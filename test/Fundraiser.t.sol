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
    uint256 public constant TEST_GOAL = 10000;
    uint256 public constant TEST_DEADLINE = 10000;

    function setUp() public {
        vm.prank(OWNER);
        rightErc20 = new MyERC20();
        wrongErc20 = new MyERC20();
        fundraiser = new Fundraiser();
    }

    function testCreateFundRaiser() public {
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        vm.expectRevert();
        fundraiser.createFundraiser(
            0,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        vm.expectRevert();
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp - TEST_DEADLINE
        );
    }

    function testDonate() public {
        vm.startPrank(USER);
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        rightErc20.mint(USER, 10000);
        rightErc20.approve(address(fundraiser), 10000);
        fundraiser.donate(1, address(rightErc20), 10000);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(USER);
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        rightErc20.mint(USER, 10000);
        rightErc20.approve(address(fundraiser), 10000);
        fundraiser.donate(1, address(rightErc20), 10000);
        vm.expectRevert();
        fundraiser.withdraw(1);
        vm.warp(block.timestamp + TEST_DEADLINE);
        fundraiser.withdraw(1);
        vm.stopPrank();
    }
}
