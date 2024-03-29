// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {Fundraiser} from "../src/Fundraiser.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract FundraiserTest is Test {
    Fundraiser public fundraiser;
    MyERC20 public rightErc20;
    MyERC20 public wrongErc20;
    address public OWNER = makeAddr("OWNER");
    address public USER = makeAddr("user");

    function setup() public {
        vm.prank(OWNER);
        rightErc20 = new MyERC20();
        wrongErc20 = new MyERC20();
        fundraiser = new Fundraiser();
    }
}
