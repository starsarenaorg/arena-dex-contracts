## Arena Dex implementation
This fork routes the swap fees back to a treasury address.
1. Router02 works just as is and calculates the amounts as if there is a 0.3 % fee.
2. The excess amount normally stay in the Pair contract and go to liquidity providers
3. Instead of leaving them in the contract, we calculate the amount of fees and send them to a treasury address. 
4. The liquidity constant check is modified to handle the sent fees but it still ensures k_new > k_old. 

This means liquidity providers wont get any fees. We acknowledge and accept the fact that this will lead to most probs noone deploying any liquidity but the protocol. 


The only modification is to the JoePair contract under `src/libraries/JoePair.sol` where the fees are sent instead of being left in the contract. The original can also be found under  `src/libraries/JoePairOriginal.sol` for ease of comparison.