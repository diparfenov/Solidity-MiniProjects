// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract StakingAlg {
    IERC20 public rewardsToken; //токены - награда, за стейкинг
    IERC20 public stakingToken; //токены, которые стейкаются

    //отношение, какую награду мы будем получать, 
    //награда будет расти пропорционально тому, 
    //сколько токены будут лежать на контракте
    uint public rewardRate = 10;

    //когда мы последний раз обновляли информацию о награде,
    //который должен получить юзер
    uint public lastUpdateTime;

    //сколько награды платить за каждый токен в контракте
    uint public rewardPerTokenStored;

    //инфорамация, сколько мы платили пользователю за каждый токен
    mapping(address => uint) public userRewardPerTokenPaid;

    //выплаченные вознаграждения
    mapping(address => uint) public rewards;

    //балансы разных адресов
    mapping(address => uint) private _balances;

    //сколько всего на контракте токенов есть
    uint private _totalSupply;

    //принять токены для стейкинга и награды
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }
    //модификатор, чтобы мы могли пересчитывать награду, который должен 
    //получить конкретный аккаунт (_account)
    //при каждом вызове модификатора мы сохраняем сколько на данный момент врмени 
    //надо юзеру залпатить rewards[account]
    modifier updateReward(address _account) {

        //сколько нужно заплатить награды за каждый токен в контракте
        rewardPerTokenStored = rewardPerToken();

        //нужуно пересчитывать награду в актулаьное время
        lastUpdateTime = block.timestamp;

        //то сколько данный аккаунт заработал на данный момент времени
        rewards[_account] = earned(_account);

        //информация сколько мы выплатили данному аккаунту
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        _;
    }
    //сколько нужно платить за каждый токен в зависимости от времени и оборота
    function rewardPerToken() public view returns(uint) {
        //если у нас на контракте нет никаких токенов, то и награда будет 0
        if (_totalSupply == 0) {
            return 0;
        }

        //но если токены на контракте есть, то берем награду за каждый токен 
        //который лежит в контракте (rewardPerTokenStored) и прибавляем 
        //отношение (rewardRate) умноженное на колличество секунду прошедшее 
        //с момента последнего обновления (block.timestamp - lastUpdateTime)
        //* 1e18 - привести число к учислу с 18 нулями. И дальше нужно поделить 
        //это значение на колличество всех токенов на в данный момент (_totalSupply)
        return rewardPerTokenStored + (
            rewardRate * (block.timestamp - lastUpdateTime)
            ) * 1e18 / _totalSupply;
    }

    //скольок на данный момент аккаунт заработал
    function earned(address _account) public view returns(uint) {
        //сколько данный акаунт положил на счет (_balances[_account]) умножить 
        //на (сколько мы платим за каждый токен (rewardPerToken()) минус
        //сколько данному аккаунту мы уже платили (userRewardPerTokenPaid[_account])
        //также приведем к числу с 18 нулями. И к этому значению прибавляем то значение 
        //которое уже было посчитано раньше (rewards[account]);
        //
        return(_balances[_account] * (
            rewardPerToken() - userRewardPerTokenPaid[_account]
            ) / 1e18) + rewards[_account];
    }

    //положить токены на счет
    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;

        //прежде чем функция stake() будет вызвана, инициатор транзакции msg.sender
        //должен явно разрешить, чтобы с его аккаунта(msg.sender), списалось
        //в пользу данного контракта(address(this)) такое (_amount) кол-во токенов
        //то есть нужн вызвать функцию approve()
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    //забрать с этого контракта токены
    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_balances[msg.sender] >= _amount, "not enough funds");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;

        //отправляем с адреса контракта переводим на адрес (msg.sender)
        //нужное кол-во (_amount) токенов
        stakingToken.transfer(msg.sender, _amount);
    }

    //Забрать награду за те токены, которые лажат на контракте
    function gerReward() external updateReward(msg.sender) {
         //то, скольок награды полагается на текущий момент времени 
        //для конкретного пользвателья
        uint reward = rewards[msg.sender];

        //зануляем в мэпинге
        rewards[msg.sender] = 0;

        //отправляем с текущего адреса инициатору транзакции (msg.sender) 
        //все доступные ему реварды
        rewardsToken.transfer(msg.sender, reward);
    }





   



}