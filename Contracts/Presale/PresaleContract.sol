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

    uint constant MINIMUM_TOKEN_VALUE_MULTIPLIER = 10**18;
                                
    uint constant MINIMUM_PAYMENT_VALUE = 0.01 ether;//100 ether;

    uint[] prices;
    uint[] amounts; 
    
    uint totalRaisedEth = 0;
    uint soldTokensAmount = 0;
    address public mainVallet;
    function PresaleContract() public {
        mainVallet = owner;
        prices.push(FIRST_PRESALE_PRICE);
        prices.push(SECOND_PRESALE_PRICE);
        prices.push(THIRD_PRESALE_PRICE);
        
        amounts.push(FIRST_PRESALE_AMOUNT * MINIMUM_TOKEN_VALUE_MULTIPLIER);
        amounts.push(SECOND_PRESALE_AMOUNT * MINIMUM_TOKEN_VALUE_MULTIPLIER);
        amounts.push(THIRD_PRESALE_AMOUNT * MINIMUM_TOKEN_VALUE_MULTIPLIER);
    }
    
    mapping (address => Balance) usersBalance;
    Transaction[] transactions;
    
    function buyTokens() public payable {
        require(msg.value >= MINIMUM_PAYMENT_VALUE);
        uint deposit = msg.value;
        
        uint8 index = 0;
        uint profit = 0;
        
        uint totalTokens = 0;
        
        while (deposit > 0 && index < 3) {
            uint ethers = 0;
            uint maxAmount = deposit * MINIMUM_TOKEN_VALUE_MULTIPLIER * prices[index] / 1 ether;
            if (amounts[index] >= maxAmount) {
                amounts[index] -= maxAmount;
                ethers = deposit;
                deposit = 0;
            } else {
                maxAmount = amounts[index];
                amounts[index] = 0;
                ethers = maxAmount * 1 ether / MINIMUM_TOKEN_VALUE_MULTIPLIER / prices[index];
                deposit -= ethers;
                
            }
            //save transaction
            _addTransaction(msg.sender, ethers, prices[index], maxAmount);
            //calculations
            totalTokens += maxAmount;
            profit += ethers;
            //
            index++;
        }
        
        _updateData(msg.sender, profit, totalTokens);
        //return money
        if (deposit > 0) {
            withdraw(msg.sender, deposit);
        }
        //auto-transfer to our wallet
        if (profit > 0) {
            withdraw(mainVallet, profit);
            // mainVallet.transfer(profit);
        }
    }
    function _addTransaction(address _buyer, uint _ethers, uint _price, uint _amount) private {
        Transaction memory transaction = Transaction(_buyer, _ethers, _price, _amount);
        transactions.push(transaction);
    }
    function _updateData(address _buyer, uint _profit, uint _totalTokens) private {
        Balance storage balan
        ce = usersBalance[_buyer];
        soldTokensAmount += _totalTokens;
        totalRaisedEth += _profit;
        balance.ethers += _profit;
        balance.tokens += _totalTokens;
        totalRaisedEth += _profit;
    }
    function getMyBalans() public view returns(uint) {
        return usersBalance[msg.sender].tokens;
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
