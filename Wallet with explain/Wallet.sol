//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SharedWallet.sol";

contract Wallet is SharedWallet { //унаследуем контракт SharedWallet, а вместе с ним Ownable из OpenZeppelin 
  
  //события "деньги пришли в кошелёк" и "деньги выведены из кошелька", indexed для поиска
  event MoneyWithdrawn(address indexed _to, uint _amount);
  event MoneyReceived(address indexed _from, uint _amount);
  

  //узнать баланс контракта
  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  //вывести какое-то колличество денег на текущий адресс
  function withdrawMoney(uint _amount) external ownerOrWithinLimits(_amount) {
    //проверка достатоно ли денег для вывода
    require(_amount <= getBalance(), "Not enough funds to withdraw!"); 
    
    //если ты не владелец и не админ уменьшает лимит на вывод
    if(!isOwner() && !isAdmin()) { 
      deduceFromLimit(msg.sender, _amount); 
    }

    //отправляет деньги на адресс текущий
    payable(msg.sender).transfer(_amount);
    //порождаем событие
    emit MoneyWithdrawn(msg.sender, _amount);
  }
    
  fallback() external payable {}
    
  receive() external payable {
    //порождаем событие
    emit MoneyReceived(msg.sender, msg.value);
  }
}
