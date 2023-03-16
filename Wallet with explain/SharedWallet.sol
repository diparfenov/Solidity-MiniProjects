//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract SharedWallet is Ownable { //унаследуем контракт Ownable из OpenZeppelin
  //событие инофрмация о старом и новом лимите
  event LimitChanged(address indexed _address, uint _oldLimit, uint _newLimit);

  struct info {
    string name;
    uint limit;
    bool is_admin;
  }

  //ключами здесь будут выступать адреса пользователей, а значениями — лимиты на вывод.
  mapping(address => info) public members;

  modifier ownerOrWithinLimits(uint _amount) { //_amount - сколько пытается некто снять денег
    // (либо ты владелец или админ) либо если ты members то можешь снять денег не больше, чем лимит указанный в сопоставлении
    require((isOwner() || isAdmin()) || members[msg.sender].limit >= _amount, "Not allowed!");
    _;
  }

  //возвращает true, если владелец
  function isOwner() internal view returns(bool) { // internal - достпуна внутри контракта и внутри потомков
    //owner() функция из бибилиотеки возвращает адресс владельца 
    return owner() == msg.sender;
  }

  //возвращает true, если admin
  function isAdmin() internal view returns (bool) {
    return members[msg.sender].is_admin == true;
  }
    
  //добавляет в сопоставление адресс участника, имя  и сколько он может выводить
  // onlyOwner говорит о том, что назначать может только владелец контракта
  function addLimit(address _member, uint _limit, string memory _name) public onlyOwner { 
    emit LimitChanged(_member, members[_member].limit, _limit);
    members[_member].limit = _limit; 
    members[_member].name = _name; 
  }
  //удаляет участника
  function deleteMembers(address _member) public onlyOwner { 
    delete members[_member];
  }
  //добавляет админа
  function makeAdmin(address _member) public onlyOwner{
      require(members[_member].is_admin == false, "This member is admin!");
      members[_member].is_admin = true;
  }
  //удаляет админа
  function revokeAdmin(address _member) public onlyOwner{
      require(members[_member].is_admin == true, "This member not admin!");
      members[_member].is_admin = false;
  }

  //уменьшает лимит вывода мембера
  function deduceFromLimit(address _member, uint _amount) internal {
    emit LimitChanged(_member, members[_member].limit, members[_member].limit - _amount);
    members[_member].limit -= _amount;
  }
  //переопределяем функцию из Ownable, для этого добавляем override
  //при ее вызове сразу вылезет "Can't renounce!"
  function renounceOwnership() override public view onlyOwner {
    revert("Can't renounce!");
  }
}