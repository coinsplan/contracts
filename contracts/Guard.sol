// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces/ICore.sol";
import "./interfaces/IGuard.sol";

contract Guard is IGuard {
  address _OWNER;
  address _CORE;

  function initialize(address _core, address _owner) external override {
    _CORE = _core;
    _OWNER = _owner;
  }

  function isTicketExecuted(bytes32 _ticketHash)
    public
    view
    override
    returns (bool)
  {
    ICore.Ticket memory _ticket = ICore(_CORE).getTicket(_ticketHash);
    return _ticket.metadata.isExecuted;
  }

  function execute(bytes32 _ticketHash) external override returns (bool) {
    require(
      isTicketExecuted(_ticketHash) == false,
      "This ticket hash been executed"
    );
    // send execution to core contract
    return ICore(_CORE).coreExecutionCall(_ticketHash, payable(msg.sender));
  }
}
