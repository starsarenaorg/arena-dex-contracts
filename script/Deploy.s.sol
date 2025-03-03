pragma solidity 0.6.12;


import "forge-std/Script.sol";
import "../src/JoeFactory.sol";
import "../src/JoeRouter02.sol";
import "../src/interfaces/IJoeFactory.sol";

contract DeployScript is Script {
    function run() external {
        // Retrieve private key from environment variable

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy JoeFactory
        JoeFactory factory = new JoeFactory(msg.sender);
        factory.setFeeReceiverAddress(msg.sender);
        console.log("JoeFactory deployed at:", address(factory));
        factory.pairCodeHash();

        // Deploy JoeRouter02 with factory address and WETH address
        address WETH_ADDRESS = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c; // Replace this
        JoeRouter02 router = new JoeRouter02(address(factory), WETH_ADDRESS);
        console.log("JoeRouter02 deployed at:", address(router));

        vm.stopBroadcast();
    }
}