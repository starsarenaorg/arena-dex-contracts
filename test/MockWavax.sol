/*
pragma solidity >=0.6.2;
import {SimpleERC20} from  "./MockERC20.sol";


interface IWAVAX {
    function deposit() external payable;

    function withdraw(uint256) external;
}


contract MockWAVAX is SimpleERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() SimpleERC20("Wrapped AVAX", "WAVAX") public {}


    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "WAVAX: withdraw amount exceeds balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    receive() external payable {
        deposit();
    }
}

*/