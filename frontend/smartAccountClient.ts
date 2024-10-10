
import { 
    createAlchemySmartAccountClient, 
    sepolia, 
    alchemy,} from "@account-kit/infra"; 

import { createLightAccount } from "@account-kit/smart-contracts"; 
import { LocalAccountSigner } from "@aa-sdk/core"; 
import { encodeFunctionData, encodeAbiParameters, parseAbiParameters } from "viem"; 
import { generatePrivateKey } from "viem/accounts"; 

// alchemy API key
const ALCHEMY_API_KEY = " " ;
const ALCHEMY_POLICY_ID = " "; 

// New greeting to set 
const newGreeting = "Hello, World!"; 


// Create a transport with Alchemy 
const alchemyTransport = alchemy({ apiKey: ALCHEMY_API_KEY }); ; 

// Set up with your Alchemy API key 
export const smartAccountClient = createAlchemySmartAccountClient({
    transport: alchemyTransport, 
    policyId: ALCHEMY_POLICY_ID,
    chain: sepolia, 
    account:  await createLightAccount({
        signer : LocalAccountSigner.privateKeyToAccountSigner(generatePrivateKey()), 
        chain: sepolia,
        transport: alchemyTransport
    })
}); 

async function getNonce(address:string): Promise<bigint> {
    const nonce = await smartAccountClient.transport.getNonce({
    address, 
}); 

    return nonce;
}

const encodedFunctionCall = encodeFunctionData({
    abi : [
        {
            "inputs": [
                {
                    "internalType": "string",
                    "name": "newGreeting",
                    "type": "string"
                },
            ],
            "name": "setGreeting",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
    ],
    functionName: "setGreeting", 
    args: [newGreeting] 
}); 

const encodeUint256ToBytes32 = (value: bigint): `0x${string}` => {
    return `0x${value.toString(16).padStart(64, '0')}`; 
}; 


async function requestPaymasterAndData(userOp:any){
    const response = await fetch('https://eth-sepolia.g.alchemy.com/v2/' + ALCHEMY_API_KEY, { 
    method : 'POST', 
    headers: {'Content-Type': 'application/json'}, 
    body: JSON.stringify({
        jsonrpc: '2.0', 
        method: 'alchemy_requestPaymasterAndData',  
        params: [
            { 
                policyId: ALCHEMY_POLICY_ID,
                entryPoint: "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789",
                userOperation: userOp,
            }
        ], 
    })
},
); 


const data = await response.json(); 
return data.result.paymasterAndData;  
}

const userOperation = { 
    sender : 0x2aaf91afc256dfa51e36eb4b88eb57acb5114157,
    nonce: await getNonce(smartAccountClient.account.address),
    initCode: '0x',
    callData: encodedFunctionCall, 
    accountGasLimit: encodeAbiParameters(
        parseAbiParameters('uint128, uint128'),
        [BigInt(2000000), BigInt(2000000)]
    ),     
    preVerificationGas: encodeUint256ToBytes32(BigInt(2000000)),
    gasFees : encodeAbiParameters(
        parseAbiParameters('uint128, uint128'),
        [BigInt(2000000), BigInt(2000000)]
    ),
    paymasterAndData: '0x' ,
    signature: '0x',
};

userOperation.paymasterAndData = await requestPaymasterAndData(userOperation);

const contractInteraction = await smartAccountClient.sendUserOperation(
    userOperation,
); 

console.log(contractInteraction); 