//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract Record {
    uint public immutable timeOfCreation;

    constructor() {
        timeOfCreation = block.timestamp;
    }

    function getRecordType() public pure virtual returns(string memory) {
        return "address";
    }
}

contract StringRecord is Record {
    string public record;

    constructor(string memory _newRecord) {
        record = _newRecord;
    }


    function getRecordType() public pure override returns(string memory) {
        return "string";
    }

    function setRecord(string memory _newRecord) public {
        record = _newRecord;
    }

}

contract AddressRecord is Record{
    address public record;

    constructor(address _newRecord) {
        record = _newRecord;
    }

    function getRecordType() public pure override returns(string memory) {
        return "address";
    }

    function setRecord(address _newRecord) public {
        record = _newRecord;
    }

}

contract RecordFactory{
    Record[] public arrayRecords;

    function addRecord(string memory _newRecord) public {
		StringRecord newRecord = new StringRecord(_newRecord); 
		arrayRecords.push(newRecord);
	}

    function addRecord(address _newRecord) public {
		AddressRecord newRecord = new AddressRecord(_newRecord); 
		arrayRecords.push(newRecord);
	}

}