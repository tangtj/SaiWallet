// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


interface IOperator {
    function whitelist(address, address) external view returns (bool);
}

contract Wallet is Initializable, IERC721Receiver {
    address public owner;
    address public factory;

    mapping(address => bool) public whitelist;

    function initialize(address _owner) public initializer {
        owner = _owner;
        factory = msg.sender;
        // owner address
        whitelist[_owner] = true;
        // factory address
        whitelist[factory] = true;
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
        uint256 balance = address(this).balance;
        if (balance > 0) {
            receiver.transfer(balance);
        }
    }

    function withdrawToken(address receiver, address token) public checkCaller {
        IERC20 _t = IERC20(token);
        uint256 balance = _t.balanceOf(address(this));
        if (balance > 0) {
            _t.transfer(receiver, balance);
        }
    }

    receive() external payable {}

    modifier checkCaller() {
        require(
            tx.origin == owner && IOperator(factory).whitelist(tx.origin, msg.sender),
            "caller not allow"
        );
        _;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
} 