// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Account} from "./Account.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/**
 * @dev Deploys un-upgradeable Account contracts with salts and initial arguments.
 */
contract AccountFactory {
    function createAccount(bytes32 salt, address[] calldata owners, uint256 threshold) external returns (address) {
        address addr = getAddress(salt, owners, threshold);
        if (addr.code.length > 0) return addr;
        // deploys new account
        return Create2.deploy(0, salt,
            abi.encodePacked(type(Account).creationCode, abi.encode(owners, threshold))
        );
    }

    function getAddress(bytes32 salt, address[] calldata owners, uint256 threshold) public view returns (address) {
        return Create2.computeAddress(salt,
            keccak256(abi.encodePacked(type(Account).creationCode, abi.encode(owners, threshold)))
        );
    }
}