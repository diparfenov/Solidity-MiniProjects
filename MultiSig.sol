// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//создание и проверка на владельцев
contract Ownable {
    address[] public owners;
    mapping(address => bool) public isOwner;

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "no owners!");
        for(uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "zero address!");
            require(!isOwner[owner], "not unique!");

            owners.push(owner);
            isOwner[owner] = true;
        }
    }

    //можно добавить функцию для добавления новых владельцев после создания

    modifier onlyOwners() {
        require(isOwner[msg.sender], "not an owner!");
        _;
    }
}

contract Multisig is Ownable {
    uint public requiredApprovals; //колличество подписей для отправки
    
    struct Transaction { //структура поставленная в очередь
        address _to;
        uint _value;
        bytes _data;
        bool _executed;
    }

    Transaction[] public transactions; //массив для этих транзакций
    
    //для каждой транщакции в массиве, которая определяется индексом записывать 
    //сколько подтверждений было отправлено для данной транзакции
    //ключ - индекс транзакции в массиве, значением - колличество подтверждений
    mapping(uint => uint) public approvalsCount;

    //кто конкретно сделал подтверждение
    //ключ - индекс транзакции в массиве, ключ - адрес владельца, значением - подтверждена или нет
    mapping(uint => mapping(address => bool)) public approved;

    event Deposit(address _from, uint _amount);
    event Submit(uint _txId);
    event Approve(address _owner, uint _txId);
    event Revoke(address _owner, uint _txId);
    event Executed(uint _txId);

    constructor(address[] memory _owners, uint _requiredApprovals) Ownable(_owners) {
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length, 
            "invalid approvals count!"
        );
        requiredApprovals = _requiredApprovals;
    }

    //поставить транзакцию в очередь
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwners{
        Transaction memory newTx = Transaction({
            _to: _to,
            _value: _value,
            _data: _data,
            _executed: false
        });
        transactions.push(newTx);
        emit Submit(transactions.length - 1);
    }

    //существует ли такая транзакция
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    //не подтверждена ли тарнзакция
    modifier notApproved(uint _txId) {
        require(!_isApproved(_txId, msg.sender), "tx already approved");
        _;
    }
    //подтверждена ли тарнзакция
    modifier wasApproved(uint _txId) {
        require(_isApproved(_txId, msg.sender), "tx not yet approved");
        _;
    }

    function _isApproved(uint _txId, address _addr) private view returns(bool) {
        return approved[_txId][_addr];
    }
    
    //не выполнена ли еще транзакция
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId]._executed, "tx already executed");
        _;
    }

    //отозвать транзакцию
    function approve(uint _txId) 
        external 
        onlyOwners 
        txExists(_txId)
        notExecuted(_txId)
        wasApproved(_txId) {
            approved[_txId][msg.sender] = false;
            approvalsCount[_txId] -= 1;
            emit Revoke(msg.sender, _txId);
    }

    //подтвердить транзакцию
    function revoke(uint _txId) 
        external 
        onlyOwners 
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId) {
            approved[_txId][msg.sender] = true;
            approvalsCount[_txId] += 1;
            emit Approve(msg.sender, _txId);
    }

    modifier enoughApprovals(uint _txId) {
        require(approvalsCount[_txId] >= requiredApprovals, "not enough approvals");
        _;
    }

    //отправить транзакцию
    function execute(uint _txId) 
        external  
        txExists(_txId)
        notExecuted(_txId)
        wasApproved(_txId) {
            Transaction storage myTx = transactions[_txId];

            (bool success,) = myTx._to.call{value: myTx._value}(myTx._data);
            require(success, "tx failed");

            myTx._executed = true;
            emit Executed(_txId);
    }

    //закодировать data
    function encode(string memory _func, string memory _arg) public pure returns(bytes memory) {
        return abi.encodeWithSignature(_func, _arg);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }
}

contract Receiver {
    string public message;

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getMoney (string memory _msg) external payable {
        message = _msg;
    }
}