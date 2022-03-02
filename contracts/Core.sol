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

  mapping(bytes32 => Ticket) internal t;
  mapping(address => uint32) public nonceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => Wallet) internal wallet;

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
        _ticket.caller,
        _ticket.from,
        _ticket.to,
        _ticket.value,
        _ticket.fee,
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
    IERC20(cupaAddress).transferFrom(_from, address(this), _fee);
    wallet[_from].fee += _fee;
    // Keep eth and map to each wallet.
    wallet[_from].gas += msg.value;

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
      thisNonce,
      bytes32(0),
      Node(false, false, 0, address(0))
    );

    bytes32 ticketHash = _calculateTicketHash(_newTicket);
    _newTicket.ticketHash = ticketHash;
    t[ticketHash] = _newTicket;

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

  function coreExecution(bytes32 _ticketHash, address caller)
    external
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


  }
}
