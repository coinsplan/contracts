// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICore.sol";
import "./Guard.sol";
import "./interfaces/IGuard.sol";

contract Core is ICore, Ownable {
  constructor(address _cupaAddress) {
    cupaAddress = _cupaAddress;
    _initGuard();
  }

  // modifiers
  modifier guard() {
    require(msg.sender == guardAddress);
    _;
  }

  // Global vars

  address public cupaAddress;
  address public guardAddress;

  mapping(bytes32 => Ticket) private t;
  mapping(address => uint32) public nonceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => uint256) internal gas;

  function _initGuard() private {
    address g;
    bytes memory bytecode = type(Guard).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(address(this)));
    assembly {
      g := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    guardAddress = g;
    IGuard(guardAddress).initialize(address(this), Ownable.owner());
    if (guardAddress == address(0)) {
      revert();
    }
  }

  function _calculateTicketHash(Ticket memory _ticket)
    private
    pure
    returns (bytes32 hash)
  {
    hash = keccak256(
      abi.encodePacked(
        _ticket.targetExecutionBlock,
        _ticket.creationBlock,
        _ticket.tokenAddress,
        _ticket.sender,
        _ticket.from,
        _ticket.to,
        _ticket.value,
        _ticket.fee,
        _ticket.gas,
        _ticket.nonce
      )
    );
  }

  function createTicket(
    uint256 targetExecutionBlock,
    address _tokenAddress,
    address _from,
    address _to,
    uint256 _value,
    uint256 _fee
  ) external payable override returns (bytes32) {
    // Transfer CUPA fees.
    IERC20(cupaAddress).transferFrom(msg.sender, address(this), _fee);

    // Keep eth and map to each wallet.
    gas[msg.sender] += msg.value;

    // Begin ticket creation
    uint32 thisNonce = nonceOf[_from];
    nonceOf[_from]++;

    Ticket memory _newTicket = Ticket(
      targetExecutionBlock,
      block.number,
      _tokenAddress,
      msg.sender,
      _from,
      _to,
      _value,
      _fee,
      msg.value,
      thisNonce,
      bytes32(0),
      TicketMetadata(true, address(0), false, false, 0, address(0))
    );

    bytes32 ticketHash = _calculateTicketHash(_newTicket);
    _newTicket.ticketHash = ticketHash;
    t[ticketHash] = _newTicket;

    gas[_newTicket.sender] = msg.value;

    emit TicketCreate(_newTicket);

    return ticketHash;
  }

  function getTicket(bytes32 _ticketHash)
    public
    view
    override
    returns (Ticket memory _ticket)
  {
    return t[_ticketHash];
  }

  function coreExecutionCall(bytes32 _ticketHash, address payable caller)
    external
    override
    guard
    returns (bool)
  {
    Ticket memory targetTicket = getTicket(_ticketHash);
    require(
      IERC20(targetTicket.tokenAddress).allowance(
        targetTicket.from,
        address(this)
      ) >= targetTicket.value,
      "Not enough approval liquidity."
    );
    require(
      IERC20(targetTicket.tokenAddress).balanceOf(targetTicket.from) >=
        targetTicket.value,
      "Not enough liquidity."
    );

    return _execute(targetTicket, caller);
  }

  function _execute(Ticket memory _ticket, address payable caller)
    private
    returns (bool)
  {
    require(
      _ticket.metadata.isActive == true && _ticket.metadata.isExecuted == false,
      "Already executed or canceled."
    );
    // Gas calculation starts here.
    uint256 startGas = gasleft();
    IERC20(_ticket.tokenAddress).transferFrom(
      _ticket.from,
      _ticket.to,
      _ticket.value
    );

    // Transfer CUPA fee to caller
    IERC20(cupaAddress).transferFrom(address(this), caller, _ticket.fee);

    uint256 endedGas = gasleft();
    uint256 usedGas = startGas - endedGas;

    // Transfer gas to caller
    gas[_ticket.sender] -= usedGas;

    t[_ticket.ticketHash].metadata.isActive = false;
    t[_ticket.ticketHash].metadata.isExecuted = true;
    t[_ticket.ticketHash].metadata.isSuccess = true;
    t[_ticket.ticketHash].metadata.executionBlock = block.number;
    t[_ticket.ticketHash].metadata.caller = caller;

    caller.transfer(usedGas * tx.gasprice);

    payable(_ticket.sender).transfer(gas[_ticket.sender]);

    emit TicketExecuted(_ticket);

    return true;
  }

  function cancel(bytes32 ticketHash) external override returns (bool) {
    Ticket memory _ticket = getTicket(ticketHash);
    require(
      msg.sender == _ticket.from || msg.sender == _ticket.sender,
      "Not allowed"
    );
    require(_ticket.metadata.isExecuted == false, "Ticket is already executed");
    require(_ticket.metadata.isActive == true, "Ticket is canceled");

    return _cancel(ticketHash);
  }

  function _cancel(bytes32 ticketHash) private returns (bool) {
    t[ticketHash].metadata.isActive = false;
    Ticket memory _ticket = getTicket(ticketHash);
    // Refunds
    gas[_ticket.sender] -= _ticket.gas;
    IERC20(cupaAddress).transfer(_ticket.sender, _ticket.value);
    payable(_ticket.sender).transfer(_ticket.gas);

    emit TicketCancel(t[ticketHash]);
    return true;
  }

  function isActive(bytes32 ticketHash) public view returns (bool) {
    return t[ticketHash].metadata.isActive;
  }

  function isExecuted(bytes32 ticketHash) public view returns (bool) {
    return t[ticketHash].metadata.isExecuted;
  }

  function getTicketMetadata(bytes32 ticketHash)
    public
    view
    returns (TicketMetadata memory)
  {
    return t[ticketHash].metadata;
  }
}
