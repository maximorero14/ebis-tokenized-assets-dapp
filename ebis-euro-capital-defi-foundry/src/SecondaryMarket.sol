// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SecondaryMarket
 * @dev Peer-to-peer marketplace for trading tokenized financial assets
 * Implements Delivery vs Payment (DvP) for atomic settlement
 */
contract SecondaryMarket is
    AccessControl,
    Pausable,
    ReentrancyGuard,
    ERC1155Holder
{
    // Struct representing a listing
    struct Listing {
        address seller;
        uint256 assetId;
        uint256 amount;
        uint256 pricePerUnit;
        bool active;
    }

    // Reference to the Digital Euro token (payment method)
    IERC20 public immutable digitalEuro;

    // Reference to the Financial Assets contract
    IERC1155 public immutable financialAssets;

    // Mapping from listing ID to Listing struct
    mapping(uint256 => Listing) private _listings;

    // Counter for generating unique listing IDs
    uint256 private _listingIdCounter;

    // Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed assetId,
        uint256 amount,
        uint256 pricePerUnit
    );

    event TradeExecuted(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 assetId,
        uint256 amount,
        uint256 totalPrice
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller,
        uint256 assetId,
        uint256 amount
    );

    event ListingUpdated(uint256 indexed listingId, uint256 newAmount);

    // Custom errors
    error SecondaryMarketInvalidAddress();
    error SecondaryMarketInvalidAmount();
    error SecondaryMarketInvalidPrice();
    error SecondaryMarketInvalidListing();
    error SecondaryMarketListingNotActive();
    error SecondaryMarketUnauthorized();
    error SecondaryMarketInsufficientAssets();
    error SecondaryMarketInsufficientBalance();
    error SecondaryMarketInsufficientAllowance();
    error SecondaryMarketTransferFailed();

    /**
     * @dev Constructor
     * @param _digitalEuro Address of the Digital Euro token contract
     * @param _financialAssets Address of the Financial Assets contract
     */
    constructor(address _digitalEuro, address _financialAssets) {
        if (_digitalEuro == address(0) || _financialAssets == address(0)) {
            revert SecondaryMarketInvalidAddress();
        }

        digitalEuro = IERC20(_digitalEuro);
        financialAssets = IERC1155(_financialAssets);

        // Grant admin role to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Creates a new listing
     * Seller must approve this contract to transfer their assets
     * Assets are transferred to this contract (escrow)
     * @param assetId ID of the asset to sell
     * @param amount Amount of assets to sell
     * @param pricePerUnit Price per unit in Digital Euro (6 decimals)
     * @return listingId Unique ID of the created listing
     */
    function createListing(
        uint256 assetId,
        uint256 amount,
        uint256 pricePerUnit
    ) external whenNotPaused nonReentrant returns (uint256 listingId) {
        if (amount == 0) {
            revert SecondaryMarketInvalidAmount();
        }
        if (pricePerUnit == 0) {
            revert SecondaryMarketInvalidPrice();
        }

        listingId = _listingIdCounter++;

        _listings[listingId] = Listing({
            seller: msg.sender,
            assetId: assetId,
            amount: amount,
            pricePerUnit: pricePerUnit,
            active: true
        });

        // Transfer assets from seller to this contract (escrow)
        financialAssets.safeTransferFrom(
            msg.sender,
            address(this),
            assetId,
            amount,
            ""
        );

        emit ListingCreated(
            listingId,
            msg.sender,
            assetId,
            amount,
            pricePerUnit
        );

        return listingId;
    }

    /**
     * @dev Executes a trade (Delivery vs Payment)
     * Buyer pays with Digital Euro, receives assets
     * Seller receives Digital Euro, assets transferred from escrow
     * Settlement is atomic - either both happen or neither
     * @param listingId ID of the listing to buy from
     * @param amount Amount of assets to buy
     */
    function executeTrade(
        uint256 listingId,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        if (amount == 0) {
            revert SecondaryMarketInvalidAmount();
        }

        Listing storage listing = _listings[listingId];

        // Validate listing exists and is active
        if (listing.seller == address(0)) {
            revert SecondaryMarketInvalidListing();
        }
        if (!listing.active) {
            revert SecondaryMarketListingNotActive();
        }

        // Check sufficient assets in listing
        if (listing.amount < amount) {
            revert SecondaryMarketInsufficientAssets();
        }

        // Calculate total price
        uint256 totalPrice = listing.pricePerUnit * amount;

        // Check buyer has enough Digital Euro
        uint256 buyerBalance = digitalEuro.balanceOf(msg.sender);
        if (buyerBalance < totalPrice) {
            revert SecondaryMarketInsufficientBalance();
        }

        // Check buyer has approved this contract to spend enough Digital Euro
        uint256 allowance = digitalEuro.allowance(msg.sender, address(this));
        if (allowance < totalPrice) {
            revert SecondaryMarketInsufficientAllowance();
        }

        // Update listing amount
        listing.amount -= amount;

        // If listing is fully filled, mark as inactive
        if (listing.amount == 0) {
            listing.active = false;
        }

        // ATOMIC SETTLEMENT - Delivery vs Payment (DvP)
        // Step 1: Payment - Transfer Digital Euro from buyer to seller
        bool paymentSuccess = digitalEuro.transferFrom(
            msg.sender,
            listing.seller,
            totalPrice
        );
        if (!paymentSuccess) {
            revert SecondaryMarketTransferFailed();
        }

        // Step 2: Delivery - Transfer assets from contract to buyer
        financialAssets.safeTransferFrom(
            address(this),
            msg.sender,
            listing.assetId,
            amount,
            ""
        );

        emit TradeExecuted(
            listingId,
            msg.sender,
            listing.seller,
            listing.assetId,
            amount,
            totalPrice
        );

        // Emit update event if listing still has remaining amount
        if (listing.amount > 0) {
            emit ListingUpdated(listingId, listing.amount);
        }
    }

    /**
     * @dev Cancels a listing and returns assets to seller
     * Can only be called by the seller who created the listing
     * @param listingId ID of the listing to cancel
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = _listings[listingId];

        // Validate listing exists
        if (listing.seller == address(0)) {
            revert SecondaryMarketInvalidListing();
        }

        // Validate caller is the seller
        if (listing.seller != msg.sender) {
            revert SecondaryMarketUnauthorized();
        }

        // Validate listing is active
        if (!listing.active) {
            revert SecondaryMarketListingNotActive();
        }

        uint256 assetId = listing.assetId;
        uint256 amount = listing.amount;

        // Mark listing as inactive
        listing.active = false;
        listing.amount = 0;

        // Return assets to seller
        financialAssets.safeTransferFrom(
            address(this),
            msg.sender,
            assetId,
            amount,
            ""
        );

        emit ListingCancelled(listingId, msg.sender, assetId, amount);
    }

    /**
     * @dev Pauses all marketplace activities
     * Can only be called by admin
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses marketplace activities
     * Can only be called by admin
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Gets listing details
     * @param listingId ID of the listing
     * @return Listing struct
     */
    function getListing(
        uint256 listingId
    ) external view returns (Listing memory) {
        return _listings[listingId];
    }

    /**
     * @dev Gets active listing details
     * @param listingId ID of the listing
     * @return Listing struct if active, reverts otherwise
     */
    function getActiveListing(
        uint256 listingId
    ) external view returns (Listing memory) {
        Listing memory listing = _listings[listingId];
        if (!listing.active) {
            revert SecondaryMarketListingNotActive();
        }
        return listing;
    }

    /**
     * @dev Checks if a listing is active
     * @param listingId ID of the listing
     * @return true if active, false otherwise
     */
    function isListingActive(uint256 listingId) external view returns (bool) {
        return _listings[listingId].active;
    }

    /**
     * @dev Gets the current listing ID counter
     * @return Current counter value
     */
    function getListingCount() external view returns (uint256) {
        return _listingIdCounter;
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
