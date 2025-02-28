// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {NaiveUserOperation, IAccount} from "./IERC4337Naive.sol";

contract EntryPoint is ReentrancyGuardTransient {
    using Address for address;
   
    /**
     * @dev A user operation at `opIndex` failed with error `reason`.
     */
    event OpFailed(uint256 opIndex, bytes reason);

    /**
     * @dev A user operation at `opIndex` consumed `gasUsed` at `gasPrice`.
     */
    event OpGasUsed(uint256 opIndex, uint256 gasUsed, uint256 gasPrice);

    /**
     * @dev `sender` is this contract. User operation's sender must not be this entry point.
     */ 
    error InvalidOpSender(address sender);

    /**
     * @dev Internal call only.
     */    
    error Unauthorized();

    modifier authorized() {
        require(msg.sender == address(this), Unauthorized());
        _;
    }

    function handleOps(NaiveUserOperation[] calldata ops) external nonReentrant {
        for (uint256 i = 0; i < ops.length; ++i) {
            uint256 preGas = gasleft();

            try
                this.executeUserOp(ops[i]) {
            }  catch Error(string memory reason) {
                emit OpFailed(i, abi.encode(reason));
            } catch (bytes memory reason) {
                emit OpFailed(i, reason);
            }

            unchecked {
                uint256 usedGas = preGas - gasleft();
                emit OpGasUsed(i, usedGas, block.basefee);
            }
        }
    }

    function executeUserOp(NaiveUserOperation calldata op) external authorized {
        require(op.sender != address(this), InvalidOpSender(op.sender));
        require(op.sender.code.length > 0, Address.AddressEmptyCode(op.sender));

        // using {Address-functionCall} to revert if op.sender is invalid
        // op.sender is not a contract -> reverts with error `{Address-AddressEmptyCode}`
        // op.sender does not implement IAccount -> reverts with error `{Errors-FailedCall}`
        bytes memory data = abi.encodeCall(IAccount.executeUserOp, (op));
        address(op.sender).functionCall(data);
    }
}