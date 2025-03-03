// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import  "./JoeLib820.sol";
import {MockERC20} from "./MockERC20.sol";      
import {IJoeRouter02} from "../src/interfaces/IJoeRouter02.sol";
import {IJoeFactory} from "../src/interfaces/IJoeFactory.sol";
import {IJoePair} from "../src/interfaces/IJoePair.sol";

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract DexComparisonTest is Test { 
    MockERC20 public mockToken;
    IJoeRouter02 public router1;
    IJoeRouter02 public router2;
    address public user1;
    address public user2;
    address public WAVAX;
    address public feeReceiver = 0x74917a7960A010862335d92B3cEd199d779acfEd;

    uint256 constant INITIAL_AMOUNT = 1000 ether;
    uint256 constant LP_AMOUNT = 100 ether;
    uint256 constant SWAP_AMOUNT = 1 ether;
    
    // Replace these with your actual router addresses
    address constant ROUTER1_ADDRESS = address(0x4d7Db7ccbDDE2420260679e2e547e4Fab8E9DF84); // modified router
// 0x6401989498310c63ed7068174c99bad5d81E1a17
    address public factory1_address;
    //0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901 -> fuji router
    address constant ROUTER2_ADDRESS = address(0x6401989498310c63ed7068174c99bad5d81E1a17);

    function setUp() public {
        // Create users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        factory1_address = IJoeRouter02(ROUTER1_ADDRESS).factory();
        emit log_named_address("factory1_address", factory1_address);   
        // Deploy mock token
        mockToken = new MockERC20();

        // Get router instances
        router1 = IJoeRouter02(ROUTER1_ADDRESS);
        router2 = IJoeRouter02(ROUTER2_ADDRESS);

        // Get WAVAX address
        WAVAX = router1.WAVAX();

        // Mint tokens to users
        mockToken.mint(user1, INITIAL_AMOUNT);
        mockToken.mint(user2, INITIAL_AMOUNT);

        // Give users some AVAX
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        //addLiquidity(address(router1), user1);
        //addLiquidity(address(router2), user1);
    }

    function addLiquidity(address _router, address _user) internal {
        vm.startPrank(_user);
        
        // Approve router
        mockToken.approve(_router, LP_AMOUNT);

        // Add liquidity
        IJoeRouter02(_router).addLiquidityAVAX{value: 10 ether}(
            address(mockToken),
            LP_AMOUNT,
            0, // Accept any amount of tokens
            0, // Accept any amount of AVAX
            _user,
            block.timestamp + 1000
        );

        vm.stopPrank();
    }

    function addLiquidity(address _router, address _user, uint256 _avaxAmount, uint256 _tokenAmount) internal {
        vm.startPrank(_user);
        
        // Approve router
        mockToken.approve(_router, _tokenAmount);

        // Add liquidity
        IJoeRouter02(_router).addLiquidityAVAX{value: _avaxAmount}(
            address(mockToken),
            _tokenAmount,
            0, // Accept any amount of tokens
            0, // Accept any amount of AVAX
            _user,
            block.timestamp + 1000
        );

        vm.stopPrank();
    }

    /**
    Fuzz stragegy :
    In a loop:
        1- deploy an arbitrary amount of liquidity in Avax and mockToken
        2- buy an random amount thats smaller than the liquidty pool boundaries
        3- sell a random amount thats in the balance boundaries
     */
    

    function fundUserWithTokensAndAvax(address _user, uint256 _avaxAmount, uint256 _tokenAmount) internal {
        if(_avaxAmount > 0 ){
            vm.deal(_user,_avaxAmount);
        }
        if(_tokenAmount > 0) {
            mockToken.mint(_user,_tokenAmount);
        }
    }

    function getAvaxAmountForBuy() internal returns (uint256 _AvaxAmount) {
        address pairAddress =IJoeFactory(factory1_address).getPair(WAVAX,address(mockToken));
        (uint256 WAVAXReserve, uint256 tokenReserve,) = IJoePair(pairAddress).getReserves();
        return vm.randomUint(1, WAVAXReserve * 6 / 10);
    }

    function getTokenAmountForSell() internal returns (uint256 _tokenAmount) {
        address pairAddress =IJoeFactory(factory1_address).getPair(WAVAX,address(mockToken));
        (uint256 WAVAXReserve, uint256 tokenReserve,) = IJoePair(pairAddress).getReserves();
        return vm.randomUint(1, tokenReserve * 6 / 10);
    }

    // q : can an LP pool

    function testBuySellFuzz(uint256 _avaxAmount, uint256 _tokenAmount) public {
        _avaxAmount = vm.randomUint(100 ether, 1000 ether);
        _tokenAmount = vm.randomUint(1 ether, 10000 ether);
        address _router = address(router1);
        for (uint256 index = 0; index < 10; index++) {
            fundUserWithTokensAndAvax(user1,_avaxAmount,_tokenAmount);
            addLiquidity(_router,user1,_avaxAmount,_tokenAmount);
            uint256 avaxAmountToSpend = getAvaxAmountForBuy();
            fundUserWithTokensAndAvax(user1,avaxAmountToSpend,0);
            _buyTokensFromLp(avaxAmountToSpend, user1, _router);
            uint256 tokenAmountToSell = getTokenAmountForSell();
            fundUserWithTokensAndAvax(user1,0,tokenAmountToSell);
            _sellTokensToLp(tokenAmountToSell, user1, _router);
        }

    }

    function _buyTokensFromLp(uint256 _avaxAmount, address _user, address _router) internal {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(mockToken);
        vm.startPrank(_user);
        IJoeRouter02(_router).swapExactAVAXForTokens{value: _avaxAmount}(
            0, // Accept any amount of tokens
            path,
            _user,
            block.timestamp 
        );
        vm.stopPrank();
    }

    function _sellTokensToLp(uint256 _tokenAmount, address _user, address _router) internal {
        address[] memory path = new address[](2);
        path[0] = address(mockToken);
        path[1] = WAVAX;
        vm.startPrank(_user);
        mockToken.approve(address(_router), _tokenAmount);
        IJoeRouter02(_router).swapExactTokensForAVAX(
            _tokenAmount,
            0, // Accept any amount of AVAX
            path,
            _user,
            block.timestamp
        );
        vm.stopPrank();
    }


    function testSellComparison() public {
        // Setup sell path
        address[] memory path = new address[](2);
        path[0] = address(mockToken);
        path[1] = WAVAX;

        // Record initial balances
        uint256 initialAVAXBalance1 = user1.balance;
        uint256 initialAVAXBalance2 = user2.balance;
        uint256 initialFeeReceiverBalance = feeReceiver.balance;
        uint256 initialFeeReceiverToken = mockToken.balanceOf(feeReceiver);
        uint256 initialFeeReceiverWAVAX = IERC20(WAVAX).balanceOf(feeReceiver);

        // Perform swaps
        vm.startPrank(user1);
        mockToken.approve(address(router1), SWAP_AMOUNT);
        router1.swapExactTokensForAVAX(
            SWAP_AMOUNT,
            0, // Accept any amount of AVAX
            path,
            user1,
            block.timestamp + 3600
        );
        vm.stopPrank();

        vm.startPrank(user2);
        mockToken.approve(address(router2), SWAP_AMOUNT);
        router2.swapExactTokensForAVAX(
            SWAP_AMOUNT,
            0, // Accept any amount of AVAX
            path,
            user2,
            block.timestamp + 3600
        );
        vm.stopPrank();

        // Calculate changes
        uint256 change1 = user1.balance - initialAVAXBalance1;
        uint256 change2 = user2.balance - initialAVAXBalance2;
        uint256 feeReceiverAVAXChange = feeReceiver.balance - initialFeeReceiverBalance;
        uint256 feeReceiverTokenChange = mockToken.balanceOf(feeReceiver) - initialFeeReceiverToken;
        uint256 feeReceiverWAVAXChange = IERC20(WAVAX).balanceOf(feeReceiver) - initialFeeReceiverWAVAX;

        // Log results
        emit log_named_uint("Router 1 AVAX received", change1);
        emit log_named_uint("Router 2 AVAX received", change2);
        emit log_named_uint("Fee Receiver AVAX change", feeReceiverAVAXChange);
        emit log_named_uint("Fee Receiver Token change", feeReceiverTokenChange);
        emit log_named_uint("Fee Receiver WAVAX change", feeReceiverWAVAXChange);

        // Compare results (allow 0.0001 AVAX difference)
        uint256 difference = change1 > change2 ? change1 - change2 : change2 - change1;
        assertEq(difference, 0);
    }

    function testBuyComparison() public {
        // Setup buy path
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(mockToken);

        uint256 amountIn = 0.1 ether;

        // Record initial balances
        uint256 initialToken1 = mockToken.balanceOf(user1);
        uint256 initialToken2 = mockToken.balanceOf(user2);
        uint256 initialFeeReceiverToken = mockToken.balanceOf(feeReceiver);
        uint256 initialFeeReceiverWAVAX = IERC20(WAVAX).balanceOf(feeReceiver);
        uint256 initialAVAXBalance1 = user1.balance;
        uint256 initialAVAXBalance2 = user2.balance;
        uint256 initialFeeReceiverAVAX = feeReceiver.balance;

        // Perform swaps
        vm.startPrank(user1);
        router1.swapExactAVAXForTokens{value: amountIn}(
            0, // Accept any amount of tokens
            path,
            user1,
            block.timestamp + 3600
        );
        vm.stopPrank();

        vm.startPrank(user2);
        router2.swapExactAVAXForTokens{value: amountIn}(
            0, // Accept any amount of tokens
            path,
            user2,
            block.timestamp + 3600
        );
        vm.stopPrank();

        // Calculate changes
        uint256 tokenChange1 = mockToken.balanceOf(user1) - initialToken1;
        uint256 tokenChange2 = mockToken.balanceOf(user2) - initialToken2;
        uint256 feeReceiverTokenChange = mockToken.balanceOf(feeReceiver) - initialFeeReceiverToken;
        uint256 feeReceiverWAVAXChange = IERC20(WAVAX).balanceOf(feeReceiver) - initialFeeReceiverWAVAX;
        uint256 avaxChange1 = initialAVAXBalance1 - user1.balance;
        uint256 avaxChange2 = initialAVAXBalance2 - user2.balance;
        uint256 feeReceiverAVAXChange = feeReceiver.balance - initialFeeReceiverAVAX;

        // Log results
        emit log_named_uint("Router 1 AVAX spent", avaxChange1);
        emit log_named_uint("Router 2 AVAX spent", avaxChange2);
        emit log_named_uint("Router 1 tokens received", tokenChange1);
        emit log_named_uint("Router 2 tokens received", tokenChange2);
        emit log_named_uint("Fee Receiver token change", feeReceiverTokenChange);
        emit log_named_uint("Fee Receiver AVAX change", feeReceiverAVAXChange);
        emit log_named_uint("Fee Receiver WAVAX change", feeReceiverWAVAXChange);

        // Compare results (allow 0.0001 token difference)
        uint256 difference = tokenChange1 > tokenChange2 ? tokenChange1 - tokenChange2 : tokenChange2 - tokenChange1;
        assertEq(difference, 0);
    }
} 