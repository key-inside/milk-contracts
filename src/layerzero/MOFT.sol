// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract MOFT is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {OFTCore-sharedDecimals}.
     */
    function sharedDecimals() public pure override returns (uint8) {
        return 8;
    }
}