
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/interfaces/IJoePair.sol";

library JoeLib820 {
        // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(
            keccak256(
                abi.encodePacked(
                    hex"ff",
                    factory,
                    keccak256(abi.encodePacked(token0, token1)),
                    hex"d55a95fec910e205ad96585c51c964169dcfd7782588eeb192737033c18e343a" // init code fuji
                )
            )
        )));
    }

       // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

}