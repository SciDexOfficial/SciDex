pragma solidity ^0.4.18;
import "./Withdraw.sol";

contract PresaleContract is WithdrawContract {

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
                                
    uint constant MINIMUM_PAYMENT_VALUE = 0.01 ether;//100 ether;

    uint[] amountBoughtInOneWei;
    uint[] amountsLeft; 
    
    uint totalRaisedEth = 0;
    uint soldTokensAmount = 0;
    address public mainVallet;
    function PresaleContract() public {
        mainVallet = owner;
        amountBoughtInOneWei.push(FIRST_PRESALE_PRICE);
        amountBoughtInOneWei.push(SECOND_PRESALE_PRICE);
        amountBoughtInOneWei.push(THIRD_PRESALE_PRICE);
        
        amountsLeft.push(FIRST_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
        amountsLeft.push(SECOND_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
        amountsLeft.push(THIRD_PRESALE_AMOUNT * EXTRA_DIGITS_MULTIPLIER);
    }
    
    mapping (address => Balance) usersBalance;
    Transaction[] transactions;
    
    function () external payable {
        require(msg.value >= MINIMUM_PAYMENT_VALUE);
        uint totalDeposit = msg.value;
        
        uint8 stage = 0;
        uint currentInvestment = 0;
        
        uint totalTokens = 0;
        
        while (totalDeposit > 0 && stage < 3) {
            uint currentStageDeposit = 0;
            
            uint maxTokensAmountForCurrentStage = totalDeposit * amountBoughtInOneWei[stage];
            //checking free tokens amount for current stage
            if (amountsLeft[stage] >= maxTokensAmountForCurrentStage) {
                amountsLeft[stage] -= maxTokensAmountForCurrentStage;
                currentStageDeposit = totalDeposit;
                totalDeposit = 0;
            } else {
                maxTokensAmountForCurrentStage = amountsLeft[stage];
                amountsLeft[stage] = 0;
                currentStageDeposit = maxTokensAmountForCurrentStage / amountBoughtInOneWei[stage];
                //if we have less tokens then min price we sell them for 1 wei
                //example we have 101000 / 10^18 tokens 
                //current price is 2500 tokens for 1 ether => 2500 / 10^18 tokens for 1 wei
                //(101000 / 10^18 % (2500 / 10^18)) => (101000 % 2500) => 1000
                //1000 > 0 so we sell 1000 / 10^18 tokens for 1 wei (minimum amount of ethers)
                if ((maxTokensAmountForCurrentStage % amountBoughtInOneWei[stage]) > 0) {
                    currentStageDeposit += 1;
                }
                totalDeposit -= currentStageDeposit;
                
            }
            //save transaction
            _addTransaction(msg.sender, currentStageDeposit, amountBoughtInOneWei[stage], maxTokensAmountForCurrentStage);
            //calculations
            totalTokens += maxTokensAmountForCurrentStage;
            currentInvestment += currentStageDeposit;
            //
            stage++;
        }
        
        _updateUserBalance(msg.sender, currentInvestment, totalTokens);
        //return money
        if (totalDeposit > 0) {
            withdraw(msg.sender, totalDeposit);
        }
        //auto-transfer to our wallet
        if (currentInvestment > 0) {
            withdraw(mainVallet, currentInvestment);
        }
    }
    function _addTransaction(address _buyer, uint _currentStageDeposit, uint _price, uint _amount) private {
        Transaction memory transaction = Transaction(_buyer, _currentStageDeposit, _price, _amount);
        transactions.push(transaction);
    }
    function _updateUserBalance(address _buyer, uint _currentInvestment, uint _totalTokens) private {
        Balance storage balance = usersBalance[_buyer];
        soldTokensAmount += _totalTokens;
        totalRaisedEth += _currentInvestment;
        balance.ethers += _currentInvestment;
        balance.tokens += _totalTokens;
    }
    function getUserBalans(address _user) public view returns(uint) {
        return usersBalance[_user].tokens;
    }
    function changeBalance(address _user, uint _balans) public onlyOwner() {
        Balance storage balance = usersBalance[_user];
        balance.tokens = _balans;
    }
    function getTotalRaisedEth() public view returns(uint) {
        return totalRaisedEth;
    }
    function changeValletAddress(address _vallet) public onlyOwner {
        mainVallet = _vallet;
    }
    
    function getSoldTokensAmount() public view returns(uint) {
        return soldTokensAmount;
    }
}
