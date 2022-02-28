// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IGuard {
    function initialize(address _core, address _owner) external;

    function isTicketExecuted(bytes32 _ticketHash) external view returns (bool);

    function execute(bytes32 _ticketHash) external returns (bool);
}
