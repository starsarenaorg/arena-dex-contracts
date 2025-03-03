/*
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "forge-std/Test.sol";
import "../src/libraries/JoeLibrary.sol";
import "../src/JoeFactory.sol";
import "../src/JoeRouter02.sol";
import "../src/interfaces/IJoeRouter02.sol";
import "../src/interfaces/IWAVAX.sol";
import {MockWAVAX} from "./MockWavax.sol";
import {MockERC20} from "./MockERC20.sol";



contract DexUtils is Test {
    // Global variables for easy access
    address public WAVAX;
    address public token;
    
    function deployDex(address feeToSetter) public returns (JoeRouter02 router, JoeFactory factory, bytes32 pairCodeHash) {
        // Deploy WAVAX mock
        MockWAVAX wavaxToken = new MockWAVAX();
        WAVAX = address(wavaxToken);
        
        // Deploy test token
        MockERC20 testToken = new MockERC20();
        token = address(testToken);
        
        // Deploy factory
        factory = new JoeFactory(feeToSetter);
        
        // Deploy router with mock WAVAX
        router = new JoeRouter02(address(factory), WAVAX);
        
        // Get and log pair code hash
        pairCodeHash = factory.pairCodeHash();
        console.log("Pair Code Hash:", vm.toString(pairCodeHash));
        console.log("WAVAX Address:", WAVAX);
        console.log("Token Address:", token);
        
        return (router, factory, pairCodeHash);
    }

    function deployAndAddLiquidity(
        IJoeRouter02 router,
        address tokenAddress,
        address liquidityProvider,
        uint256 tokenAmount,
        uint256 avaxAmount
    ) public returns (uint256 liquidity) {
        MockERC20 token = MockERC20(tokenAddress);
        
        // Mint tokens to liquidity provider
        token.mint(liquidityProvider, tokenAmount);
        
        // Fund liquidity provider with AVAX
        vm.deal(liquidityProvider, avaxAmount);
        
        // Add liquidity
        vm.startPrank(liquidityProvider);
        
        token.approve(address(router), tokenAmount);
        
        (,, liquidity) = router.addLiquidityAVAX{value: avaxAmount}(
            address(token),
            tokenAmount,
            0, // Accept any amount of tokens
            0, // Accept any amount of AVAX
            liquidityProvider,
            block.timestamp + 3600
        );
        
        vm.stopPrank();
        
        return liquidity;
    }

    function buyTokens(
        IJoeRouter02 router,
        address tokenAddress,
        address buyer,
        uint256 avaxAmount
    ) public returns (uint256[] memory amounts) {
        // Setup buy path
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = tokenAddress;
        
        // Fund buyer with AVAX
        vm.deal(buyer, avaxAmount);
        
        // Execute swap
        vm.startPrank(buyer);
        amounts = router.swapExactAVAXForTokens{value: avaxAmount}(
            0, // Accept any amount of tokens
            path,
            buyer,
            block.timestamp + 3600
        );
        vm.stopPrank();
        
        return amounts;
    }

    function sellTokens(
        IJoeRouter02 router,
        address tokenAddress,
        address seller,
        uint256 tokenAmount
    ) public returns (uint256[] memory amounts) {
        MockERC20 token = MockERC20(tokenAddress);
        
        // Setup sell path
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WAVAX();
        
        // Approve router
        vm.startPrank(seller);
        token.approve(address(router), tokenAmount);
        
        // Execute swap
        amounts = router.swapExactTokensForAVAX(
            tokenAmount,
            0, // Accept any amount of AVAX
            path,
            seller,
            block.timestamp + 3600
        );
        vm.stopPrank();
        
        return amounts;
    }
}

*/