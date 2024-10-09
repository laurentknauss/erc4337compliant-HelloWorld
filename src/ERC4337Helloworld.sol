// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol"; 
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";  
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol"; 
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol"; 
import { INonceManager } from "lib/account-abstraction/contracts/interfaces/INonceManager.sol"; 



contract ERC4337HelloWorld  is IAccount, Ownable{ 

/*//////////////////////////////////////////////////////////////
                                 ERRORS
//////////////////////////////////////////////////////////////*/
/// @notice Error when the caller is not the EntryPoint contract.
error HelloWorldAccount__NotFromEntryPoint(); 
/// @notice Error when the caller is not the EntryPoint contract or the owner of the contract.
error HelloWorldAccout__NotFromEntryPointOrOwner(); 
/// @notice Error when the call to the destination address fails.
error HelloWorldAccount__CallFailed(bytes result); 


/*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
//////////////////////////////////////////////////////////////*/
/// @notice The EntryPoint contract address.
IEntryPoint private immutable i_entryPoint; 
/// @notice The greeting message.
string public greet = "Hello World"; 





/*//////////////////////////////////////////////////////////////
                               MODIFIERS
//////////////////////////////////////////////////////////////*/
/// @notice Require that the caller is the EntryPoint contract.
modifier requireFromEntryPoint(){ 
    if(msg.sender != address(i_entryPoint)){ 
        revert HelloWorldAccount__NotFromEntryPoint(); 
    }
    _; 
}
/// @notice Require that the caller is the EntryPoint contract or the owner of the contract. 
modifier requireFromEntryPointOrOwner(){ 
    if(msg.sender != address(i_entryPoint) && msg.sender != owner()){ 
        revert HelloWorldAccout__NotFromEntryPointOrOwner(); 
    }
    _; 
}

    constructor (address entryPoint) Ownable(msg.sender) {  
        i_entryPoint = IEntryPoint(entryPoint); 
    }
    // Fallback function to receive ether 
    receive() external payable { 
    
    }


 /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
 //////////////////////////////////////////////////////////////*/
/// @notice Execute a call to a destination address with a value and function data.
/// @dev This function is called by the EntryPoint contract to execute a call to a destination address with a value and function data.
/// @param dest The destination address to call.
/// @param value The value to send with the call.
/// @param fuctionData The function data to include in the call.
function execute (address dest, uint256 value, bytes calldata fuctionData) external requireFromEntryPointOrOwner {
    (bool success, bytes memory result) = dest.call{value: value}(fuctionData); 
    if(!success){ 
        revert HelloWorldAccount__CallFailed(result); 
    }
}


/// @notice Validate the user operation and pay the prefund if necessary (in the case where there is no paymaster).
/// @dev This function is called by the EntryPoint contract to validate the user operation and pay the prefund if necessary.
/// @param userOp The user operation to validate. 
/// @param userOpHash The hash of the user operation. 
/// @param missingAccountFunds The amount of funds missing in the account. 
function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) 
external requireFromEntryPoint returns (uint256 validationData)
{
    validationData = _validateSignature(userOp, userOpHash); 
    if (validationData != SIG_VALIDATION_SUCCESS){ 
        return validationData; 
    }

    _payPrefund(missingAccountFunds); 
    return SIG_VALIDATION_SUCCESS; 
}

/// @notice Set the greeting message.
/// @dev This function is called by the owner of the contract to set the greeting message.
/// @param _newGreeting The new greeting message.
function setGreeting(string memory _newGreeting) external requireFromEntryPointOrOwner {
    greet = _newGreeting;
}




/*//////////////////////////////////////////////////////////////
                           INTERNAL  FUNCTIONS
//////////////////////////////////////////////////////////////*/
/// @notice  Helper function to validate the signature of the user operation.
/// @dev This function recovers the signer of the user operation and validates that it is the owner of the contract.
/// @param userOp The user operation to validate.
/// @param userOpHash The hash of the user operation.
/// @return uint256 SIG_VALIDATION_SUCCESS if the signature is valid, SIG_VALIDATION_FAILED otherwise.
function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) 
internal  view returns (uint256 validationData)
{
    bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash); 
    address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature); 
    if(signer != owner()){ 
        return SIG_VALIDATION_FAILED; 
    }
    return SIG_VALIDATION_SUCCESS;
} 

/// @notice Helper function to pay the prefund to the account.
/// @dev This function sends the missing account funds to the account.
/// @param missingAccountFunds The amount of funds missing in the account.

function _payPrefund(uint256 missingAccountFunds) internal { 
    if(missingAccountFunds != 0){ 
        (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}(""); 
        (success); 
    }
}

/// @notice Validate the nonce of the user operation. 
/// @dev compares the nonce in the userOperation witht he currentNonce from the EntryPoint contract. 
/// @param userOp The user operation to validate.
/// @return  uint256 SIG_VALIDATION_SUCCESS if the nonce is valid, SIG_VALIDATION_FAILED otherwise. 
function _validateNonce(PackedUserOperation calldata userOp) internal view returns (uint256) {
    // Get the current nonce for this userOp from the EntryPoint contract
    uint256 currentnonce = INonceManager(address(i_entryPoint))
    .getNonce(addrees(this)), userOp.nonce);

    // Check if the nonce in the userOp matches the current nonce.
    if(userOp.nonce != currentnonce){
        return SIG_VALIDATION_FAILED;
    }

    return SIG_VALIDATION_SUCCESS; 
}
/*//////////////////////////////////////////////////////////////
                            GETTERS
//////////////////////////////////////////////////////////////*/
/// @notice Get the EntryPoint contract address.
/// @return address The EntryPoint contract address.
function getEntryPoint() external view returns (address) {
    return address(i_entryPoint);
}



}
