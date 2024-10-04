// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol"; 
import {Ownable} from "openzeppelin-solidity/contracts/access/Ownable.sol"; 
import { PackedUserOperation } from "lib/account-abstraction/contracts/PackedUserOperation.sol"; 
import { MessageHasUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";  
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_PASSED} from "lib/account-abstraction/contracts/core/Helpers.sol"; 
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol"; 



contract ERC4337HelloWorld  is IAccount, Ownable{ 

/*//////////////////////////////////////////////////////////////
                                 ERRORS
//////////////////////////////////////////////////////////////*/
error HelloWorldAccount__NotFromEntryPoint(); 
error HelloWorldAccout__NotFromEntryPointOrOwner(); 
error HelloWorldAccount__CallFailed(); 



IEntryPoint private immutable i_entryPoint; 
string public greet = "Hello World"; 

modifier requireFromEntryPoint(){ 
    if(msg.sender != address(i_entryPoint)){ 
        revert HelloWorldAccount__NotFromEntryPoint(); 
    }
    _; 

}

modifier requireFromEntryPointOrOwner(){ 
    if(msg.sender != address(i_entryPoint) && msg.sender != owner()){ 
        revert HelloWorldAccout__NotFromEntryPointOrOwner(); 
    }
    _; 

    constructor (address entryPoint) Ownable(msg.sender) {  
        i_entryPoint = IEntryPoint(entryPoint); 
    }

    receive() external payable { 
        revert HelloWorldAccount__CallFailed();  
    }

    function execute (address dest, uint256 value, bytes calldata fuctionData) external requireFromEntryPointOrOwer {
        (bool success, bytes memory return) = dest.call{value: value}(fuctionData); 
        if(!success){ 
            revert HelloWorldAccount__CallFailed(); 
        }
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) 
    external requireFromEntryPoint returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash); 
        // we can additionally validate nonce with _validateNonce()
        _payprefund(missingAccountFunds); 
    }


    // Helper function to validate the signature of the user operation.
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) 
    internal  view returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash); 
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature); 
        if(signer != userOp.signer){ 
            return SIG_VALIDATION_FAILED; 
        }
        return SIG_VALIDATION_SUCCESS;
    } 

    function _payPrefund(uint256 missingAccountFunds) internal { 
        if(missingAccountFunds != 0){ 
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}(""); 
            (success); 
        }
    }

    function setGreeting(string memory _newGreeting) external requireFromEntryPointOrOwner {
        greet = _newGreeting;
    }

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}


}
