// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {NFTMarketD1} from "./D1_NftMarket.sol";

event PermitList(address signer, uint256 tokenId, uint256 price);

event NFTMarketD2Initialized(address indexed paymentToken, address indexed nftContract, string name, string version);

contract NFTMarketD2 is NFTMarketD1 {
    // EIP-712 type hash for the PermitList struct
    bytes32 public constant PERMIT_LIST_TYPEHASH = keccak256("PermitList(address signer,uint256 tokenId,uint256 price)");

    // EIP-712 domain type hash
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // State variables for EIP712 domain (for proxy initialization)
    string private _domainName;
    string private _domainVersion;
    bool private _initialized;

    constructor() NFTMarketD1(address(0), address(0)) {
        // Constructor is not used in proxy pattern, but required by inheritance
    }

    function initialize(address _paymentToken, address _nftContract, string memory _name, string memory _version)
        public
    {
        require(!_initialized, "Already initialized");
        require(msg.sender == address(this), "Only callable by proxy");

        // Initialize parent contracts
        super.initialize(_paymentToken, _nftContract);

        // Set EIP712 domain parameters
        _domainName = _name;
        _domainVersion = _version;
        _initialized = true;

        emit NFTMarketD2Initialized(_paymentToken, _nftContract, _name, _version);
    }

    /**
     * @dev Builds the EIP-712 domain separator
     */
    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_domainName)),
                keccak256(bytes(_domainVersion)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Creates the EIP-712 digest for signature verification
     */
    function _hashTypedDataV4(bytes32 structHash) private view returns (bytes32) {
        bytes32 domainSeparator = _buildDomainSeparator();
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function permitList(address signer, uint256 tokenId, uint256 price, uint8 v, bytes32 r, bytes32 s) external {
        require(_initialized, "Contract not initialized");

        // Create the struct hash according to EIP-712
        bytes32 structHash = keccak256(abi.encode(PERMIT_LIST_TYPEHASH, signer, tokenId, price));

        // Create the digest
        bytes32 hash = _hashTypedDataV4(structHash);

        // Recover the signer
        address recoveredSigner = ecrecover(hash, v, r, s);
        require(signer == recoveredSigner, "Invalid signature");

        // Call the original list function
        super.list(tokenId, price);

        // Emit the permit list event
        emit PermitList(signer, tokenId, price);
    }

    /**
     * @dev Returns the EIP-712 domain separator for external verification
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _buildDomainSeparator();
    }

    /**
     * @dev Returns the domain name and version for external signature generation
     */
    function getDomainInfo() external view returns (string memory name, string memory version) {
        return (_domainName, _domainVersion);
    }
}
