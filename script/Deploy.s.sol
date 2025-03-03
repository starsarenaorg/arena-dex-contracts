pragma solidity 0.6.12;


import "forge-std/Script.sol";
import "../src/JoeFactory.sol";
import "../src/JoeRouter02.sol";
import "../src/interfaces/IJoeFactory.sol";
import "forge-std/console.sol";
contract DexDeployScript is Script {
    function run() external {
        // Retrieve private key from environment variable

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy JoeFactory
        JoeFactory factory = new JoeFactory(msg.sender);    
        factory.setFeeReceiverAddress(msg.sender);
        console.log("JoeFactory deployed at:", address(factory));
        console.logBytes32((factory.pairCodeHash()));
        // Deploy JoeRouter02 with factory address and WETH address
        address WETH_ADDRESS = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // Replace this
        JoeRouter02 router = new JoeRouter02(address(factory), WETH_ADDRESS);
        console.log("JoeRouter02 deployed at:", address(router));

        vm.stopBroadcast();
    }
}