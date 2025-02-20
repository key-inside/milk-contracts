// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev {TimeLockWallet} is an ownable wallet that can receive ERC20 tokens
 * and release them to the wallet owner according to a schedule.
 *
 * NOTE: Since the wallet is {Ownable}, ownership can be transferred.
 */
contract TimeLockWallet is Ownable {
    using SafeERC20 for IERC20;

    event Deposited(uint256 indexed timestamp, uint256 amount);
    event Released(uint256 indexed timestamp, uint256 amount);

    address private immutable _token;
    mapping(uint256 timestamp => uint256 amount) private _releasable;
    uint256 private _unreleased;    // total unreleased amount

    /**
     * @dev Deposit with zero amount.
     */
    error ZeroAmount();

    /**
     * @dev `timestamp` is not later than `block.timestamp`.
     */
    error Expired(uint256 timestamp);

    /**
     * @dev `timestamp` is later than `block.timestamp`.
     */
    error NotReady(uint256 timestamp);

    /**
     * @dev Scheduled release at `timestamp` doesn't exist.
     */
    error NotScheduled(uint256 timestamp);

    /**
     * @dev Scheduled release at `timestamp` exists.
     */
    error AlreadyScheduled(uint256 timestamp);

    /**
     * @dev Sets the ERC20 contract address and the beneficiary (owner) of the wallet.
     */
    constructor(address token_, address beneficiary) Ownable(beneficiary) {
        _token = token_;
    }

    /**
     * @dev Returns the address of the ERC20 contract.
     */
    function token() public view returns (address) {
        return _token;
    }

    /**
     * @dev Returns releasable amount after `timestamp`.
     */
    function releasable(uint256 timestamp) public view returns (uint256) {
        return _releasable[timestamp];
    }

    /**
     * @dev Returns total unreleased amount.
     */
    function unreleased() public view returns (uint256) {
        return _unreleased;
    }

    /**
     * @dev Spends token allowance and deposits into this wallet.
     * Before `deposit` is called, `msg.sender` must call {ERC20-approve} with sufficient amount.
     *
     * Emits a {Deposited} event.
     */
    function deposit(uint256 amount, uint256 timestamp) external {
        depositFrom(msg.sender, amount, timestamp);
    }

    /**
     * @dev Spends token allowance and deposits into this wallet.
     * Before `depositFrom` is called, `from` must call {ERC20-approve} with sufficient amount.
     *
     * Emits a {Deposited} event.
     */
    function depositFrom(address from, uint256 amount, uint256 timestamp) public {
        require(amount > 0, ZeroAmount());
        require(timestamp > block.timestamp, Expired(timestamp));
        require(_releasable[timestamp] == 0, AlreadyScheduled(timestamp));

        _releasable[timestamp] = amount;
        IERC20(_token).safeTransferFrom(from, address(this), amount);
        unchecked {
            _unreleased += amount;
        }
        emit Deposited(timestamp, amount);
    }

    /**
     * @dev Sends the tokens scheduled to be released after `timestamp` to the wallet owner.
     *
     * Emits a {Released} event.
     */
    function release(uint256 timestamp) external {
        require(timestamp <= block.timestamp, NotReady(timestamp));
        require(_releasable[timestamp] > 0, NotScheduled(timestamp));

        uint256 amount = _releasable[timestamp];
        _releasable[timestamp] = 0;
        unchecked {
            _unreleased -= amount;
        }
        IERC20(_token).safeTransfer(owner(), amount);
        emit Released(timestamp, amount);
    }
}