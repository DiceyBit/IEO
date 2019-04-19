/*
This file is part of the DiceyBit Contract.

The DiceybitToken Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version. See the GNU lesser General Public License
for more details.

You should have received a copy of the GNU lesser General Public License
along with the DiceybitToken Contract. If not, see <http://www.gnu.org/licenses/>.

*/


pragma solidity ^0.5.0;

contract owned {

    address public owner;
    address public candidate;

    constructor() payable public {
        owner=msg.sender;
    }
    
    modifier onlyOwner {
        require(owner==msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate=_owner;
    }
    
    function confirmOwner() public {
        require(candidate==msg.sender);
        owner=candidate;
        delete candidate;
    }
}

library SafeMath {
    
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b<=a);
        return a-b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c=a+b;
        assert(c>=a);
        return c;
    }
}

contract DiceyBitToken is owned {
    using SafeMath for uint;

    address                      public diceybitBackend;
    bool                         public crowdsaleFinished;
    uint                         public totalSupply;
    mapping (address => uint256) public balanceOf;

    string  public standard    = 'Token 0.1';
    string  public name        = 'DiceyBit';
    string  public symbol      = "DBT";
    uint8   public decimals    = 8;

    mapping (address => mapping (address => uint)) public allowed;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed minter, uint tokens, uint8 originalCoinType, bytes32 originalTxHash);

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length>=size+4);
        _;
    }

    constructor() public payable owned() {
    }

    function changeBackend(address _diceybitBackend) public onlyOwner {
        diceybitBackend=_diceybitBackend;
    }
    
    function mintTokens(address minter, uint tokens, uint8 originalCoinType, bytes32 originalTxHash) public {
        require(msg.sender==diceybitBackend);
        require(!crowdsaleFinished);
        balanceOf[minter]=balanceOf[minter].add(tokens);
        totalSupply=totalSupply.add(tokens);
        emit Transfer(address(this), minter, tokens);
        emit Mint(minter, tokens, originalCoinType, originalTxHash);
    }
    
    function finishCrowdsale() onlyOwner public {
        crowdsaleFinished=true;
    }

    function transfer(address to, uint256 value)
        public onlyPayloadSize(2*32) returns(bool) {
        require(balanceOf[msg.sender]>=value);
        balanceOf[msg.sender]=balanceOf[msg.sender].sub(value);
        balanceOf[to]=balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value)
        public onlyPayloadSize(3*32) returns(bool) {
        require(balanceOf[from]>=value);
        require(allowed[from][msg.sender]>=value);
        balanceOf[from]=balanceOf[from].sub(value);
        balanceOf[to]=balanceOf[to].add(value);
        allowed[from][msg.sender]=allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowed[msg.sender][spender]=value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }
    
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        totalSupply=totalSupply.sub(value);
        balanceOf[account]=balanceOf[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}