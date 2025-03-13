## Arena Dex implementation
This fork routes the swap fees back to a treasury address.
1. Router02 works just as is and calculates the amounts as if there is a 0.3 % fee.
2. The excess amount normally stay in the Pair contract and go to liquidity providers
3. Instead of leaving them in the contract, we calculate the amount of fees and send them to a treasury address. 
4. The liquidity constant check is modified to handle the sent fees but it still ensures k_new > k_old. 

This means liquidity providers wont get any fees.


The only modification is to the JoePair contract under `src/libraries/JoePair.sol` where the fees are sent instead of being left in the contract. The original can also be found under  `src/libraries/JoePairOriginal.sol` for ease of comparison.

Deployment : 
```
forge script DexDeployScript  --rpc-url avalanche  -vvvvv --etherscan-api-key avalanche --private-key XX  --broadcast --verify
````

Avalanche deployments:


* JoeFactory deployed at: 0x231DF4D421f1F9e0AAe9bA3634a87EBC87A09c39
* Bytecode  0x5eae27f407e5d417db3b2c176a2221883934aa8eecf365f8795afb69ee0b23d1
* JoeRouter02 deployed at: 0x3a6F16E3639e83a085812288D16DE9883E649D1D