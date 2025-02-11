// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

struct NaiveUserOperation {
    address sender;
    uint256 nonce;
    bytes callData;
    bytes paymasterAndData;
    bytes signature;
}

/**
 * @dev Base interface for an ERC-4337 account.
 */
interface IAccount {
    function validateUserOp(NaiveUserOperation calldata userOp) external;

    function executeUserOp(NaiveUserOperation calldata userOp) external;
}