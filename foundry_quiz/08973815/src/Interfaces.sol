// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @dev 扩展的代币接收者接口，支持额外数据参数
 */
interface ITokenReceiverWithData {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}

/*
* @dev 简化的 ERC721 接口
*/
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
}

/**
 * @dev Interface for contracts that want to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

/*
* @dev 简化的 ERC20 接口
*/
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

