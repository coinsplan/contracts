// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICore.sol";
import "./Guard.sol";
import "./interfaces/IGuard.sol";

contract Core is ICore, Ownable {
    constructor(address _CUPA_ADDRESS) {
        CUPA_ADDRESS = _CUPA_ADDRESS;
        initGuard();
    }

    // modifiers

    modifier onlyAllow(address _from) {
        require(
            allowance[_from][msg.sender] > 0,
            "Method not allowed, permitted by allowance."
        );
        _;
    }

    modifier guard() {
        require(msg.sender == GUARD_ADDRESS);
        _;
    }

    // Global vars

    address CUPA_ADDRESS;
    address GUARD_ADDRESS;

    mapping(bytes32 => Ticket) internal sig;
    mapping(address => uint32) public nonceOf;
    mapping(address => mapping(address => uint64)) allowance;

    function initGuard() private {
        address g;
        bytes memory bytecode = type(Guard).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        assembly {
            g := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        GUARD_ADDRESS = g;
        IGuard(GUARD_ADDRESS).initialize(address(this), Ownable.owner());
        if (GUARD_ADDRESS == address(0)) {
            revert();
        }
    }

    function calculateTicketHash(Ticket memory _ticket)
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
        bytes32 ticketHash = calculateTicketHash(_newTicket);
        sig[ticketHash] = _newTicket;

        _newTicket.ticketHash = ticketHash;

        emit TicketCreate(
            _newTicket.targetExecutionBlock,
            _newTicket.creationBlock,
            _newTicket.tokenAddress,
            _newTicket.caller,
            _newTicket.from,
            _newTicket.to,
            _newTicket.value,
            _newTicket.fee,
            _newTicket.nonce
        );

        return ticketHash;
    }

    function getTicket(bytes32 _ticketHash)
        external
        view
        override
        returns (Ticket memory _ticket)
    {
        return sig[_ticketHash];
    }

    function coreExecution(bytes32 _ticketHash, address caller)
        external
        guard
        returns (bool)
    {}
}
