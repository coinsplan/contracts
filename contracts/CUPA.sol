// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CUPA is ERC20, Ownable {
  constructor(uint256 initialSupply) ERC20("Cupa Token", "CUPA") {
    _mint(msg.sender, initialSupply);
  }

  function getTestToken() external returns (uint256) {
    _transfer(Ownable.owner(), msg.sender, 1 ether);
    return balanceOf(msg.sender);
  }
}
