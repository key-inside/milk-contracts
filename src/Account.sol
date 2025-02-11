// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC4337NaiveUtils} from "./ERC4337NaiveUtils.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MultiSigManager} from "./MultiSigManager.sol";
import {NaiveUserOperation, IAccount} from "./IERC4337Naive.sol";

/**
 * Non-payable account specifically designed for MiL.k's ERC20 token.
 * Signature validation ensures request comes from the intended entrypoint or delegator.
 */
contract Account is EIP712, IAccount, MultiSigManager {
    using Address for address;
    using MessageHashUtils for bytes32;
    using ERC4337NaiveUtils for NaiveUserOperation;

    bytes32 private constant EXECUTE_USEROP_WITH_ENTRYPOINT_TYPEHASH =
        keccak256("executeUserOp(NaiveUserOperation userOp,address entrypoint)");

    /**
     * @dev Store used nonces for security reasons (i.e. to prevent replay attack).
     */  
    mapping(uint256 => bool) private _nonces;

    /**
     * @dev Used `nonce`.
     */ 
    error DuplicatedNonce(uint256 nonce);

    /**
     * @dev `sender` is not this account.
     */ 
    error InvalidOpSender(address sender);

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

    constructor(address[] memory owners, uint256 threshold)
        EIP712("MiL.k", "1")
        MultiSigManager(owners, threshold)
    {}

    function validateUserOp(NaiveUserOperation calldata userOp) external view {
        _validateUserOp(userOp);
    }

    function executeUserOp(NaiveUserOperation calldata userOp) external {
        require(userOp.sender == address(this), InvalidOpSender(userOp.sender));
        _validateUserOp(userOp);
        _nonces[userOp.nonce] = true;

        // executes a call
        (address target, bytes calldata data) = userOp.decodeCallData();
        (bool success, bytes memory returnData) = target.call(data);
        target.verifyCallResultFromTarget(success, returnData);
    }

    function _typedData(NaiveUserOperation calldata userOp) private view returns (bytes32) {
        // calculates a hash with the entrypoint
        bytes32 structHash = keccak256(
            abi.encode(
                EXECUTE_USEROP_WITH_ENTRYPOINT_TYPEHASH,
                userOp.hash(),
                msg.sender  // entrypoint or delegator
            )
        );
        return _hashTypedDataV4(structHash);
    }

    function _validateUserOp(NaiveUserOperation calldata userOp) private view {
        require(!_nonces[userOp.nonce], DuplicatedNonce(userOp.nonce));
        // validates userOp and userOpHash
        _validateSignature(_typedData(userOp).toEthSignedMessageHash(), userOp.signature);
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