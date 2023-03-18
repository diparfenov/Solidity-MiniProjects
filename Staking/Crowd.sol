//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Crowd {
    //одна компания
    struct Campaign {
        address owner; //владелец  
        uint goal; // сколько всего нужно собрать
        uint pledged; // сколько собрали на данный момент
        uint startAt; //время начала
        uint endAt; //время окончания
        bool claimed; //забрали сбор или нет   
    }

    IERC20 public immutable token; //токен, который хотим зайдействовать
    
    uint public currentId;
    mapping(uint => Campaign) public campaigns;
    
    //uint тут и в campaigns это будут currentId, а внутренний мэпинг 
    //адрес и сколько денег он внес
    mapping(uint => mapping(address => uint)) public pledges; 
    uint public constant MAX_DURATION = 100 days; //максимальная продолжительность компании
    uint public constant MIN_DURATION = 10; //минимальная продолжительность компании

    constructor(address _token) {
        token = IERC20(_token); 
    }

    event Launched (uint id, address owner, uint goal, uint startAt, uint endAt);
    event Cancel (uint id);
    event Pledged (uint id, address pledger, uint amount);
    event Unpledged (uint id, address pledger, uint amount);
    event Claimed(uint id);
    event Refunded(uint id, address pledger, uint amount);

    //запуск компании
    function launch(uint _goal, uint _startAt, uint _endAt) external {
        require(_startAt >= block.timestamp, "incorrect start at");
        require(_endAt >= block.timestamp + MIN_DURATION, "incorrect end at"); 
        require(_startAt <= block.timestamp + MAX_DURATION, "too long!");

        campaigns[currentId] = Campaign({
            owner: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launched (currentId, msg.sender, _goal, _startAt, _endAt);
        currentId +=1;
    }
    //отмена компании, если она еще не началась
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.owner, "not an owner");
        require(block.timestamp < campaign.startAt, "already started!");

        delete campaigns[_id];
        emit Cancel(_id);
    }

    //сделать взнос
    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started!");
        require(block.timestamp < campaign.endAt, "ended!");

        campaign.pledged += _amount;
        pledges[_id][msg.sender] +=_amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledged(_id, msg.sender, _amount);
    }

    //забрать взнос, если кампания не началсь
    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.endAt, "ended!");

        campaign.pledged -= _amount;
        pledges[_id][msg.sender] -=_amount;
        token.transfer(msg.sender, _amount);
        emit Unpledged(_id, msg.sender, _amount);
    }

    //забрать все деньги собранной компании
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.owner, "not an owner");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged is too low");
        require(!campaign.claimed, "already claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
        emit Claimed(_id);
    }

    //забрать деньги несобранной компании конкретным адресом
     function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "reached goal");
        
        uint pledgedAmount = pledges[_id][msg.sender];
        pledges[_id][msg.sender] = 0;
        token.transfer(msg.sender, pledgedAmount);
        emit Refunded(_id, msg.sender, pledgedAmount);
    }    
}

    