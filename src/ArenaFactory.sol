// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./interfaces/IArenaFactory.sol";
import "./ArenaPair.sol";

contract ArenaFactory is IArenaFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;
    ProtocolFeeInfo public protocolFeeInfo;

    struct ProtocolFeeInfo {
        address protocolFeeReceiverAddress;
        // this value represents the percentage of the standard 0.3% fee is taken by the protocol. 10000 = 100%
        uint96 protocolFeePercentageInBps;
    }

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event ProtocolFeeInfoSet(address indexed feeReceiverAddress, uint96 feePercentageInBps, uint96 previousFeePercentageInBps);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(ArenaPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "Arena: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Arena: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Arena: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(ArenaPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ArenaPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Arena: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setProtocolFeeInfo(address _feeReceiverAddress, uint96 _feePercentageInBps) external override {
        require(_feePercentageInBps <= 10000, "Arena: INVALID_FEE_PERCENTAGE");
        require(msg.sender == feeToSetter, "Arena: FORBIDDEN");
        require(_feeReceiverAddress != address(0), "Arena: INVALID_FEE_RECEIVER_ADDRESS");
        uint96 previousFeePercentageInBps = protocolFeeInfo.protocolFeePercentageInBps;
        protocolFeeInfo = ProtocolFeeInfo({
            protocolFeeReceiverAddress: _feeReceiverAddress,
            protocolFeePercentageInBps: _feePercentageInBps
        });
        emit ProtocolFeeInfoSet(_feeReceiverAddress, _feePercentageInBps, previousFeePercentageInBps);
    }

    function getProtocolFeeInfo() external view override returns (address, uint96) {
        return (protocolFeeInfo.protocolFeeReceiverAddress, protocolFeeInfo.protocolFeePercentageInBps);
    }


    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, "Arena: FORBIDDEN");
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Arena: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
