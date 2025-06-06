// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title AfricanStablecoin
 * @dev An ERC20 stablecoin contract pegged to a mock "African stablecoin".
 * This contract includes basic minting/burning by the owner to simulate pegging.
 * In a real-world scenario, the pegging mechanism would be more complex and decentralized.
 */
contract AfricanStablecoin is ERC20, Ownable {
    // Event to log minting of stablecoins
    event StablecoinMinted(address indexed to, uint256 amount);
    // Event to log burning of stablecoins
    event StablecoinBurned(address indexed from, uint256 amount);

    /**
     * @dev Constructor that initializes the contract with the name and symbol.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Initial mint to the deployer for testing purposes
        _mint(msg.sender, 1000 * (10 ** decimals())); // Mint 1000 tokens to the deployer
        emit StablecoinMinted(msg.sender, 1000 * (10 ** decimals()));
    }

    /**
     * @dev Allows the owner to mint new tokens.
     * In a real stablecoin, this would be tied to collateralization mechanisms.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit StablecoinMinted(to, amount);
    }

    /**
     * @dev Allows the owner to burn tokens from a specific address.
     * In a real stablecoin, this would be tied to redemption mechanisms.
     * @param from The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
        emit StablecoinBurned(from, amount);
    }
}

/**
 * @title RemittanceAndSavings
 * @dev A contract for cross-border remittances, token swapping/exchange, and savings features.
 * This contract uses a mock "AfricanStablecoin" and integrates with Chainlink Price Feeds.
 */
contract RemittanceAndSavings is Ownable {
    AfricanStablecoin public stablecoin; // The stablecoin contract
    AggregatorV3Interface public priceFeedEthUsd; // Chainlink ETH/USD Price Feed
    AggregatorV3Interface public priceFeedUsdMockLocal; // Chainlink USD/Mock Local Currency Price Feed (e.g., USD/GHS)

    uint256 public constant SAVINGS_INTEREST_RATE_PER_YEAR = 5; // 5% annual interest rate (mock)
    uint256 public constant SAVINGS_PERIOD_SECONDS = 30 days; // Savings period for interest calculation

    mapping(address => uint256) public savingsBalance; // User's locked savings balance
    mapping(address => uint256) public savingsStartTime; // Timestamp when savings started

    event TokensSwapped(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event SavingsDeposited(address indexed user, uint256 amount);
    event SavingsWithdrawn(address indexed user, uint256 amount);
    event InterestEarned(address indexed user, uint256 interestAmount);

    /**
     * @dev Constructor to initialize the contract with the stablecoin address and Chainlink price feed addresses.
     * @param _stablecoinAddress Address of the deployed AfricanStablecoin contract.
     * @param _priceFeedEthUsd Address of the Chainlink ETH/USD price feed.
     * @param _priceFeedUsdMockLocal Address of the Chainlink USD/Mock Local Currency price feed.
     */
    constructor(
        address _stablecoinAddress,
        address _priceFeedEthUsd,
        address _priceFeedUsdMockLocal
    ) {
        require(_stablecoinAddress != address(0), "Invalid stablecoin address");
        require(_priceFeedEthUsd != address(0), "Invalid ETH/USD price feed address");
        require(_priceFeedUsdMockLocal != address(0), "Invalid USD/Local price feed address");

        stablecoin = AfricanStablecoin(_stablecoinAddress);
        priceFeedEthUsd = AggregatorV3Interface(_priceFeedEthUsd);
        priceFeedUsdMockLocal = AggregatorV3Interface(_priceFeedUsdMockLocal);
    }

    /**
     * @dev Gets the latest ETH/USD price from Chainlink.
     * @return The latest price, multiplied by $10^8$.
     */
    function getLatestEthUsdPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedEthUsd.latestRoundData();
        return price;
    }

    /**
     * @dev Gets the latest USD/Mock Local Currency price from Chainlink.
     * @return The latest price, multiplied by $10^8$.
     */
    function getLatestUsdMockLocalPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedUsdMockLocal.latestRoundData();
        return price;
    }

    /**
     * @dev Simulates buying stablecoins with ETH.
     * Users send ETH to the contract, and stablecoins are minted and sent to them.
     * In a real system, ETH would be swapped for stablecoins via a liquidity pool.
     * @param amountToBuy Amount of stablecoin tokens to buy.
     */
    function buyStablecoinWithEth(uint256 amountToBuy) public payable {
        require(amountToBuy > 0, "Amount to buy must be greater than zero");
        require(msg.value > 0, "ETH sent must be greater than zero");

        int256 ethUsdPrice = getLatestEthUsdPrice();
        require(ethUsdPrice > 0, "Failed to get ETH/USD price");

        // Calculate required ETH based on mock stablecoin peg to USD (e.g., 1 Stablecoin = 1 USD)
        // This is a simplified calculation. A real system would use more precise conversion.
        // Assuming 1 Stablecoin = 1 USD for simplicity.
        // Amount of stablecoin requested (in USD equivalent) / (ETH price in USD / 10^8)
        uint256 stablecoinUsdEquivalent = amountToBuy; // Assuming 1 Stablecoin = 1 USD
        uint256 requiredEth = (stablecoinUsdEquivalent * (10 ** 18)) / (uint256(ethUsdPrice) / (10 ** 10)); // Adjust decimals

        require(msg.value >= requiredEth, "Insufficient ETH sent for the requested amount");

        // Mint stablecoins to the user
        stablecoin.mint(msg.sender, amountToBuy);

        // Refund any excess ETH
        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }

        emit TokensSwapped(msg.sender, address(0), address(stablecoin), msg.value, amountToBuy);
    }

    
}