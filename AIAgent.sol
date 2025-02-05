// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// If your dependency is correctly installed, you can remove this interface.
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract AIAgent {
    address public owner;
    address public agentWallet;
    address public uniswapRouter;
    uint256 public managementFee = 100; // 1% fee (100 basis points)
    
    mapping(address => uint256) public balances; // User balances stored in the contract
    address public investmentToken; // The original investment token
    AggregatorV3Interface public priceFeed;
    
    event Deposited(address indexed user, uint256 amount);
    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event Withdrawn(address indexed user, uint256 amount);
    event Rebalanced(address indexed user);

    modifier onlyAgent() {
        require(msg.sender == agentWallet, "Not authorized");
        _;
    }

    constructor(address _investmentToken, address _priceFeed, address _uniswapRouter, address _agentWallet) {
        owner = msg.sender;
        investmentToken = _investmentToken;
        priceFeed = AggregatorV3Interface(_priceFeed);
        uniswapRouter = _uniswapRouter;
        agentWallet = _agentWallet;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        uint256 fee = (amount * managementFee) / 10000;
        uint256 depositAmount = amount - fee;
        
        IERC20(investmentToken).transferFrom(msg.sender, agentWallet, fee);
        IERC20(investmentToken).transferFrom(msg.sender, address(this), depositAmount);
        balances[msg.sender] += depositAmount;
        emit Deposited(msg.sender, depositAmount);
    }

    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) public onlyAgent {
        require(IERC20(tokenIn).approve(uniswapRouter, amountIn), "Approval failed");
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint256[] memory amounts = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        
        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amounts[1]);
    }

    function rebalance(address[] calldata tokens, uint256[] calldata amounts) external onlyAgent {
        require(tokens.length == amounts.length, "Mismatched inputs");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            swapTokens(investmentToken, tokens[i], amounts[i], 0);
        }
        emit Rebalanced(msg.sender);
    }

    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No funds available");
        
        IERC20(investmentToken).transfer(msg.sender, balance);
        balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, balance);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
