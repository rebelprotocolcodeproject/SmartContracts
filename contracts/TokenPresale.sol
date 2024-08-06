//SPDX-License-Identifier: MIT Licensed
pragma solidity 0.8.20;

///////////////////
// imports
///////////////////

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title Presale Contract
 * @dev This contract handles the presale of tokens. Users can buy tokens with BNB, USDT, or USDC.
 * - Allows the owner to set the presale status and end the presale.
 * - Utilizes Chainlink to fetch the real-time price of BNB.
 * - Implements security features to prevent abuse, such as reentrancy guard and ownership control.
 * - Maintains records of user balances and allows users to claim their purchased tokens once the presale ends.
 * - Uses the OpenZeppelin Ownable contract for ownership management.
 *
 * Author: Sanjay Sen
 */

contract Presale is Ownable, ReentrancyGuard {
    ///////////////////
    // State Variables
    ///////////////////

    IERC20 public mainToken;
    IERC20 public USDT;
    IERC20 public USDC;
    uint256 public tokensToSell;
    uint256[] public tokenPerUsdPrice;
    uint256 public totalStages;
    uint8 public tokenDecimals;
    uint256 public minUsdAmountToBuy = 40000000; //40usdt usdc
    AggregatorV3Interface public priceFeed;
    AggregatorV3Interface public priceFeedUSDT;
    AggregatorV3Interface public priceFeedUSDC;

    struct Phase {
        uint256 tokenPerUsdPrice;
    }

    uint256 public currentStage;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public amountRaisedUSDT;
    uint256 public amountRaisedUSDC;
    uint256 public totalRaised;
    uint256 public uniqueBuyers;
    address payable public fundReceiver;

    bool public presaleStatus;
    bool public isPresaleEnded;

    address[] public UsersAddresses;
    struct User {
        uint256 native_balance;
        uint256 usdt_balance;
        uint256 usdc_balance;
        uint256 claimedAmount;
        uint256 claimAbleAmount;
        uint256 purchasedToken;
    }

    mapping(address => User) public users;
    mapping(uint256 => Phase) public phases;
    mapping(address => bool) public isExist;

    ///////////////////
    ////event
    ///////////////////

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address _user, uint256 indexed _amount);
    event UpdatePrice(uint256 _oldPrice, uint256 _newPrice);

    ///////////////////
    // constructor
    ///////////////////

    /**
     * @dev Initializes the presale contract.
     * @param _token The address of the token being sold.
     * @param _fundReceiver The address that will receive the funds raised.
     * @param _USDT The address of the USDT token contract.
     * @param _USDC The address of the USDC token contract.
     */

    constructor(
        IERC20 _token,
        address _fundReceiver,
        address _USDT,
        address _USDC
    ) {
        mainToken = _token;
        fundReceiver = payable(_fundReceiver);
        USDT = IERC20(_USDT);
        USDC = IERC20(_USDC);
        priceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        priceFeedUSDT = AggregatorV3Interface(
            0xB97Ad0E74fa7d920791E90258A6E2085088b4320
        );
        priceFeedUSDC = AggregatorV3Interface(
            0x51597f405303C4377E36123cBc172b13269EA163
        );

        tokenDecimals = mainToken.decimals();
        tokensToSell = 150000000 * 10 ** tokenDecimals;
        tokenPerUsdPrice = [
            12500 * 10 ** (tokenDecimals - 2),
            8333 * 10 ** (tokenDecimals - 2),
            7142 * 10 ** (tokenDecimals - 2),
            6250 * 10 ** (tokenDecimals - 2),
            5555 * 10 ** (tokenDecimals - 2)
        ];
        for (uint256 i = 0; i < tokenPerUsdPrice.length; i++) {
            phases[i].tokenPerUsdPrice = tokenPerUsdPrice[i];
        }
        totalStages = tokenPerUsdPrice.length;
    }

    /**
     * @dev Updates the token price for a given phase.
     * @param _phaseId The ID of the phase to update.
     * @param _tokenPerUsdPrice The new token price per USD.
     */

    function updatePresale(
        uint256 _phaseId,
        uint256 _tokenPerUsdPrice
    ) public onlyOwner {
        phases[_phaseId].tokenPerUsdPrice = _tokenPerUsdPrice;
    }

    /**
     * @dev Fetches the latest price of BNB in USD from the Chainlink oracle.
     * @return The latest price of BNB in USD with 18 decimals.
     */

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    // update usdc usdt
    function getLatestPriceUSDT() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedUSDT.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function getLatestPriceUSDC() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedUSDC.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    /**
     * @dev Allows users to buy tokens with BNB during the presale.
     * @param _bnbamount The amount of BNB to spend in wei.
     */

    function buyToken(uint _bnbamount) public payable nonReentrant {
        require(msg.value == _bnbamount, "Incorrect Ether value sent");
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }

        // require(_bnbamount >= minUsdAmountToBuy, "Insufficient USD amount");
        // fundReceiver.transfer(_bnbamount);
        (bool success, ) = fundReceiver.call{value: _bnbamount}("");
        require(success, "Payment failed");

        uint256 usdAmount = (_bnbamount * (getLatestPrice()) * (1e6)) /
            (1e18 * 1e18);
        require(usdAmount >= minUsdAmountToBuy, "Insufficient USD amount");

        uint256 numberOfTokens;
        numberOfTokens = nativeToToken(_bnbamount, currentStage);
        require(
            soldToken + numberOfTokens <= tokensToSell,
            "Phase Limit Reached"
        );
        soldToken = soldToken + (numberOfTokens);
        amountRaised = amountRaised + _bnbamount;
        totalRaised += usdAmount;

        users[msg.sender].native_balance =
            users[msg.sender].native_balance +
            (_bnbamount);
        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;
        users[msg.sender].purchasedToken += numberOfTokens;
        emit BuyToken(msg.sender, numberOfTokens);
    }

    /**
     * @dev Allows users to buy tokens with USDT during the presale.
     * @param amount The amount of USDT to spend.
     */

    function buyTokenUSDT(uint256 amount) public nonReentrant {
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        // update
        // require(amount >= minUsdAmountToBuy, "Insufficient USD amount");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }
        USDT.transferFrom(msg.sender, fundReceiver, amount);

        // update
        uint256 usdAmount = (amount * (getLatestPriceUSDT()) * (1e6)) /
            (1e18 * 1e18);
        require(usdAmount >= minUsdAmountToBuy, "Insufficient USD amount");

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount, currentStage);
        require(
            soldToken + numberOfTokens <= tokensToSell,
            "Phase Limit Reached"
        );
        soldToken = soldToken + numberOfTokens;
        amountRaisedUSDT = amountRaisedUSDT + amount;
        totalRaised += usdAmount;

        users[msg.sender].usdt_balance += amount;
        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;

        users[msg.sender].purchasedToken += numberOfTokens;
        emit BuyToken(msg.sender, numberOfTokens);
    }

    /**
     * @dev Allows users to buy tokens with USDC during the presale.
     * @param amount The amount of USDC to spend.
     */

    function buyTokenUSDC(uint256 amount) public nonReentrant {
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        // update
        // require(amount >= minUsdAmountToBuy, "Insufficient USD amount");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }
        USDC.transferFrom(msg.sender, fundReceiver, amount);

        // update
        uint256 usdAmount = (amount * (getLatestPriceUSDC()) * (1e6)) /
            (1e18 * 1e18);
        require(usdAmount >= minUsdAmountToBuy, "Insufficient USD amount");

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount, currentStage);
        require(
            soldToken + numberOfTokens <= tokensToSell,
            "Phase Limit Reached"
        );

        soldToken = soldToken + numberOfTokens;
        amountRaisedUSDC = amountRaisedUSDC + amount;
        totalRaised += usdAmount;

        users[msg.sender].usdc_balance += amount;

        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;

        users[msg.sender].purchasedToken += numberOfTokens;
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // claim the token.
    // can be called only when presaleEnded.

    function claimTokens() external {
        require(isPresaleEnded, "Presale has not ended yet");
        require(isExist[msg.sender], "User don't exist");
        User storage user = users[msg.sender];
        uint256 claimAmount = user.claimAbleAmount;
        require(claimAmount > 0, "No tokens to claim");
        user.claimedAmount += claimAmount;
        mainToken.transfer(msg.sender, claimAmount);
        user.claimAbleAmount = 0;
        emit ClaimToken(msg.sender, claimAmount);
    }

    function getPhaseDetail(
        uint256 phaseInd
    ) external view returns (uint256 priceUsd) {
        Phase memory phase = phases[phaseInd];
        return (phase.tokenPerUsdPrice);
    }

    /**
     * @dev Allows the owner to set the presale status.
     */
    function setPresaleStatus(bool _status) external onlyOwner {
        presaleStatus = _status;
    }

    /**
     * @dev Allows the owner to end the presale.
     */

    function endPresale() external onlyOwner {
        require(!isPresaleEnded, "Already ended");
        isPresaleEnded = true;
    }

    /**
     * @dev Converts the BNB amount to the equivalent number of tokens.
     * @param _amount The amount of BNB to convert.
     * @param  phaseId The current presale stage.
     * @return The number of tokens equivalent to the given BNB amount.
     */

    function nativeToToken(
        uint256 _amount,
        uint256 phaseId
    ) public view returns (uint256) {
        uint256 bnbToUsd = (_amount * (getLatestPrice()) * (1e6)) /
            ((1e18) * (1e18));
        uint256 numberOfTokens = (bnbToUsd * phases[phaseId].tokenPerUsdPrice) /
            (1e6);
        return numberOfTokens;
    }

    /**
     * @dev Converts the USD amount to the equivalent number of tokens.
     * @param _amount The amount of USD to convert.
     * @param phaseId The current presale stage.
     * @return The number of tokens equivalent to the given USD amount.
     */

    function usdtToToken(
        uint256 _amount,
        uint256 phaseId
    ) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * phases[phaseId].tokenPerUsdPrice) /
            (1e18);

        return numberOfTokens;
    }

    function updateInfos(
        uint256 _sold,
        uint256 _raised,
        uint256 _raisedInUsdt
    ) external onlyOwner {
        soldToken = _sold;
        amountRaised = _raised;
        amountRaisedUSDT = _raisedInUsdt;
    }

    /**
     * @dev Allows the owner to change the main token address.
     */
    function updateToken(address _token) external onlyOwner {
        mainToken = IERC20(_token);
    }

    function whitelistAddresses(
        address[] memory _addresses,
        uint256[] memory _tokenAmount
    ) external onlyOwner {
        require(
            _addresses.length == _tokenAmount.length,
            "Addresses and amounts must be equal"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            users[_addresses[i]].claimAbleAmount += _tokenAmount[i];
        }
    }

    /**
     * @dev Allows the owner to change tokens for buy.
     */

    function updateStableTokens(IERC20 _USDT, IERC20 _USDC) external onlyOwner {
        USDT = IERC20(_USDT);
        USDC = IERC20(_USDC);
    }

    // change the minUsdAmountToBuy.
    function updateMinUsdAmountToBuy(uint _usd) external onlyOwner {
        minUsdAmountToBuy = _usd;
    }

    // to withdraw funds for liquidity
    function initiateTransfer(uint256 _value) external onlyOwner {
        fundReceiver.transfer(_value);
    }

    function totalUsersCount() external view returns (uint256) {
        return UsersAddresses.length;
    }

    // change fundreceiver
    function changeFundReciever(address _addr) external onlyOwner {
        fundReceiver = payable(_addr);
    }

    // update presale
    function updatePriceFeed(
        AggregatorV3Interface _priceFeed,
        AggregatorV3Interface _priceFeedUSDT,
        AggregatorV3Interface _priceFeedUSDC
    ) external onlyOwner {
        priceFeed = _priceFeed;
        priceFeedUSDT = _priceFeedUSDT;
        priceFeedUSDC = _priceFeedUSDC;
    }

    // funtion is used to change the stage of presale
    function setCurrentStage(uint256 _stageNum) public onlyOwner {
        currentStage = _stageNum;
    }

    // to withdraw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(fundReceiver, _value);
    }
}
