// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract MultiSigManager {
    event AddedOwner(address indexed account, address indexed owner);
    event RemovedOwner(address indexed account, address indexed owner);
    event ChangedThreshold(address indexed account, uint256 threshold);

    address private constant PIVOT = address(0x1);

    mapping(address => address) private _owners;
    uint256 private _ownerCount;
    uint256 private _threshold;

    /**
     * @dev `owner` is already an owner.
     * @param owner Address to be added to the owners.
     */
    error DuplicatedOwner(address owner);

    /**
     * @dev `owner` does not satisfy requirement (i.e. address(0), address(this)).
     */
    error InvalidOwner(address owner);

    /**
     * @dev `signer` is not an owner.
     */
    error InvalidSignature(address signer);

    /**
     * Signatures are not concatenated in ascending order by address.
     * @param signer The first signer that does not satisfy ascending order.
     */
    error InvalidSignatureOrder(address signer);

    /**
     * @dev `threshold` is either zero or more than owners count.
     */
    error InvalidThreshold(uint256 threshold);

    /**
     * @dev Signature count is less than threshold.
     */
    error NotEnoughSignatures(uint256 threshold, uint256 sigCount);

    /**
     * @dev Account can not have zero owner.
     */
    error RequiresAtLeastOneOwner();

    function isOwner(address account) public view returns (bool) {
        return account != PIVOT && _owners[account] != address(0);
    }

    function owners() public view returns (address[] memory) {
        address[] memory owners_ = new address[](_ownerCount);
        address marker = PIVOT;
        for (uint256 i = 0; i < _ownerCount; ++i) {
            owners_[i] = _owners[marker];
            marker = owners_[i];
        }
        return owners_;
    }

    function threshold() public view returns (uint256) {
        return _threshold;
    }

    function _initOwners(address[] memory owners_, uint256 threshold_) internal {
        require(owners_.length > 0, RequiresAtLeastOneOwner());
        require(threshold_ > 0 && threshold_ <= owners_.length, InvalidThreshold(threshold_));

        address marker = PIVOT;
        for (uint256 i = 0; i < owners_.length; ++i) {
            address owner = owners_[i];
            _validateNewOwner(owner);
            _owners[marker] = owner;
            marker = owner;
            emit AddedOwner(address(this), owner);
        }
        _owners[marker] = PIVOT;
        _ownerCount = owners_.length;
        _changeThreshold(threshold_);
    }

    function _validateNewOwner(address owner) private view {
        require(owner != address(0) && owner != PIVOT && owner != address(this), InvalidOwner(owner));
        require(_owners[owner] == address(0), DuplicatedOwner(owner));
    }

    function _addOwner(address owner, uint256 threshold_) internal {
        _validateNewOwner(owner);
        _owners[owner] = _owners[PIVOT];
        _owners[PIVOT] = owner;
        ++_ownerCount;
        emit AddedOwner(address(this), owner);
        _changeThreshold(threshold_);
    }

    function _removeOwner(address owner, uint256 threshold_) internal {
        require(_ownerCount > 1, RequiresAtLeastOneOwner());
        require(owner != PIVOT && _owners[owner] != address(0), InvalidOwner(owner));
        address prev = _prevOwnerOf(owner);
        _owners[prev] = _owners[owner];
        _owners[owner] = address(0);
        --_ownerCount;
        emit RemovedOwner(address(this), owner);
        _changeThreshold(threshold_);
    }

    function _swapOwner(address old_, address new_) internal {
        require(old_ != PIVOT && _owners[old_] != address(0), InvalidOwner(old_));
        _validateNewOwner(new_);
        address prev = _prevOwnerOf(old_);
        _owners[new_] = _owners[old_];
        _owners[prev] = new_;
        _owners[old_] = address(0);
        emit RemovedOwner(address(this), old_);
        emit AddedOwner(address(this), new_);
    }

    function _changeThreshold(uint256 threshold_) internal {
        require(threshold_ > 0 && threshold_ <= _ownerCount, InvalidThreshold(threshold_)); 
        if (threshold_ != _threshold) {
            _threshold = threshold_;
            emit ChangedThreshold(address(this), threshold_);
        }
    }

    function _prevOwnerOf(address owner) private view returns (address) {
        address prev = PIVOT;
        for (uint256 i = 0; i < _ownerCount; ++i) {
            if (_owners[prev] == owner) return prev;
            prev = _owners[prev];
        }
        return PIVOT;
    }

    /**
     * @dev Validates that `signature` is valid for the hashed message (`hash`).
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: See {ECDSA-recover}.
     *
     * IMPORTANT: `signature` must be concatenated in ascending order by signer's address.
     *
     * MUST revert if not valid
     */
    function _validateSignature(bytes32 hash, bytes calldata signature) internal view {
        uint256 count = signature.length / 65;
        require(count >= _threshold, NotEnoughSignatures(_threshold, count));

        count = 0;  // reuse to count valid signatures
        address prev = address(0);
        for (uint256 i = 0; (i < signature.length && count < _threshold); i += 65) {
            address signer = ECDSA.recover(hash, signature[i:(i + 65)]);
            require(isOwner(signer), InvalidSignature(signer));
            require(signer > prev, InvalidSignatureOrder(signer));
            prev = signer;
            ++count;
        }
    }
}