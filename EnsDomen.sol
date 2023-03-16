//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0; 

contract EnsDomen {
  address public owner;
  uint public pricePerYear;
  uint public factor;
  uint public constant SECONDS_IN_YEAR = 31536000;

  struct Payment {
    address anyAddress;
    uint timestamp;
    uint amount;
    uint howManyYears;
  }

   mapping(string => Payment) public information;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "You're not a owner!");
    _;
  }

  modifier manyYears(string memory _domen, uint _howManyYears) {
    require((information[_domen].timestamp + (information[_domen].howManyYears * SECONDS_IN_YEAR)) < block.timestamp, "Not free");
    require (_howManyYears >= 0 && _howManyYears <= 10, "You can register a domain from 1 to 10 years");
    _;
  }

  function newEns(string memory _domen, uint _howManyYears) public payable manyYears(_domen, _howManyYears) {
    require(msg.value == pricePerYear*_howManyYears, "Insufficient funds");
    information[_domen] = Payment(msg.sender, block.timestamp, pricePerYear*_howManyYears, _howManyYears);
  }
  
 function reNewDomen(string memory _domen, uint _reNewYears) public payable {
    require(msg.sender == information[_domen].anyAddress, "You're not a owner!");
    require(msg.value == _reNewYears*pricePerYear*factor/10, "Insufficient funds");
    require((information[_domen].timestamp + (information[_domen].howManyYears * SECONDS_IN_YEAR)) > block.timestamp, "Your domain ended, buy new!");
    information[_domen].howManyYears += _reNewYears;
    information[_domen].amount += _reNewYears*pricePerYear*factor/10;
  }

  function ens(string memory _domen) view public returns(address) {
    return information[_domen].anyAddress;
  }

  function withdrawMoney(address payable _to) public onlyOwner {
    _to.transfer(address(this).balance);
  }

  function setPrice(uint _price) public onlyOwner {
    pricePerYear = _price * (10 ** 18); 
  }

  function setFactor(uint _factor) public onlyOwner {
    factor = _factor; 
  }
}
