// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BaseERC721 } from "./BaseERC721.sol";
import { IERC721Receiver } from "./Interfaces.sol";

contract ExtendedERC721 is BaseERC721, IERC721Receiver {

    constructor() BaseERC721("ExtendedNFT", "ENFT", "ipfs://bafybeidf36u4iba7c5cnqttyd2kz5mwsuqadmoevijlnshfr2fbwo4wsla/") {}

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
