// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MyWrappedUniswap} from "src/wuni.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

contract MyUniswapTest is Test {
    IWETH private weth = IWETH(WETH);
    IERC20 private dai = IERC20(DAI);
    IERC20 private usdc = IERC20(USDC);

    MyWrappedUniswap private wuni = new MyWrappedUniswap();

    function setUp() public {}

    function testUniV2() public {
        weth.deposit{value: 1e18}();
        weth.approve(address(wuni), 1e18);
        wuni.deposit(WETH, 1e18);

        uint256 amountOut = wuni.swapUniV2(WETH, DAI, 1e18);

        console2.log("DAI", amountOut);
    }

    function testUniV3() public {
        weth.deposit{value: 1e18}();
        weth.approve(address(wuni), 1e18);
        wuni.deposit(WETH, 1e18);

        uint256 amountOut = wuni.swapUniV3(WETH, DAI, 1e18);

        console2.log("DAI", amountOut);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}