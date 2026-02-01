// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PrimaryMarket
 * @dev Contract for the primary market sale of tokenized financial assets
 * Allows investors to purchase financial assets using Digital Euro (DEUR)
 */
contract PrimaryMarket is
    AccessControl,
    Pausable,
    ReentrancyGuard,
    ERC1155Holder
{
    // Role for the investment fund manager
    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");

    // Reference to the Digital Euro token (payment method)
    IERC20 public immutable digitalEuro;

    // Reference to the Financial Assets contract
    IERC1155 public immutable financialAssets;

    // Address that receives the payment (fund treasury)
    address public fundTreasury;

    // Mapping from asset ID to price in Digital Euro (in wei units, 6 decimals)
    mapping(uint256 => uint256) private _assetPrices;

    // Events
    event AssetConfigured(uint256 indexed assetId, uint256 price);
    event AssetPurchased(
        address indexed buyer,
        uint256 indexed assetId,
        uint256 amount,
        uint256 totalPrice
    );
    event FundTreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );

    // Custom errors
    error PrimaryMarketInvalidAddress();
    error PrimaryMarketInvalidAmount();
    error PrimaryMarketInvalidPrice();
    error PrimaryMarketAssetNotConfigured();
    error PrimaryMarketTransferFailed();

    // Removed errors (not needed after optimization):
    // error PrimaryMarketInsufficientAssets();
    // error PrimaryMarketInsufficientBalance();
    // error PrimaryMarketInsufficientAllowance();

    /**
     * @dev Constructor
     * @param _digitalEuro Address of the Digital Euro token contract
     * @param _financialAssets Address of the Financial Assets contract
     * @notice fundTreasury is set to msg.sender by default, can be changed later via updateFundTreasury
     */
    constructor(address _digitalEuro, address _financialAssets) {
        if (_digitalEuro == address(0) || _financialAssets == address(0)) {
            revert PrimaryMarketInvalidAddress();
        }

        digitalEuro = IERC20(_digitalEuro);
        financialAssets = IERC1155(_financialAssets);
        fundTreasury = msg.sender; // Deployer is the default fund treasury

        // Grant roles to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FUND_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Configures the price for an asset type
     * Can only be called by fund manager
     * @param assetId ID of the asset
     * @param price Price in Digital Euro (in wei units, 6 decimals)
     */
    function configureAsset(
        uint256 assetId,
        uint256 price
    ) external onlyRole(FUND_MANAGER_ROLE) {
        if (price == 0) {
            revert PrimaryMarketInvalidPrice();
        }

        _assetPrices[assetId] = price;
        emit AssetConfigured(assetId, price);
    }

    /**
     * @dev OLD VERSION - Performs many unnecessary redundant checks
     * Balance and allowance checks are already performed by ERC20/ERC1155 contracts
     * internally, so these checks only waste extra gas without adding real security.
     * Additionally, they don't prevent race conditions since between the check and the transfer
     * another transaction can modify the state.
     */
    /*
    function buyAsset_OLD(
        uint256 assetId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        if (amount == 0) {
            revert PrimaryMarketInvalidAmount();
        }

        // Check asset is configured with a price
        uint256 price = _assetPrices[assetId];
        if (price == 0) {
            revert PrimaryMarketAssetNotConfigured();
        }

        // Calculate total price
        uint256 totalPrice = price * amount;

        // Check contract has enough assets available - REDUNDANT
        uint256 availableAssets = financialAssets.balanceOf(
            address(this),
            assetId
        );
        if (availableAssets < amount) {
            revert PrimaryMarketInsufficientAssets();
        }

        // Check buyer has enough Digital Euro - REDUNDANT
        uint256 buyerBalance = digitalEuro.balanceOf(msg.sender);
        if (buyerBalance < totalPrice) {
            revert PrimaryMarketInsufficientBalance();
        }

        // Check buyer has approved this contract to spend enough Digital Euro - REDUNDANT
        uint256 allowance = digitalEuro.allowance(msg.sender, address(this));
        if (allowance < totalPrice) {
            revert PrimaryMarketInsufficientAllowance();
        }

        // Transfer Digital Euro from buyer to fund treasury
        bool success = digitalEuro.transferFrom(
            msg.sender,
            fundTreasury,
            totalPrice
        );
        if (!success) {
            revert PrimaryMarketTransferFailed();
        }

        // Transfer assets from contract to buyer
        financialAssets.safeTransferFrom(
            address(this),
            msg.sender,
            assetId,
            amount,
            ""
        );

        emit AssetPurchased(msg.sender, assetId, amount, totalPrice);
    }
    */

    /**
     * @dev Allows investors to purchase assets using Digital Euro
     * Investor must first approve this contract to spend their Digital Euro
     * @param assetId ID of the asset to purchase
     * @param amount Amount of assets to purchase
     *
     * NOTE: This optimized version removes redundant balance and allowance checks.
     * ERC20 and ERC1155 contracts already perform these validations internally,
     * so if there is insufficient balance, allowance or available assets,
     * the transactions will automatically revert with the corresponding errors.
     */
    function buyAsset(
        uint256 assetId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        if (amount == 0) {
            revert PrimaryMarketInvalidAmount();
        }

        // Check asset is configured with a price
        uint256 price = _assetPrices[assetId];
        if (price == 0) {
            revert PrimaryMarketAssetNotConfigured();
        }

        // Calculate total price
        uint256 totalPrice = price * amount;

        // Transfer Digital Euro from buyer to fund treasury
        // Will automatically revert if insufficient balance or allowance
        bool success = digitalEuro.transferFrom(
            msg.sender,
            fundTreasury,
            totalPrice
        );
        if (!success) {
            revert PrimaryMarketTransferFailed();
        }

        // Transfer assets from contract to buyer
        // Will automatically revert if insufficient tokens available
        financialAssets.safeTransferFrom(
            address(this),
            msg.sender,
            assetId,
            amount,
            ""
        );

        emit AssetPurchased(msg.sender, assetId, amount, totalPrice);
    }

    /**
     * @dev Updates the fund treasury address
     * Can only be called by admin
     * @param newTreasury New treasury address
     */
    function updateFundTreasury(
        address newTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) {
            revert PrimaryMarketInvalidAddress();
        }

        address oldTreasury = fundTreasury;
        fundTreasury = newTreasury;

        emit FundTreasuryUpdated(oldTreasury, newTreasury);
    }

    /**
     * @dev Pauses all asset purchases
     * Can only be called by fund manager
     */
    function pause() external onlyRole(FUND_MANAGER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses asset purchases
     * Can only be called by fund manager
     */
    function unpause() external onlyRole(FUND_MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @dev Gets the price of an asset
     * @param assetId ID of the asset
     * @return Price in Digital Euro (in wei units, 6 decimals)
     */
    function getAssetPrice(uint256 assetId) external view returns (uint256) {
        return _assetPrices[assetId];
    }

    /**
     * @dev Gets the available supply of an asset for sale
     * @param assetId ID of the asset
     * @return Available amount
     */
    function getAvailableSupply(
        uint256 assetId
    ) external view returns (uint256) {
        return financialAssets.balanceOf(address(this), assetId);
    }

    /**
     * @dev Override required by Solidity for ERC1155Holder
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
