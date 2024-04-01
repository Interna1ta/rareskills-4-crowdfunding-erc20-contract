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
    address public USER = makeAddr("USER");
    address public FREELOADER = makeAddr("FREELOADER");
    uint256 public constant TEST_GOAL = 10000;
    uint256 public constant TEST_DEADLINE = 10000;

    event Donation(
        address indexed donor,
        uint256 indexed campaignId,
        uint256 amount,
        address token
    );

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
        vm.warp(block.timestamp - TEST_DEADLINE);
        vm.expectRevert();
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );

        assertEq(fundraiser.s_campaignCount(), 1);
    }

    function testDonate() public {
        vm.startPrank(USER);
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        rightErc20.mint(USER, 20000);
        rightErc20.approve(address(fundraiser), 20000);
        vm.expectRevert();
        fundraiser.donate(1, address(rightErc20), 0);
        vm.expectRevert();
        fundraiser.donate(1, address(wrongErc20), 10000);
        vm.expectRevert();
        fundraiser.donate(2, address(rightErc20), 10000);
        fundraiser.donate(1, address(rightErc20), 10000);
        fundraiser.donate(1, address(rightErc20), 10000);
        vm.expectRevert();
        vm.stopPrank();
        vm.warp(block.timestamp + TEST_DEADLINE + 1);
        vm.expectRevert();
        fundraiser.donate(1, address(rightErc20), 10000);
    }

    function testWithdrawCreator() public {
        vm.startPrank(OWNER);
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        rightErc20.mint(OWNER, 10000);
        rightErc20.approve(address(fundraiser), 10000);
        fundraiser.donate(1, address(rightErc20), 10000);
        vm.warp(12000);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(USER);
        fundraiser.withdrawCreator(2);
        vm.expectRevert();
        fundraiser.withdrawCreator(1);
        vm.prank(OWNER);
        fundraiser.withdrawCreator(1);
    }

    function testWithdrawDonator() public {
        vm.startPrank(OWNER);
        fundraiser.createFundraiser(
            TEST_GOAL,
            address(rightErc20),
            block.timestamp + TEST_DEADLINE
        );
        rightErc20.mint(OWNER, 10000);
        rightErc20.approve(address(fundraiser), 10000);
        fundraiser.donate(1, address(rightErc20), 100);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(FREELOADER);
        fundraiser.withdrawDonator(1);
        vm.startPrank(USER);
        rightErc20.mint(USER, 10000);
        rightErc20.approve(address(fundraiser), 10000);
        fundraiser.donate(1, address(rightErc20), 100);
        vm.expectRevert();
        fundraiser.withdrawDonator(1);
        vm.warp(12000);
        fundraiser.withdrawDonator(1);
        vm.stopPrank();
    }
}
