// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./wallet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract WalletOperator {

    uint256 public deployCount;

    address public immutable clone;

    mapping(address => Wallet[]) wallets;
    mapping(address => mapping(address => bool)) public whitelist;

    struct CallOpt {
        uint256 perValue;
        bool failedRevert;
    }

    constructor(address _clone){
        clone = _clone;
    }


    function create(uint256 num) public {
        address caller = msg.sender;
        Wallet[] storage wallet = wallets[caller];
        for (uint256 i = 0; i < num; i++) {
            wallet.push(Wallet(payable(Clones.clone(clone))));
        }
        deployCount += num;

    }


    function invokeBatch(address target, bytes calldata callData, CallOpt calldata opt, address[] calldata addrs) public payable {
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            bool success = Wallet(payable(addrs[i])).invoke{value : opt.perValue}(target, callData);
            if (opt.failedRevert) {
                require(success, "exec failure revert tx");
            }
        }
    }

    function invokeAll(address target, bytes memory callData, CallOpt calldata opt) public {
        Wallet[] memory addrs = wallets[msg.sender];
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            bool success = addrs[i].invoke{value : opt.perValue}(target, callData);
            if (opt.failedRevert) {
                require(success, "exec failure revert tx");
            }
        }
    }

    function withdrawAll(address payable receiver) public {
        Wallet[] memory addrs = wallets[msg.sender];
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            addrs[i].withdraw(receiver);
        }
    }

    function withdrawBatch(address payable receiver, address[] calldata addrs) public {
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            Wallet(payable(addrs[i])).withdraw(receiver);
        }
    }

    function withdrawTokenAll(address receiver, address token) public {
        Wallet[] memory addrs = wallets[msg.sender];
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            addrs[i].withdrawToken(receiver, token);
        }
    }

    function withdrawTokenBatch(address payable receiver, address token, address[] calldata addrs) public {
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            Wallet(payable(addrs[i])).withdrawToken(receiver, token);
        }
    }

    function changeWhitelist(address[] calldata addrs, bool status) public {
        mapping(address => bool) storage list = whitelist[msg.sender];
        uint256 size = addrs.length;
        for (uint256 i = 0; i < size; i++) {
            if (status) {
                if (list[addrs[i]] == false) {
                    list[addrs[i]] = true;
                }
            } else {
                delete list[addrs[i]];
            }
        }
    }

    function userWalletCount(address caller) public view returns (uint256){
        return wallets[caller].length;
    }

    function userWallet(address caller) public view returns (Wallet[] memory){
        return wallets[caller];
    }
} 