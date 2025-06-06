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
