// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOperator {
    function whitelist(address, address) external view returns (bool);
}

contract Wallet {

    address public immutable owner;
    address public immutable factory;

    constructor(address _owner, address _factory){
        owner = _owner;
        factory = _factory;
    }

    function invoke(address addr, bytes calldata data)
    public
    payable
    checkCaller
    returns (bool)
    {
        (bool success,) = addr.call{value : msg.value}(data);
        return success;
    }

    function withdraw(address payable receiver) public payable checkCaller {
        receiver.transfer(address(this).balance);
    }

    function withdrawToken(address receiver, IERC20 token) public checkCaller {
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    receive() external payable {}

    modifier checkCaller() {
        require(
            tx.origin == owner && IOperator(factory).whitelist(tx.origin, msg.sender),
            "caller not allow"
        );
        _;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}