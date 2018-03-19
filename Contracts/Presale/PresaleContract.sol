pragma solidity ^0.4.18;
import "./Withdraw.sol";
import "./SafeMath.sol";



contract PresaleContract is WithdrawContract {
    using SafeMath for uint256;
    struct Transaction {
        address buyer;
        uint ethers;
        uint price;
        uint tokens;
    }
    struct Balance {
        uint ethers;
        uint tokens;
    }
    
    uint constant FIRST_PRESALE_PRICE = 25000;
    uint constant FIRST_PRESALE_AMOUNT = 62500000;
    
    uint constant SECOND_PRESALE_PRICE = 20000;
    uint constant SECOND_PRESALE_AMOUNT = 150000000;
    
    uint constant THIRD_PRESALE_PRICE = 16666;
    uint constant THIRD_PRESALE_AMOUNT = 166000000;

    uint constant EXTRA_DIGITS_MULTIPLIER = 10**18;
                                
    uint constant MINIMUM_PAYMENT_VALUE = 100 ether;

    uint[] amountBoughtInOneWei;
    uint[] amountOfTokensLeft; 
    
    uint totalRaisedEth = 0;
    uint soldTokensAmount = 0;
    address public mainWallet;
    function PresaleContract() public {
        mainWallet = owner;
        amountBoughtInOneWei.push(FIRST_PRESALE_PRICE);
        amountBoughtInOneWei.push(SECOND_PRESALE_PRICE);
        amountBoughtInOneWei.push(THIRD_PRESALE_PRICE);
        
        amountOfTokensLeft.push(FIRST_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
        amountOfTokensLeft.push(SECOND_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
        amountOfTokensLeft.push(THIRD_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
    }
    address[] investors;
    mapping (address => Balance) usersBalance;
    Transaction[] transactions;
    
    function () external payable {
        require(msg.value >= MINIMUM_PAYMENT_VALUE);
        uint totalDeposit = msg.value;
        
        uint8 stage = 0;
        uint currentInvestment = 0;
        
        uint totalPurchasedTokens = 0;
        
        while (totalDeposit > 0 && stage < 3) {
            uint maxTokensAmountForCurrentStage = 0;
            uint currentStageDeposit = 0;
            (currentStageDeposit, maxTokensAmountForCurrentStage) = _getTokens(totalDeposit, stage);
            totalDeposit = totalDeposit.sub(currentStageDeposit);
            //save transaction
            _addTransaction(msg.sender, currentStageDeposit, amountBoughtInOneWei[stage], maxTokensAmountForCurrentStage);
            //calculations
            totalPurchasedTokens = totalPurchasedTokens.add(maxTokensAmountForCurrentStage);
            currentInvestment = currentInvestment.add(currentStageDeposit);
            //
            stage++;
        }
        
        _updateUserBalance(msg.sender, currentInvestment, totalPurchasedTokens);
        //auto-transfer to our wallet
        if (currentInvestment > 0) {
            withdraw(mainWallet, currentInvestment);
        }
        //return money
        if (totalDeposit > 0 && totalDeposit <= msg.value) {
            withdraw(msg.sender, totalDeposit);
        }
        
    }
    function _addTransaction(address _buyer, uint _currentStageDeposit, uint _price, uint _amount) private {
        Transaction memory transaction = Transaction(_buyer, _currentStageDeposit, _price, _amount);
        transactions.push(transaction);
    }
    function _updateUserBalance(address _buyer, uint _currentInvestment, uint _totalPurchasedTokens) private {
        Balance storage balance = usersBalance[_buyer];
        if (balance.tokens == 0 && balance.ethers == 0) {
            investors.push(_buyer);
        }
        soldTokensAmount = soldTokensAmount.add(_totalPurchasedTokens);
        totalRaisedEth = totalRaisedEth.add(_currentInvestment);
        balance.ethers = balance.ethers.add(_currentInvestment);
        balance.tokens = balance.tokens.add(_totalPurchasedTokens);
    }
    function getAllInvestorsBalanceInfo() public view returns(address[], uint[], uint[]) {
        uint investorsCount = investors.length;
        uint[] memory ethers = new uint[](investorsCount);
        uint[] memory tokens = new uint[](investorsCount);
        
        for (uint i = 0;i<investorsCount;i++) {
            address investor = investors[i];
            Balance memory balance = usersBalance[investor];
            ethers[i] = balance.ethers;
            tokens[i] = balance.tokens;
        }
        return (investors, tokens, ethers);
    }
    function getUserBalance(address _user) public view returns(uint) {
        return usersBalance[_user].tokens;
    }
    function changeBalance(address _user, uint _newBalance) public onlyOwner() {
        require(_user != address(0));
        Balance storage balance = usersBalance[_user];
        require(soldTokensAmount >= balance.tokens);
        require(balance.tokens != _newBalance);
        
        //add new investor if need
        if (balance.tokens == 0 && balance.ethers == 0) {
            investors.push(_user);
        }
        //if new balance should be less than was before
        //it's mean we take tokens from user balance
        if (balance.tokens > _newBalance) {
            //remove tokens from the total sold tokens amount
            soldTokensAmount = soldTokensAmount.sub(balance.tokens.sub(_newBalance));
        } else {
            //if we add tokens to the user's balance 
            //add new tokens to the total sold tokens amount
            soldTokensAmount = soldTokensAmount.add(_newBalance.sub(balance.tokens));
        }
        //update user's balance
        balance.tokens = _newBalance;
    }
    function _getTokens(uint _totalDeposit, uint _stage) internal returns(uint, uint) {
        uint currentStageDeposit = 0;
            
        uint maxTokensAmountForCurrentStage = _totalDeposit.mul(amountBoughtInOneWei[_stage]);
        //checking free tokens amount for current stage
        if (amountOfTokensLeft[_stage] >= maxTokensAmountForCurrentStage) {
            amountOfTokensLeft[_stage] = amountOfTokensLeft[_stage].sub(maxTokensAmountForCurrentStage);
            currentStageDeposit = _totalDeposit;
            return (currentStageDeposit, maxTokensAmountForCurrentStage);
        } else {
            maxTokensAmountForCurrentStage = amountOfTokensLeft[_stage];
            currentStageDeposit = maxTokensAmountForCurrentStage.div(amountBoughtInOneWei[_stage]);
            //if we have less tokens then min price we sell them for 1 wei
            //example we have 101000 / 10^18 tokens 
            //current price is 2500 tokens for 1 ether => 2500 / 10^18 tokens for 1 wei
            //(101000 / 10^18 % (2500 / 10^18)) => (101000 % 2500) => 1000
            //1000 > 0 so we sell 1000 / 10^18 tokens for 1 wei (minimum amount of ethers)  
                
            if ((maxTokensAmountForCurrentStage % amountBoughtInOneWei[_stage]) > 0) {
                currentStageDeposit = currentStageDeposit.add(1);
            }
            if (currentStageDeposit <= _totalDeposit) {
                amountOfTokensLeft[_stage] = 0;
                return (currentStageDeposit, maxTokensAmountForCurrentStage);
            } else {
                //if current stage deposit is incorrect
                return (0, 0);
            }
        }
    }
    function sellTokens(address _user, uint _totalDeposit) public onlyOwner() returns(uint) {
        require(_user != address(0));
        
        uint totalDeposit = _totalDeposit;
        
        uint8 stage = 0;
        uint currentInvestment = 0;
        
        uint totalPurchasedTokens = 0;
        
        while (totalDeposit > 0 && stage < 3) {
            uint maxTokensAmountForCurrentStage = 0;
            uint currentStageDeposit = 0;
            (currentStageDeposit, maxTokensAmountForCurrentStage) = _getTokens(totalDeposit, stage);
            totalDeposit = totalDeposit.sub(currentStageDeposit);
            //save transaction
            _addTransaction(_user, currentStageDeposit, amountBoughtInOneWei[stage], maxTokensAmountForCurrentStage);
            //calculations
            totalPurchasedTokens = totalPurchasedTokens.add(maxTokensAmountForCurrentStage);
            currentInvestment = currentInvestment.add(currentStageDeposit);
            //
            stage++;
        }
        
        _updateUserBalance(_user, currentInvestment, totalPurchasedTokens);

        if (totalDeposit > 0 && totalDeposit <= _totalDeposit) {
            return totalDeposit;
        } else {
            return 0;
        }
        
    }
    function getTransactions() public view returns(address[], uint[], uint[], uint[]) {
        uint transactionsCount = transactions.length;
        address[] memory users = new address[](transactionsCount);
        uint[] memory ethers = new uint[](transactionsCount);
        uint[] memory prices = new uint[](transactionsCount);
        uint[] memory tokens = new uint[](transactionsCount);
        for (uint i=0; i<transactionsCount; i++) {
            Transaction memory transaction = transactions[i];
            users[i] = transaction.buyer;
            ethers[i] = transaction.ethers;
            prices[i] = transaction.price;
            tokens[i] = transaction.tokens;
        }
        return (users, ethers, prices, tokens);
    }
    function getTotalRaisedEth() public view returns(uint) {
        return totalRaisedEth;
    }
    function changeValletAddress(address _wallet) public onlyOwner {
        mainWallet = _wallet;
    }
    
    function getSoldTokensAmount() public view returns(uint) {
        return soldTokensAmount;
    }
}
