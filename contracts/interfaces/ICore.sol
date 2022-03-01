// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICore {
  // Structures

  struct Node {
    bool isExecuted;
    bool isSuccess;
    uint256 executionBlock;
    address caller;
  }

  struct Ticket {
    uint256 targetExecutionBlock;
    uint256 creationBlock;
    address tokenAddress;
    address caller;
    address from;
    address to;
    uint256 value;
    uint256 fee;
    uint32 nonce;
    bytes32 ticketHash;
    Node node;
  }

  // Events

  event TicketCreate(
    Ticket ticket
  );

  event TicketFail(Ticket _ticket);

  function createTicket(
    uint256 targetExecutionBlock,
    address _tokenAddress,
    address _from,
    address _to,
    uint256 _value,
    uint256 _fee
  ) external payable returns (bytes32);

  function getTicket(bytes32 _ticketHash)
    external
    view
    returns (Ticket memory _ticket);
}
