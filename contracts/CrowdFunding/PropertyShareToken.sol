// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function transfer(address r, uint256 a) external returns (bool);
    function transferFrom(address s, address r, uint256 a) external returns (bool);
    function allowance(address o, address s) external view returns (uint256);
    function approve(address s, uint256 a) external returns (bool);
}

/// @title PropertyShareToken
/// @notice ERC20-style token representing fractional ownership in a single property.
contract PropertyShareToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    address public manager;      // Crowdfund manager
    address public sponsor;      // Property sponsor

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _manager,
        address _sponsor
    ) {
        require(_manager != address(0) && _sponsor != address(0), "Zero addr");
        name = _name;
        symbol = _symbol;
        manager = _manager;
        sponsor = _sponsor;
    }

    
}
