// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Paymaster
 * @dev A contract that sponsors gas fees and logs transactions.
 */
contract Paymaster {
    event GasSponsored(address indexed wallet, uint256 amount, address token); // Logs gas sponsorship events
    event ERC20GasPayment(address indexed sender, address token, uint256 amount); // Logs ERC-20 gas payments

    /**
     * @dev Sponsors gas fees for a transaction.
     * @param wallet The wallet receiving gas sponsorship.
     * @param amount The amount sponsored.
     * @param token The ERC-20 token used for payment (optional).
     */
    function sponsorGas(address wallet, uint256 amount, address token) external {
        emit GasSponsored(wallet, amount, token); // Logs sponsorship details
    }

    /**
     * @dev Accepts ERC-20 token payments for gas fees.
     * @param token The ERC-20 token address.
     * @param amount The amount of tokens for payment.
     */
    function acceptERC20GasPayment(address token, uint256 amount) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "ERC-20 payment failed");
        emit ERC20GasPayment(msg.sender, token, amount); // Logs gas payment transactions
    }
}
