pragma solidity 0.6.12;


import "forge-std/Script.sol";
import "../src/ArenaFactory.sol";
import "../src/ArenaRouter02.sol";
import "../src/interfaces/IArenaFactory.sol";
import "forge-std/console.sol";
contract DexDeployScript is Script {
    function run() external {
        // Retrieve private key from environment variable

        // Start broadcasting transactions
        vm.startBroadcast();
        // Deploy JoeFactory
        ArenaFactory factory = new ArenaFactory(msg.sender);
        factory.setProtocolFeeInfo(msg.sender, 100);
        console.log("ArenaFactory deployed at:", address(factory));
        console.logBytes32((factory.pairCodeHash()));
        // Deploy JoeRouter02 with factory address and WETH address
        address WETH_ADDRESS = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // Replace this
        ArenaRouter02 router = new ArenaRouter02(address(factory), WETH_ADDRESS);
        console.log("ArenaRouter02 deployed at:", address(router));
        console.log("msg.sender", msg.sender);

        vm.stopBroadcast();
    }
}