// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Internals} from "./helpers/ERC20Internals.sol";
import {IERC20Errors} from "./helpers/IERC20Errors.sol";

contract ERC20 is IERC20Errors, ERC20Internals {
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return totalSupply_();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return _balanceOf(owner);
    }

    function transfer(address to, uint256 value) public virtual returns (bool success) {
        success = _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool success) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        success = _transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public virtual returns (bool success) {
        address owner = msg.sender;
        success = _approve(owner, spender, value);
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowance(owner, spender);
    }
}
