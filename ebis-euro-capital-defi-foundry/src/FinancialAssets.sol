// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title FinancialAssets
 * @dev ERC-1155 token representing multiple types of financial fund shares
 * Only accounts with FUND_MANAGER_ROLE can mint new asset tokens
 */
contract FinancialAssets is ERC1155, AccessControl, ERC1155Supply {
    // Role for the investment fund manager
    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");

    // Address of the PrimaryMarket contract where all minted assets are sent
    address public primaryMarket;

    // Mapping from asset ID to its name
    mapping(uint256 => string) private _assetNames;

    // Mapping from asset ID to its symbol
    mapping(uint256 => string) private _assetSymbols;

    // Counter of created asset types
    uint256 private _assetTypeCount;

    // Events
    event AssetTypeCreated(uint256 indexed assetId, string name, string symbol);
    event PrimaryMarketSet(
        address indexed previousMarket,
        address indexed newMarket
    );
    event AssetsMinted(
        uint256 indexed assetId,
        address indexed to,
        uint256 amount
    );
    event AssetsBurned(
        uint256 indexed assetId,
        address indexed from,
        uint256 amount
    );

    // Custom errors
    error FinancialAssetsInvalidAmount();
    error FinancialAssetsInvalidAssetId();
    error FinancialAssetsAssetAlreadyExists();
    error FinancialAssetsInvalidPrimaryMarket();
    error FinancialAssetsPrimaryMarketNotSet();
    error FinancialAssetsInvalidName();

    /**
     * @dev Constructor that initializes the contract
     * @param uri Base URI for token metadata (can be an IPFS URL)
     */
    constructor(string memory uri) ERC1155(uri) {
        // Grant roles to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FUND_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Creates a new type of financial asset
     * Can only be called by accounts with FUND_MANAGER_ROLE
     * @param assetId Unique ID for this asset type
     * @param name Name of the asset (e.g., "Technology Fund")
     * @param symbol Symbol of the asset (e.g., "TECH")
     */
    function createAssetType(
        uint256 assetId,
        string memory name,
        string memory symbol
    ) external onlyRole(FUND_MANAGER_ROLE) {
        // Verify that the name is not empty
        if (bytes(name).length == 0) {
            revert FinancialAssetsInvalidName();
        }

        // Verify that the ID is not already in use
        if (bytes(_assetNames[assetId]).length != 0) {
            revert FinancialAssetsAssetAlreadyExists();
        }

        _assetNames[assetId] = name;
        _assetSymbols[assetId] = symbol;
        _assetTypeCount++;

        emit AssetTypeCreated(assetId, name, symbol);
    }

    /**
     * @dev Sets the PrimaryMarket contract address
     * Can only be called by accounts with DEFAULT_ADMIN_ROLE
     * @param _primaryMarket Address of the PrimaryMarket contract
     */
    function setPrimaryMarket(
        address _primaryMarket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_primaryMarket == address(0)) {
            revert FinancialAssetsInvalidPrimaryMarket();
        }

        address previousMarket = primaryMarket;
        primaryMarket = _primaryMarket;

        emit PrimaryMarketSet(previousMarket, _primaryMarket);
    }

    /**
     * @dev Mints (issues) new tokens of a specific asset
     * All minted tokens are sent to the PrimaryMarket contract
     * Can only be called by accounts with FUND_MANAGER_ROLE
     * @param assetId ID of the asset type
     * @param amount Amount of tokens to mint
     */
    function mint(
        uint256 assetId,
        uint256 amount
    ) external onlyRole(FUND_MANAGER_ROLE) {
        if (primaryMarket == address(0)) {
            revert FinancialAssetsPrimaryMarketNotSet();
        }
        if (amount == 0) {
            revert FinancialAssetsInvalidAmount();
        }
        // Verify that the asset type exists
        if (bytes(_assetNames[assetId]).length == 0) {
            revert FinancialAssetsInvalidAssetId();
        }

        _mint(primaryMarket, assetId, amount, "");
        emit AssetsMinted(assetId, primaryMarket, amount);
    }

    /**
     * @dev Mints multiple asset types to the PrimaryMarket
     * All minted tokens are sent to the PrimaryMarket contract
     * Can only be called by accounts with FUND_MANAGER_ROLE
     * @param assetIds Array of asset IDs
     * @param amounts Array of corresponding amounts
     */
    function mintBatch(
        uint256[] memory assetIds,
        uint256[] memory amounts
    ) external onlyRole(FUND_MANAGER_ROLE) {
        if (primaryMarket == address(0)) {
            revert FinancialAssetsPrimaryMarketNotSet();
        }

        // Verify arrays have the same length
        if (assetIds.length != amounts.length) {
            revert FinancialAssetsInvalidAmount();
        }

        // Verify that all assets exist and amounts are valid
        for (uint256 i = 0; i < assetIds.length; i++) {
            if (bytes(_assetNames[assetIds[i]]).length == 0) {
                revert FinancialAssetsInvalidAssetId();
            }
            if (amounts[i] == 0) {
                revert FinancialAssetsInvalidAmount();
            }
        }

        _mintBatch(primaryMarket, assetIds, amounts, "");

        // Emit event for each minted asset
        for (uint256 i = 0; i < assetIds.length; i++) {
            emit AssetsMinted(assetIds[i], primaryMarket, amounts[i]);
        }
    }

    /**
     * @dev Gets the name of an asset type
     * @param assetId ID of the asset
     * @return Name of the asset
     */
    function getAssetName(
        uint256 assetId
    ) external view returns (string memory) {
        return _assetNames[assetId];
    }

    /**
     * @dev Gets the symbol of an asset type
     * @param assetId ID of the asset
     * @return Symbol of the asset
     */
    function getAssetSymbol(
        uint256 assetId
    ) external view returns (string memory) {
        return _assetSymbols[assetId];
    }

    /**
     * @dev Gets the total number of asset types created
     * @return Number of asset types
     */
    function getAssetTypeCount() external view returns (uint256) {
        return _assetTypeCount;
    }

    /**
     * @dev Verifies if an asset type exists
     * @param assetId ID of the asset to verify
     * @return true if the asset exists, false otherwise
     */
    function assetExists(uint256 assetId) external view returns (bool) {
        return bytes(_assetNames[assetId]).length != 0;
    }

    /**
     * @dev Override required by Solidity to support multiple inheritance
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that executes before any token transfer
     * Override necessary for using ERC1155Supply
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
