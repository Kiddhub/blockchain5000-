//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MasterChef {
    ERC20 public tokenX;
    ERC20 public tokenY;
    uint256 public tokenYPerTokenX;

    constructor(ERC20 _tokenX, ERC20 _tokenY, uint256 _tokenYPerTokenX){
        tokenX = _tokenX;
        tokenY = _tokenY;
        tokenYPerTokenX = _tokenYPerTokenX;
    }
    function deposit(uint256 _amount) external {
        tokenX.transferFrom(msg.sender, address(this), _amount);
        uint256 rewardAmount = _amount * tokenYPerTokenX;
        tokenY.transfer(msg.sender,rewardAmount);
    }
}
