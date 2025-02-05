// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AIAgent.sol";  // Import the AI Agent contract

contract AIAgentFactory {
    address public owner;
    mapping(address => address) public userToAgent;  // Maps users to their deployed AI Agent contracts
    address[] public allAgents; // Stores all deployed AI Agents

    event AIAgentCreated(address indexed user, address aiAgent);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createAIAgent(
        address investmentToken,
        address priceFeed,
        address uniswapRouter,
        address agentWallet
    ) external {
        require(userToAgent[msg.sender] == address(0), "AI Agent already exists for this user");

        // Deploy a new AI Agent contract for the user
        AIAgent newAgent = new AIAgent(
            investmentToken,
            priceFeed,
            uniswapRouter,
            agentWallet
        );

        // Store the new AI Agent's address
        userToAgent[msg.sender] = address(newAgent);
        allAgents.push(address(newAgent));

        emit AIAgentCreated(msg.sender, address(newAgent));
    }

    function getUserAIAgent(address user) external view returns (address) {
        return userToAgent[user];
    }

    function getAllAIAgents() external view returns (address[] memory) {
        return allAgents;
    }
}
