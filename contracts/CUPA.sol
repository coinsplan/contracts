// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CUPA is ERC20 {
  constructor(uint256 initialSupply) ERC20("Cupa Token", "CUPA") {
    _mint(address(0), initialSupply);
  }
  function getTestToken() external returns (uint256) {
    _transfer(address(0), msg.sender, 1 ether);
    return balanceOf(msg.sender);
  }
}
