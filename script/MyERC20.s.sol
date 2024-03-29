// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract DeployMyERC20 is Script {
    function run() public returns (address){
        vm.startBroadcast();
        MyERC20 nft = new MyERC20();
        vm.stopBroadcast();
        return address(nft);
    }
}
