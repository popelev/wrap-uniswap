// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// TODO reentrncy guard
// TODO ERC20 ??

contract MyWrappedUniswap {
    //TODO using SafeERC20 for IERC20;
    
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
   
    uint24 public constant UNISWAP_V3_FIX_FEE = 3000;

    mapping (address => mapping (address => uint256)) public balance;  // balance[user][asset]

    function deposit(
        address tokenIn, 
        uint256 amountIn) external {

        uint256 balanceBefore = IERC20(tokenIn).balanceOf(address(this));
        bool success = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // TODO require

        uint256 balanceAfter = IERC20(tokenIn).balanceOf(address(this));

        uint256 delta = balanceAfter - balanceBefore;
        
        // TODO require amountIn == delta

        balance[msg.sender][tokenIn] += delta;
    }

    function withdraw(
        address tokenOut, 
        uint256 amountOut) external {
        
        balance[msg.sender][tokenOut] -= amountOut;

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        bool success = IERC20(tokenOut).transfer(msg.sender, amountOut);
        // TODO require

        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        uint256 delta = balanceAfter - balanceBefore;
        
        // TODO require amountOut >= delta
    }

    // swapSingleHopExactAmountIn
    function swapUniV2(
        address tokenIn, 
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut)
    {
        balance[msg.sender][tokenIn] -= amountIn;

        IERC20(tokenIn).approve(UNISWAP_V2_ROUTER, amountIn);

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

        balance[msg.sender][tokenOut] += amountOut;

    }

    function swapUniV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        swapUniV3(tokenIn, tokenOut , amountIn, UNISWAP_V3_FIX_FEE);
    }

    function swapUniV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 poolFee
    ) public returns (uint256 amountOut) {
        balance[msg.sender][tokenIn] -= amountIn;

        IERC20(tokenIn).approve(UNISWAP_V3_ROUTER, amountIn);
        
        bytes memory path = abi.encodePacked(
            tokenIn,
            poolFee,
            tokenOut
        );

        IUniswapV3Router.ExactInputParams memory params = IUniswapV3Router
            .ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0
        });

        amountOut = IUniswapV3Router(UNISWAP_V3_ROUTER).exactInput(params);

        balance[msg.sender][tokenOut] += amountOut;
    }
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

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
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
