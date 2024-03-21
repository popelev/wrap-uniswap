// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MyWrappedUniswap, IWETH} from "src/wuni.sol";
import {WETH9} from "./weth9.sol";

contract MyUniswapTest is Test {
    WETH9 private weth = WETH9(WETH);
    IERC20 private dai = IERC20(DAI);
    IERC20 private usdc = IERC20(USDC);

    address user = vm.addr(1);

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    MyWrappedUniswap private wuni = new MyWrappedUniswap();

    function setUp() public {
        vm.prank(user);
        vm.deal(user, 100 ether);
        vm.stopPrank();
    }

    function test_deposit_RevertedWithoutApprove() public {
        vm.startPrank(user);
        uint256 amount = 1e18;

        weth.deposit{value: amount}();

        vm.expectRevert();
        wuni.deposit(WETH, amount);
        vm.stopPrank();
    }

    function test_deposit_ERC20() public {
        vm.startPrank(user);
        uint256 amount = 1e18;

        weth.deposit{value: amount}();

        // assertEq(WETH9(WETH).balanceOf(user), amount);
        // assertEq(wuni.getBalance(user, WETH), 0);
        // assertEq(WETH9(WETH).balanceOf(address(wuni)), 0);

        weth.approve(address(wuni), amount);
        wuni.deposit(WETH, amount);

        // assertEq(WETH9(WETH).balanceOf(user), 0);
        // assertEq(wuni.getBalance(address(wuni), WETH), amount);
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(user);
        uint256 amount = 1e18;

        weth.deposit{value: amount}();
        weth.approve(address(wuni), amount);

        // assertEq(WETH9(WETH).balanceOf[user], amount);

        wuni.deposit(WETH, amount);
        // assertEq(WETH9(WETH).balanceOf[user], 0);

        wuni.withdraw(WETH, amount);
        // assertEq(WETH9(WETH).balanceOf[user], amount);

        vm.stopPrank();
    }

    function test_swapUniV2_WETH_DAI() public {
        vm.startPrank(user);
        uint256 amount = 1e18;

        weth.deposit{value: amount}();
        weth.approve(address(wuni), amount);
        wuni.deposit(WETH, amount);

        uint256 amountOut = wuni.swapUniV2(WETH, DAI, amount);

        console2.log("DAI", amountOut);
        vm.stopPrank();
    }

    function test_swapUniV3_WETH_DAI() public {
        vm.startPrank(user);
        uint256 amount = 1e18;

        weth.deposit{value: amount}();
        weth.approve(address(wuni), amount);
        wuni.deposit(WETH, amount);

        uint256 amountOut = wuni.swapUniV3(WETH, DAI, amount);

        console2.log("DAI", amountOut);
        vm.stopPrank();
    }
}
