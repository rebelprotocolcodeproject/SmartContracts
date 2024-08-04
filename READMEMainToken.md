# NewBEP20token
NewBEP20token is an ERC20-compliant token contract with added security features to prevent abuse. This token uses OpenZeppelin libraries for enhanced security and implements transfer throttling to control transaction frequency.

## Key Features
* Fixed Supply: The total supply is set at 1,000,000,000 tokens.
* No Minting: The contract owner cannot mint additional tokens.
* No Blacklisting: The contract owner cannot blacklist addresses.
* No Honeypot: The contract owner cannot set transaction fees.
* Enabled Trading: Trading is enabled by default.
* Transfer Throttling: Prevents excessive transactions by limiting transfer frequency.

# State Variables
* s_MIN_TIME_BETWEEN_TRANSFERS: Minimum time interval between consecutive transfers (1 minute).
* s_lastTransactionBlock: Tracks the last transaction block number for each address.
* s_lastTransactionTime: Tracks the last transaction time for each address.

 # Modifiers
* timeLimit(address _from): Ensures a certain amount of time has passed since the last transaction from the specified address.
* throttleBlocks(uint _minBlocks): Limits the number of transactions within a specified number of blocks.
* throttleTime(uint _minSeconds): Limits the number of transactions within a specified amount of time.
# Functions

* transfer(address _recipient, uint256 _amount): Transfers tokens from the sender to the recipient, restricted by timeLimit.
* transferFrom(address _sender, address _recipient, uint256 _amount): Allows a designated spender to transfer tokens from the sender to the recipient, restricted by timeLimit.
* secureTransfer(address _to, uint256 _amount): Secure token transfer using nonReentrant, throttleBlocks, and throttleTime modifiers.

# Usage
To use the NewBEP20token contract, deploy it with the desired token name and symbol. The initial supply of 1,000,000,000 tokens will be minted to the deployer's address.
```
solidity

constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Permit(_name) {
    uint256 initialSupply = 1000000000 * (10 ** uint256(decimals()));
    _mint(msg.sender, initialSupply);
}
```
# Security
This contract uses OpenZeppelin libraries for enhanced security and includes measures to prevent reentrancy attacks and excessive transaction frequency.




