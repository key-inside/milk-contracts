// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC4337NaiveUtils} from "./ERC4337NaiveUtils.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MultiSigManager} from "./MultiSigManager.sol";
import {NaiveUserOperation} from "./IERC4337Naive.sol";

contract Account is MultiSigManager {
    using Address for address;
    using MessageHashUtils for bytes32;
    using ERC4337NaiveUtils for NaiveUserOperation;

    /**
     * @dev Store used nonces for security reasons (i.e. to prevent replay attack).
     */  
    mapping(uint256 => bool) private _nonces;

    error DuplicatedNonce(uint256 nonce);

    /**
     * @dev See {ERC4337NaiveUtils} and {ECDSA-recover}.
     */   
    error InvalidUserOpHash();

    /**
     * @dev Calls to state altering methods such as `addOwner` must go through `executeUserOp`.
     */
    error Unauthorized();

    modifier authorized() {
        require(msg.sender == address(this), Unauthorized());
        _;
    }

    constructor(address[] memory owners, uint256 threshold) {
        _initOwners(owners, threshold);
    }

    function validateUserOp(NaiveUserOperation calldata userOp, bytes32 userOpHash) external view {
        _validateUserOp(userOp, userOpHash);
    }

    function executeUserOp(NaiveUserOperation calldata userOp, bytes32 userOpHash) external {
        _validateUserOp(userOp, userOpHash);
        _nonces[userOp.nonce] = true;

        // executes a call
        (address target, uint256 value, bytes memory data) = userOp.decodeCallData();
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        Address.verifyCallResult(success, returnData);
    }

    function _validateUserOp(NaiveUserOperation calldata userOp, bytes32 userOpHash) private view {
        require(!_nonces[userOp.nonce], DuplicatedNonce(userOp.nonce));
        // validates userOp and userOpHash
        require(userOp.hash(msg.sender) == userOpHash, InvalidUserOpHash());
        _validateSignature(userOpHash.toEthSignedMessageHash(), userOp.signature);
    }

    function addOwner(address owner, uint256 threshold) external authorized {
        _addOwner(owner, threshold);
    }

    function removeOwner(address owner, uint256 threshold) external authorized {
        _removeOwner(owner, threshold);
    }

    function swapOwner(address old_, address new_) external authorized {
        _swapOwner(old_, new_);
    }

    function changeThreshold(uint256 threshold) external authorized {
        _changeThreshold(threshold);
    }
}