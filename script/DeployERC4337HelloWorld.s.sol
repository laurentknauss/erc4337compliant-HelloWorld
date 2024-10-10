// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC4337HelloWorld} from "src/ERC4337HelloWorld.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployERC4337HelloWorld is Script {
    function run() public {
        deployERC4337HelloWorld();
    }


       function deployERC4337HelloWorld() public returns (HelperConfig, ERC4337HelloWorld) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Deploy the ERC4337HelloWorld contract
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Private key of the deployer
        vm.startBroadcast(deployerPrivateKey);
        ERC4337HelloWorld erc4337HelloWorld = new ERC4337HelloWorld(config.entryPoint); 
        erc4337HelloWorld.transferOwnership(config.account);
        vm.stopBroadcast();
        return (helperConfig, erc4337HelloWorld);
    }
}
