// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title DigitalEuro
 * @dev ERC-20 token representing digital euro with minting capabilities
 * Only accounts with MINTER_ROLE (Central Bank) can mint new tokens
 */
contract DigitalEuro is ERC20, AccessControl {
    //keccak256 es una función global en el lenguaje Solidity que se utiliza para generar un hash de un string.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event TokensMinted(address indexed to, uint256 amount);

    error DigitalEuroInvalidAmount();

    /**
     * @dev Constructor that gives the deployer the default admin and minter roles
     * @param name Token name
     * @param symbol Token symbol
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Grant the contract deployer the default admin role and minter role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Mints new tokens to a specified address
     * Can only be called by accounts with MINTER_ROLE (Central Bank)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint (in wei units)
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (amount == 0) {
            revert DigitalEuroInvalidAmount();
        }

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Returns the number of decimals used for token amounts
     * @return Number of decimals
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
