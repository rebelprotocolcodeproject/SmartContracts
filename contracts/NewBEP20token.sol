// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

///////////////////
// imports
///////////////////

// This library provides the standard implementation of the ERC20 token,
//  which is the most common standard for creating tokens on Ethereum.
//  It includes basic functionality like transferring tokens,
//  checking balances, and managing allowances.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This library helps prevent reentrancy attacks,
// where a malicious contract repeatedly calls a function before previous calls are finished,
// potentially causing unexpected behavior or draining funds.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// This library provides utilities for working with Elliptic Curve Digital Signature Algorithm (ECDSA) signatures.
// It is used to verify the authenticity of messages
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// This extension to the ERC20 standard allows for approvals to be made via signatures rather than requiring an on-chain transaction.
// This is defined in EIP-2612.
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/*
 * @title NewBEP20token
 * @dev This is an ERC20-compliant token contract with additional security features to prevent abuse.
 * - Total supply is fixed at 1,000,000,000 tokens.
 * - The contract owner cannot mint additional tokens.
 * - The contract owner cannot blacklist addresses.
 * - There is no honeypot functionality in this contract.
 * - The contract owner cannot set transaction fees.
 * - Trading is enabled by default.
 * - Implemented transfer throttling to prevent excessive transactions.
 * - Utilizes OpenZeppelin libraries for enhanced security.
 *
 * Author:
 */

contract RebelToken is ERC20, ERC20Permit, ReentrancyGuard {
    ///////////////////
    // Errors
    ///////////////////

    error NewBEP20token__ToomanyTransactionsInAShortTime();
    error NewBEP20token__TransferTooSoonPleaseWait();
    error NewBEP20token_TooManyTransactionsInAShortTime();

    ///////////////////
    // State Variables
    ///////////////////

    /*
     * @dev Constant s_MIN_TIME_BETWEEN_TRANSFERS defines the minimum time interval between consecutive transfer transactions.
     * This is implemented to prevent overly frequent transactions that might be triggered by automated programs or bots.
     * For example, if the value of s_MIN_TIME_BETWEEN_TRANSFERS is set to 3 minutes, a user won't be able to execute two transfer
     * transactions between the same accounts within less than the specified time interval, which helps prevent potential manipulations
     * or exploitation of the system.
     */

    uint256 private constant s_MIN_TIME_BETWEEN_TRANSFERS = 1 minutes;

    /*
     * @dev Mapping to track the last transaction block number for each address.
     */

    mapping(address => uint) private s_lastTransactionBlock;

    /*
     * @dev Mapping to track the last transaction time for each address.
     */

    mapping(address => uint) private s_lastTransactionTime;

    ///////////////////
    // constructor
    ///////////////////

    /*
     * @dev Contract constructor, sets the initial amount of tokens and registers them to the creator's address.
     */

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        uint256 initialSupply = 1000000000 * (10 ** uint256(decimals()));
        _mint(msg.sender, initialSupply);
    }

    ///////////////////
    // Modifiers
    ///////////////////

    /*
     * @dev Modifier to limit the number of transactions within a specified number of blocks.
     * @param minBlocks The minimum number of blocks between transactions.
     */

    modifier throttleBlocks(uint _minBlocks) {
        if (block.number < s_lastTransactionBlock[msg.sender] + _minBlocks) {
            revert NewBEP20token__ToomanyTransactionsInAShortTime();
        }
        _;
        s_lastTransactionBlock[msg.sender] = block.number;
    }

    /*
     * @dev Modifier timeLimit restricts the execution of a function based on the time elapsed since the last transaction from a specific address.
     * It ensures that a certain amount of time, defined by s_MIN_TIME_BETWEEN_TRANSFERS, has passed since the last transaction from the given address.
     * If the time condition is not met, the function execution is reverted with the error message "Transfer too soon, please wait."
     * This modifier is useful for preventing users from executing transactions too frequently, thus mitigating potential abuse or spamming of the system.
     */

    modifier timeLimit(address _from) {
        if (
            block.timestamp <
            s_lastTransactionTime[_from] + s_MIN_TIME_BETWEEN_TRANSFERS
        ) {
            revert NewBEP20token__TransferTooSoonPleaseWait();
        }
        _;
        s_lastTransactionTime[_from] = block.timestamp; // Update the last transaction time
    }

    /*
     * @dev Modifier to limit the number of transactions within a specified amount of time in seconds.
     * @param minSeconds The minimum time in seconds between transactions.
     */

    modifier throttleTime(uint _minSeconds) {
        if (block.timestamp < s_lastTransactionTime[msg.sender] + _minSeconds) {
            revert NewBEP20token_TooManyTransactionsInAShortTime();
        }
        _;
        s_lastTransactionTime[msg.sender] = block.timestamp;
    }

    ///////////////////
    // Function
    ///////////////////

    /*
     * @dev Function transfer facilitates the transfer of tokens from the sender's address to the specified recipient.
     * It overrides the transfer function from the parent contract and adds the timeLimit modifier to restrict the frequency of transfers
     * from the sender's address based on the s_MIN_TIME_BETWEEN_TRANSFERS constant.
     * - The timeLimit modifier ensures that a certain amount of time has passed since the last transfer from the sender's address,
     * helping to prevent excessive transaction frequency.
     * - If the time limit requirement is met, the transfer is executed by calling the transfer function of the parent contract.
     * - The function returns a boolean indicating whether the transfer was successful or not.
     */

    function transfer(
        address _recipient,
        uint256 _amount
    ) public virtual override timeLimit(msg.sender) returns (bool) {
        return super.transfer(_recipient, _amount);
    }

    /*
     * @dev Function transferFrom allows a designated spender to transfer tokens from the sender's address to the specified recipient.
     * It overrides the transferFrom function from the parent contract and adds the timeLimit modifier to restrict the frequency of transfers
     * from the sender's address based on the s_MIN_TIME_BETWEEN_TRANSFERS constant.
     * - The timeLimit modifier ensures that a certain amount of time has passed since the last transfer from the sender's address,
     * helping to prevent excessive transaction frequency.
     * - If the time limit requirement is met, the transferFrom function of the parent contract is called to execute the transfer.
     * - The function returns a boolean indicating whether the transfer was successful or not.
     */

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override timeLimit(_sender) returns (bool) {
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /*
     * @dev Function for secure token transfer, using modifiers for enhanced transaction security.
     * @param to The recipient's address.
     * @param amount The amount of tokens to transfer.
     */

    function secureTransfer(
        address _to,
        uint256 _amount
    ) public nonReentrant throttleBlocks(3) throttleTime(60) {
        _transfer(_msgSender(), _to, _amount);
    }
}
