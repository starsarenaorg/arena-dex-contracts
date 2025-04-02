// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {MockERC20} from "./MockERC20.sol";      
import {IArenaRouter02} from "../src/interfaces/IArenaRouter02.sol";
import {IArenaFactory} from "../src/interfaces/IArenaFactory.sol";
import {IArenaPair} from "../src/interfaces/IArenaPair.sol";

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DexComparisonTest is Test { 
    MockERC20 public mockToken;
    IArenaRouter02 public ArenaRouter;
    IArenaRouter02 public LFJRouter;
    address public user1;
    address public user2;
    address public WAVAX;
    address public feeReceiver = 0x74917a7960A010862335d92B3cEd199d779acfEd;

    uint256 constant INITIAL_AMOUNT = 1000 ether;
    uint256 constant LP_AMOUNT = 100 ether;
    uint256 constant SWAP_AMOUNT = 1 ether;
    address public feeToSetter;
    address constant ArenaRouterAddress = address(0x420C7036f56a060eC2760f462977131BB57EdDd6); //modified router avax
    address public factory1_address;

    address constant LFJRouterAddress = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    function setUp() public {
        // Create users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        factory1_address = IArenaRouter02(ArenaRouterAddress).factory();
        emit log_named_address("factory1_address", factory1_address);   
        // Deploy mock token
        mockToken = new MockERC20();

        // Get router instances
        ArenaRouter = IArenaRouter02(ArenaRouterAddress);
        LFJRouter = IArenaRouter02(LFJRouterAddress);

        // Get WAVAX address
        WAVAX = ArenaRouter.WAVAX();

        // Mint tokens to users
        mockToken.mint(user1, INITIAL_AMOUNT);
        mockToken.mint(user2, INITIAL_AMOUNT);

        // Give users some AVAX
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        feeToSetter = IArenaFactory(factory1_address).feeToSetter();
        vm.prank(feeToSetter);
        IArenaFactory(factory1_address).setProtocolFeeInfo(feeReceiver, 33);
        //addLiquidity(address(ArenaRouter), user1);
        //addLiquidity(address(LFJRouter), user1);
    }   

    function addLiquidity(address _router, address _user) internal {
        vm.startPrank(_user);
        
        // Approve router
        mockToken.approve(_router, LP_AMOUNT);

        // Add liquidity
        IArenaRouter02(_router).addLiquidityAVAX{value: 10 ether}(
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
        IArenaRouter02(_router).addLiquidityAVAX{value: _avaxAmount}(
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
        address pairAddress =IArenaFactory(factory1_address).getPair(WAVAX,address(mockToken));
        (uint256 WAVAXReserve, uint256 tokenReserve,) = IArenaPair(pairAddress).getReserves();
        return vm.randomUint(1, WAVAXReserve * 6 / 10);
    }

    function getTokenAmountForSell() internal returns (uint256 _tokenAmount) {
        address pairAddress =IArenaFactory(factory1_address).getPair(WAVAX,address(mockToken));
        (uint256 WAVAXReserve, uint256 tokenReserve,) = IArenaPair(pairAddress).getReserves();
        return vm.randomUint(1, tokenReserve * 6 / 10);
    }

    // q : can an LP pool

    function testBuySellFuzz(uint256 _avaxAmount, uint256 _tokenAmount) public {
        _avaxAmount = vm.randomUint(100 ether, 1000 ether);
        _tokenAmount = vm.randomUint(1 ether, 10000 ether);
        address _router = address(ArenaRouter);
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

    function testBuySellFuzzWithFees(uint256 _avaxAmount, uint256 _tokenAmount) public {
        vm.prank(feeToSetter);
        address receiver = makeAddr("receiver");
        uint256 feePercentage = vm.randomUint(1, 100);
        IArenaFactory(factory1_address).setProtocolFeeInfo(receiver, feePercentage);
        uint256 totalAvaxVolume = 0;
        uint256 totalTokenVolume = 0;
        _avaxAmount = vm.randomUint(100 ether, 1000 ether);
        _tokenAmount = vm.randomUint(1 ether, 10000 ether);
        address _router = address(ArenaRouter);
        for (uint256 index = 0; index < 10; index++) {
            fundUserWithTokensAndAvax(user1,_avaxAmount,_tokenAmount);
            addLiquidity(_router,user1,_avaxAmount,_tokenAmount);
            uint256 avaxAmountToSpend = getAvaxAmountForBuy();
            fundUserWithTokensAndAvax(user1,avaxAmountToSpend,0);
            _buyTokensFromLp(avaxAmountToSpend, user1, _router);
            totalAvaxVolume += avaxAmountToSpend;
            uint256 tokenAmountToSell = getTokenAmountForSell();
            fundUserWithTokensAndAvax(user1,0,tokenAmountToSell);
            _sellTokensToLp(tokenAmountToSell, user1, _router);
            totalTokenVolume += tokenAmountToSell;
        }
        uint256 expectedAvaxFee = (totalAvaxVolume * 3 /1000 - 10) * feePercentage / 100;   
        uint256 expectedTokenFee = (totalTokenVolume * 3 /1000 - 10) * feePercentage / 100;
        uint256 actualAvaxFee = IERC20(WAVAX).balanceOf(receiver);
        uint256 actualTokenFee = mockToken.balanceOf(receiver);
        assertGt(expectedAvaxFee, actualAvaxFee);
        assertGt(expectedTokenFee, actualTokenFee);
        assertApproxEqAbs(expectedAvaxFee, actualAvaxFee, 20);
        assertApproxEqAbs(expectedTokenFee, actualTokenFee, 20);

    }

    

    function testSimpleBuy() public {
        vm.prank(feeToSetter);
        address receiver = makeAddr("receiver");
        IArenaFactory(factory1_address).setProtocolFeeInfo(receiver, 100);
        address _router = address(ArenaRouter);
        address _user = user1;
        uint256 _avaxAmount = 100 ether;
        uint256 _tokenAmount = 1200000 ether;
        fundUserWithTokensAndAvax(_user,_avaxAmount,_tokenAmount);
        addLiquidity(_router, _user, _avaxAmount, _tokenAmount);
        vm.deal(_user, 5500 ether);
        _buyTokensFromLp(200 ether, user1, _router);
        console.log("receiver WAVAX balance", IERC20(WAVAX).balanceOf(receiver));
        console.log("receiver token balance", mockToken.balanceOf(receiver));
    }

    function testSimpleSell() public {
        vm.prank(feeToSetter);
        address receiver = makeAddr("receiver");
        IArenaFactory(factory1_address).setProtocolFeeInfo(receiver, 27);
        address _router = address(ArenaRouter);
        address _user = user1;
        uint256 _avaxAmount = 100 ether;
        uint256 _tokenAmount = 1200000 ether;
        fundUserWithTokensAndAvax(_user,_avaxAmount,_tokenAmount + 2000 ether);
        addLiquidity(_router, _user, _avaxAmount, _tokenAmount);
        vm.deal(_user, 5500 ether);
        _sellTokensToLp(2000 ether, user1, _router);
        console.log("receiver WAVAX balance", IERC20(WAVAX).balanceOf(receiver));
        console.log("receiver token balance", mockToken.balanceOf(receiver));
    }

    
    function _buyTokensFromLp(uint256 _avaxAmount, address _user, address _router) internal {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(mockToken);
        vm.startPrank(_user);
        IArenaRouter02(_router).swapExactAVAXForTokens{value: _avaxAmount}(
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
        IArenaRouter02(_router).swapExactTokensForAVAX(
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
        mockToken.approve(address(ArenaRouter), SWAP_AMOUNT);
        IArenaRouter02(ArenaRouter).swapExactTokensForAVAX(
            SWAP_AMOUNT,
            0, // Accept any amount of AVAX
            path,
            user1,
            block.timestamp + 3600
        );
        vm.stopPrank();

        vm.startPrank(user2);
        mockToken.approve(address(LFJRouter), SWAP_AMOUNT);
        IArenaRouter02(LFJRouter).swapExactTokensForAVAX(
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
        IArenaRouter02(ArenaRouter).swapExactAVAXForTokens{value: amountIn}(
            0, // Accept any amount of tokens
            path,
            user1,
            block.timestamp + 3600
        );
        vm.stopPrank();

        vm.startPrank(user2);
        IArenaRouter02(LFJRouter).swapExactAVAXForTokens{value: amountIn}(
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