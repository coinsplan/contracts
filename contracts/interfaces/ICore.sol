// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICore {
  // Structures

  struct TicketMetadata {
    bool isActive;
    address cancelBy;
    bool isExecuted;
    bool isSuccess;
    uint256 executionBlock;
    address caller;
  }

  struct Ticket {
    uint256 targetExecutionBlock;
    uint256 creationBlock;
    address tokenAddress;
    address sender;
    address from;
    address to;
    uint256 value;
    uint256 fee;
    uint32 nonce;
    bytes32 ticketHash;
    TicketMetadata metadata;
  }

  // Events

  event TicketCreate(Ticket _ticket);

  // event TicketFail(Ticket _ticket);

  event TicketCancel(Ticket _ticket);

  event TicketExecuted(Ticket _ticket);

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

  function coreExecutionCall(bytes32 _ticketHash, address payable caller)
    external
    returns (bool);

  function cancel(bytes32 ticketHash) external returns (bool);
}
