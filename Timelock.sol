//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Timelock {
    address public owner;
    
    uint public constant MIN_DELAY = 10; //минимально допустимая задержка для выполнений транзакции
    uint public constant MAX_DELAY = 100; //максимально допустимая задержка для выполнений транзакции
    uint public constant EXPIRY_DELAY = 100; //время, когда выполнение транзакции счиатается истекшей
    
    mapping(bytes32 => bool) public queuedTx; //идентификатор транзакции => поставлена ли транзакиця в очередь
    
    event Queued(
        bytes32 indexed txId,
        address indexed to,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

     event Executed(
        bytes32 indexed txId,
        address indexed to,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }
    //очередь(на какой адресс отправляем, сколько, к какой функции обращаемся, время)
    function queue(
        address _to, 
        uint _value, 
        string calldata _func,
        bytes calldata _data, 
        uint _timestamp
    ) external onlyOwner returns(bytes32) {
        //кодируем все наши входные данные, чтобы нельзя было отправить транзакцию точно такую же
        bytes32 txId = keccak256(
            abi.encode(
                _to, _value, _func, _data, _timestamp
            )
        );
        //нет ли уже в очереди такой транзакции
        require(!queuedTx[txId], "already queued!");
        //транзакция должна входить в диапазон времени
        require(
            _timestamp >= block.timestamp + MIN_DELAY &&
            _timestamp <= block.timestamp + MAX_DELAY,
            "invalid timestamp"
        );
        //если все ок добавляем в мэпинг
        queuedTx[txId] = true;
        emit Queued (
            txId, 
            _to, 
            _value, 
            _func, 
            _data, 
            _timestamp
        );
        return txId;
    }

    //отправка транзакции
    function execute(
        address _to, 
        uint _value, 
        string calldata _func,
        bytes calldata _data, 
        uint _timestamp
    ) external payable onlyOwner returns(bytes memory) {
        //кодируем все наши входные данные, чтобы сверить их с данными в мэпинге
        bytes32 txId = keccak256(
            abi.encode(
                _to, _value, _func, _data, _timestamp
            )
        );
        //есть ли в очереди такая транзакция
        require(queuedTx[txId], "not queued!");

        //время должно настать, иначе рано отправлять
        require(block.timestamp >= _timestamp, "too early!");

        //не должно быть такой ситуации, что транзакция была создана очень давно
        require(block.timestamp <= _timestamp + EXPIRY_DELAY, "too late!");
        
        //удаляем транзакцию из мэпинга
        delete queuedTx[txId];

        //нужно правильно закодировать данные и имя функции, чтобы правильно отправить в транзакции
        bytes memory data;
        //если имя функции не указано, то берем просто data, а это итак bytes
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(
                //т.к. функция приходит в формате string нам нужно взять из нее
                //первые 4 байта хэша (таков алгоритм закулисный)
                bytes4(keccak256(bytes(_func))), _data
            );
        } else {
            data = _data;
        }

        //выполним эту транзакцию, resp - это ответ
        (bool success, bytes memory resp) = _to.call{value: _value}(data);

        require(success, "tx failed");

        emit Executed(
            txId, 
            _to, 
            _value, 
            _func, 
            _data, 
            _timestamp
        );

        return resp;

    }

    //отмена транзакции 
    function cancel(bytes32 _txId) external onlyOwner {
        require(queuedTx[_txId], "not queued!");

        delete queuedTx[_txId];
    }
}

//контракт для теста
contract Runner {
    address public lock; // адресс контракта, что писали выше
    string public message;
    mapping(address => uint) public payments;

    constructor(address _lock) {
        lock = _lock;

    }

    function run(string memory _newMsg) external payable {
        require(msg.sender == lock, "invalid address");

        payments[msg.sender] += msg.value;
        message = _newMsg;
    }

    function newTimestamp() external view returns (uint) {
        return block.timestamp + 20;
    }

    function prepearData(string calldata _msg) external pure returns (bytes memory) {
        return abi.encode(_msg);
    }
}
