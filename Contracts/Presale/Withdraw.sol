pragma solidity ^0.4.18;
import "./Ownable.sol";

contract WithdrawContract is Ownable {
    function withdraw(address _receiver, uint _amount) internal {
        _receiver.transfer(_amount);
    }
    //withdraw to the contract owner
    function withdrawToContractOwner(uint _amount) public onlyOwner {
        require(this.balance >= _amount);
        withdraw(owner, _amount);
    }
}