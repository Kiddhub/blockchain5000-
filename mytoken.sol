//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract MyToken {
    string public name = "MyToken";
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply = 1000000;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value );
    mapping (address => mapping(address => uint256)) allowed;
    mapping (address => uint256) balances;
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferForm(address _from, address _to , uint256 _value) public returns (bool success){
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >0);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
        return true;

    }

    function approve (address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance (address _owner, address _spender) public view returns (uint256 remaining){
        remaining = allowed[_owner][_spender];
        return remaining;
    }

}

