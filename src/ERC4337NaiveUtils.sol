// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {NaiveUserOperation} from "./IERC4337Naive.sol";

library ERC4337NaiveUtils {
    bytes32 internal constant NAIVE_USEROP_TYPEHASH =
        keccak256("NaiveUserOperation(address sender,uint256 nonce,bytes callData,bytes paymasterAndData)");

    /**
     * @dev Hashing function that includes information about NaiveUserOperation.
     * @param userOp NaiveUserOperation
     */
    function hash(NaiveUserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                NAIVE_USEROP_TYPEHASH,
                userOp.sender,
                userOp.nonce,
                keccak256(userOp.callData),
                keccak256(userOp.paymasterAndData)
            )
        );
    }

    /**
     * @dev Decodes NaiveUserOperation's callData.
     */
    function decodeCallData(NaiveUserOperation calldata userOp) internal pure returns (address target, bytes calldata data) {
        target = userOp.callData.length < 20 ? address(0) : address(bytes20(userOp.callData[:20]));
        data = userOp.callData.length < 21 ? userOp.callData[:0] : userOp.callData[20:];
    }
}