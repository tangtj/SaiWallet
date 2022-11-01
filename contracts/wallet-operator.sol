// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./wallet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WalletOperator is Ownable {

    uint256 public fee;

    uint256 public deployCount;

    mapping(address => address[]) wallets;
    mapping(address => mapping(address => bool)) public whitelist;

    struct CallOpt {
        uint256 perValue;

        // 0 pass 
        // 1 revert 
        // 2 finish
        uint256 failedCase;
    }

    // manager method

    function withdraw(address payable receiver, uint256 amount) public onlyOwner {
        receiver.transfer(amount);
    }

    function withdrawToken(address receiver, IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(receiver, amount);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    // user call method

    function create(uint256 num) public {
        if (num <= 0) {
            return;
        }

        address caller = msg.sender;
        address[] storage wallet = wallets[caller];
        uint256 count = num;
        if (wallet.length <= 0) {
            wallet.push(address(new Wallet(caller, address(this))));
            count -= 1;
        }
        for (uint256 i = 0; i < count; i++) {
            wallet.push(Clones.clone(address(wallet[0])));
        }
        deployCount += num;

        whitelist[caller][caller] = true;
        whitelist[caller][address(this)] = true;
    }


    function invokeBatch(address target, bytes calldata callData, CallOpt calldata opt, address[] calldata addrs) public payable {
        _invoke(target, callData, opt, addrs);
    }

    function invokeAll(address target, bytes calldata callData, CallOpt calldata opt) public payable {
        address[] memory addrs = wallets[msg.sender];
        _invoke(target, callData, opt, addrs);
    }

    function withdrawAll(address payable receiver) public {
        address[] memory addrs = wallets[msg.sender];
        _withdraw(receiver, addrs);
    }

    function withdrawBatch(address payable receiver, address[] calldata addrs) public {
        _withdraw(receiver, addrs);
    }

    function withdrawTokenAll(address payable receiver, IERC20 token) public {
        address [] memory addrs = wallets[msg.sender];
        _withdrawToken(receiver, token, addrs);
    }

    function _invoke(address target, bytes calldata callData, CallOpt calldata opt, address[] memory addrs) internal {
        uint256 size = addrs.length;
        require(size * opt.perValue + fee >= msg.value, "Insufficient amount to pay");

        for (uint256 i = 0; i < size; i++) {
            bool success = Wallet(payable(addrs[i])).invoke{value : opt.perValue}(target, callData);
            if (success == false) {
                if (opt.failedCase == 1) {
                    revert("failed revert tx");
                } else if (opt.failedCase == 2) {
                    return;
                }
            }
        }
    }

    function withdrawTokenBatch(address payable receiver, IERC20 token, address[] calldata addrs) public {
        _withdrawToken(receiver, token, addrs);
    }

    function _withdraw(address payable receiver, address[] memory addrs) internal {
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            if (address(addrs[i]).balance > 0) {
                Wallet(payable(addrs[i])).withdraw(receiver);
            }
        }
    }

    function _withdrawToken(address payable receiver, IERC20 token, address[] memory addrs) internal {
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            if (token.balanceOf(addrs[i]) > 0) {
                Wallet(payable(addrs[i])).withdrawToken(receiver, token);
            }
        }
    }

    function changeWhitelist(address[] calldata addrs, bool status) public {
        mapping(address => bool) storage list = whitelist[msg.sender];
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            if (status) {
                list[addrs[i]] = true;
            } else {
                delete list[addrs[i]];
            }
        }
    }

    // view method

    function userWalletCount(address caller) public view returns (uint256){
        return wallets[caller].length;
    }

    function userWallet(address caller) public view returns (address[] memory){
        return wallets[caller];
    }
}