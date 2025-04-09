## Arena Dex implementation
This is a white label fork of TraderJoe v1 (Uniswawp v2) with small a modiciation : It routes a portion of swap fees to a treasury address.
1. Router02 works just as is and calculates the amounts as if there is a 0.3 % fee.
2. The excess amount normally stay in the Pair contract and go to liquidity providers
3. Instead of leaving them in the contract, we calculate the amount of fees and send a percentage of them to a treasury address. 
4. The liquidity constant check is not modified and accounts for the correct amount of fees. 

This means liquidity providers wont get the full fees but a portion of them, depending on the fee percentage set by the protocol.

### Modifications: 
1. `src/ArenaPair.sol`
The swap function is modified to send a portion of the fees to a treasury address. The treasry address and the fee percentage is queried from the factory contract. You can see the original swap implementation down below for comparison.

```
// Original TraderJoe implementation : Can be found at 
// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/traderjoe/JoePair.sol

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, "Joe: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Joe: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Joe: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IJoeCallee(to).joeCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20Joe(_token0).balanceOf(address(this));
            balance1 = IERC20Joe(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Joe: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000**2), "Joe: K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

```

2. `src/ArenaFactory`
There is a new struct variable and its respective getters and setters for the fee recepient and the fee percentage.

### Deployment : 
```
forge script DexDeployScript  --rpc-url avalanche  -vvvvv --etherscan-api-key avalanche --private-key XX  --broadcast --verify
```

### Tests :
```
forge test --match-contract DexComparison -vvvvv --rpc-url avalanche --etherscan-api-key avalanche --gas-report --match-test testBuySellFuzzWithFees
```

Avalanche deployments:


* ArenaFactory deployed at: 0x1fDF56D7F502DA9722de1085160cF3b3C1b6FB96
* Bytecode  0x99b528e3c2a22a7928be13515cdf8fb5e787e483233ec6ec75592a51c01a67d4
* JoeRouter02 deployed at: 0x84e6964314188f2A1eb58Aa2B4c454CC8AdeA716
