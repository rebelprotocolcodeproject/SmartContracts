# Presale Contract Documentation

## Overview

The Presale contract is designed to facilitate the sale of tokens during a presale phase. Users can purchase tokens using BNB, USDT, or USDC. The contract ensures security through reentrancy guards and ownership controls, utilizes Chainlink for real-time price feeds, and manages token sales, user balances, and presale stages.

**Key Feature**

- **Presale Token Supply:** 150,000,000 tokens (15% of the total supply of NewBEP20Token).
- **Prices per Round:**
    - Round 1: 0.008 USD
    - Round 2: 0.012 USD
    - Round 3: 0.014 USD
    - Round 4: 0.016 USD
    - Round 5: 0.018 USD
- Allows users to buy tokens with BNB, USDT, or USDC.
- Uses Chainlink to fetch real-time BNB price in USD.
- Provides security features like reentrancy guard and ownership control.
- Keeps track of user balances and allows them to claim their purchased tokens after the presale ends.
- Managed by an owner, who can control the presale status and end the presale.

## State Variables

- `mainToken`: The token being sold.
- `USDT`, `USDC`: Stablecoins accepted for token purchases.
- `tokensToSell`: Total number of tokens available for sale.
- `tokenPerUsdPrice`: Array holding token prices per USD for different presale phases.
- `totalStages`: Total number of presale phases.
- `tokenDecimals`: Decimals of the main token.
- `minUsdAmountToBuy`: Minimum USD equivalent amount required to participate in the presale.
- `priceFeed`: Chainlink price feed contract address.
- `currentStage`: Current phase of the presale.
- `totalUsers`, `soldToken`, `amountRaised`, `amountRaisedUSDT`, `amountRaisedUSDC`, `totalRaised`, `uniqueBuyers`: Various counters and trackers for presale statistics.
- `fundReceiver`: Address where raised funds are sent.
- `presaleStatus`: Boolean indicating if the presale is active.
- `isPresaleEnded`: Boolean indicating if the presale has ended.
- `UsersAddresses`: Array of user addresses who participated in the presale.

## Mappings

- `users`: Mapping of user addresses to their purchase details.
- `phases`: Mapping of phase IDs to their respective details.
- `isExist`: Mapping to check if an address has participated in the presale.

## Constructor

```solidity
constructor(
    IERC20 _token,
    address _fundReceiver,
    address _USDT,
    address _USDC
)

```

Initializes the contract with the main token, fund receiver address, USDT and USDC contract addresses, sets token decimals, and initializes presale phases.

## Events

- `BuyToken(address indexed _user, uint256 indexed _amount)`: Emitted when a user buys tokens.
- `ClaimToken(address _user, uint256 indexed _amount)`: Emitted when a user claims their purchased tokens.
- `UpdatePrice(uint256 _oldPrice, uint256 _newPrice)`: Emitted when the token price is updated.

## Public Functions

- `getLatestPrice()`: Fetches the latest BNB price from Chainlink.
- `nativeToToken(uint256 _amount, uint256 phaseId)`: Converts BNB amount to the equivalent number of tokens.
- `usdtToToken(uint256 _amount, uint256 phaseId)`: Converts USD amount to the equivalent number of tokens.
- `totalUsersCount()`: Returns the total number of unique user addresses.

## External Functions

- `buyToken(uint _bnbamount)`: Allows users to buy tokens with BNB.
- `buyTokenUSDT(uint256 amount)`: Allows users to buy tokens with USDT.
- `buyTokenUSDC(uint256 amount)`: Allows users to buy tokens with USDC.
- `claimTokens()`: Allows users to claim their purchased tokens after the presale ends.
- `getPhaseDetail(uint256 phaseInd)`: Returns the price of tokens for a given phase.

## OnlyOwner Functions - only owner can call this function

- `updateStableTokens(IERC20 _USDT, IERC20 _USDC)`: Updates the USDT and USDC contract addresses.
- `updatePresale(uint256 _phaseId, uint256 _tokenPerUsdPrice)`: Updates the token price for a given phase.
- `setPresaleStatus(bool _status)`: Sets the presale status.
- `endPresale()`: Ends the presale.
- `updateInfos(uint256 _sold, uint256 _raised, uint256 _raisedInUsdt)`: Updates presale statistics.
- `updateToken(address _token)`: Updates the main token address.
- `whitelistAddresses(address[] memory _addresses, uint256[] memory _tokenAmount)`: Adds addresses to the whitelist and sets their claimable token amounts.
- `updateMinUsdAmountToBuy(uint _usd)`: Updates the minimum USD amount required to participate in the presale.
- `initiateTransfer(uint256 _value)`: Withdraws funds to the fund receiver.
- `changeFundReciever(address _addr)`: Changes the fund receiver address.
- `updatePriceFeed(AggregatorV3Interface _priceFeed)`: Updates the Chainlink price feed address.
- `setCurrentStage(uint256 _stageNum)`: Sets the current presale stage.
- `transferTokens(IERC20 token, uint256 _value)`: Withdraws tokens to the fund receiver.

## Private Functions

- `_msgSender()`: Returns the address of the sender.
- `_msgData()`: Returns the calldata of the sender.
- `_nonReentrantBefore()`: Sets reentrancy guard before executing a function.
- `_nonReentrantAfter()`: Resets reentrancy guard after executing a function.

# changing and update the presale

### Set, Paused, and End Presale

- `setPresaleStatus`
- `endPresale`

### Price Changing

- `updatePresale`
- `updatePriceFeed`

### Stage Change

- `setCurrentStage`

### Total Tokens Sold and Total USD Raised, USDT, USDC, BNB Raised

- `updateInfos`
- `buyToken`
- `buyTokenUSDT`
- `buyTokenUSDC`
