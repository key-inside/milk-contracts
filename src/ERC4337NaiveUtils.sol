// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {NaiveUserOperation} from "./IERC4337Naive.sol";

library ERC4337NaiveUtils {
    /**
     * @dev Hashing function that includes information about NaiveUserOperation, chain ID, and entry point.
     * @param userOp NaiveUserOperation
     * @param entrypoint EntryPoint's address to hash with.
     */
    function hash(NaiveUserOperation calldata userOp, address entrypoint) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        userOp.sender,
                        userOp.nonce,
                        keccak256(userOp.callData),
                        keccak256(userOp.paymasterAndData)
                    )
                ),
                entrypoint,
                block.chainid
            )
        );
    }

    function emptyBytes() internal pure returns (bytes calldata result) {
        assembly ("memory-safe") {
            result.offset := 0
            result.length := 0
        }
    }

    /**
     * @dev Decodes NaiveUserOperation's callData.
     */
    function decodeCallData(NaiveUserOperation calldata userOp) internal pure returns (address target, uint256 value, bytes calldata data) {
        target = userOp.callData.length < 20 ? address(0) : address(bytes20(userOp.callData[0:20]));
        value = userOp.callData.length < 52 ? 0 : uint256(bytes32(userOp.callData[20:52]));
        data = userOp.callData.length < 53 ? emptyBytes() : userOp.callData[52:];
    }
}