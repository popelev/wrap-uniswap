// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Contract for swap tokens via Uniswap v2 and Uniswap v3 in Ethereum Mainnet
/// @author Fedor Popelev
contract MyWrappedUniswap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 public constant UNISWAP_V3_FIX_FEE = 3000;
    address constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => mapping(address => uint256)) public _balance; // _balance[user][asset]

    /// @notice Deposit token or ETH to contract
    /// @param tokenIn Address of token
    /// @param amountIn Amount of token
    function deposit(address tokenIn, uint256 amountIn) external payable nonReentrant {
        if (msg.value > 0) {
            depositWETH();
        }

        uint256 balanceBefore = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 balanceAfter = IERC20(tokenIn).balanceOf(address(this));

        uint256 delta = balanceAfter - balanceBefore;
        require(amountIn >= delta, "Wrong deposited token amount");

        _balance[msg.sender][tokenIn] += delta;
    }

    /// @notice Withdraw token from contract
    /// @param tokenOut Address of token
    /// @param amountOut Amount of token
    function withdraw(address tokenOut, uint256 amountOut) external nonReentrant {
        _balance[msg.sender][tokenOut] -= amountOut;

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        uint256 delta = balanceBefore - balanceAfter;
        require(amountOut >= delta, "Wrong withdrawed token amount");
    }

    /// @notice Swap token via Uniswap v2
    /// @param tokenIn Address of send token
    /// @param tokenOut Address of recieve token
    /// @param amountIn Amount of send token
    /// @return amountOut Amount of recieved token
    function swapUniV2(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external nonReentrant returns (uint256 amountOut) {
        _balance[msg.sender][tokenIn] -= amountIn;

        IERC20(tokenIn).safeIncreaseAllowance(UNISWAP_V2_ROUTER, amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        // amounts[0] = tokenIn amount, amounts[1] = tokenOut amount
        amountOut = amounts[1];

        _balance[msg.sender][tokenOut] += amountOut;
    }

    /// @notice Swap token via Uniswap v3 with default pool fee
    /// @param tokenIn Address of send token
    /// @param tokenOut Address of recieve token
    /// @param amountIn Amount of send token
    /// @return amountOut Amount of recieved token
    function swapUniV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        swapUniV3(tokenIn, tokenOut, amountIn, UNISWAP_V3_FIX_FEE);
    }

    /// @notice Swap token via Uniswap v3 with default pool fee
    /// @param tokenIn Address of send token
    /// @param tokenOut Address of recieve token
    /// @param amountIn Amount of send token
    /// @param poolFee Custom pool fee
    /// @return amountOut Amount of recieved token
    function swapUniV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 poolFee
    ) public nonReentrant returns (uint256 amountOut) {
        _balance[msg.sender][tokenIn] -= amountIn;

        IERC20(tokenIn).safeIncreaseAllowance(UNISWAP_V3_ROUTER, amountIn);

        bytes memory path = abi.encodePacked(tokenIn, poolFee, tokenOut);

        IUniswapV3Router.ExactInputParams memory params = IUniswapV3Router.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0
        });

        amountOut = IUniswapV3Router(UNISWAP_V3_ROUTER).exactInput(params);

        _balance[msg.sender][tokenOut] += amountOut;
    }

    /// @notice Wrap ETH as WETH9
    function depositWETH() internal {
        uint256 amount = msg.value;
        IWETH(WETH9).deposit{value: amount}();
        _balance[msg.sender][WETH9] += amount;
    }

    /// @notice Get token balance
    /// @param user User address
    /// @param token Token address
    /// @return amount Amount of tokens

    function getBalance(address user, address token) external view returns (uint256 amount) {
        amount = _balance[user][token];
    }

    receive() external payable {
        depositWETH();
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
}
