// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Token} from "./Token.sol";
import {IERC20Errors} from "../src/ERC20.sol";

contract TokenTest is Test {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    Token public token;

    function setUp() public {
        token = new Token();
    }

    function test_metadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    function test_mint() public {
        uint256 amount = 100e18;
        address account = makeAddr("account");
        token.mint(account, amount);

        uint256 balance = token.balanceOf(account);
        assertEq(balance, amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_burn() public {
        uint256 amount = 100e18;
        address account = makeAddr("account");
        token.mint(account, amount);

        uint256 balance = token.balanceOf(account);
        assertEq(balance, amount);
        assertEq(token.totalSupply(), amount);

        token.burn(account, amount);
        balance = token.balanceOf(account);
        assertEq(balance, 0);
        assertEq(token.totalSupply(), 0);
    }

    function test_transfer() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);
        uint256 balanceSender = token.balanceOf(account);
        assertEq(balanceSender, 100e18);

        address receiver = makeAddr("receiver");

        vm.prank(account);
        vm.expectEmit(true, true, false, true);
        emit Transfer(account, receiver, 50e18);
        token.transfer(receiver, 50e18);

        balanceSender = token.balanceOf(account);
        uint256 balanceReceiver = token.balanceOf(receiver);
        assertEq(balanceSender, 50e18);
        assertEq(balanceReceiver, 50e18);
    }

    function test_allowance() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);
        uint256 balanceSender = token.balanceOf(account);
        assertEq(balanceSender, 100e18);

        address spender = makeAddr("spender");

        vm.prank(account);
        vm.expectEmit(true, true, false, true);
        emit Approval(account, spender, 50e18);
        token.approve(spender, 50e18);
        uint256 allowance = token.allowance(account, spender);
        assertEq(allowance, 50e18);
    }

    function test_transferFrom() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);

        address spender = makeAddr("spender");
        address to = makeAddr("to");

        vm.prank(account);
        token.approve(spender, 50e18);
        uint256 allowanceSpender = token.allowance(account, spender);
        assertEq(allowanceSpender, 50e18);

        vm.prank(spender);
        token.transferFrom(account, to, 50e18);

        allowanceSpender = token.allowance(account, spender);
        assertEq(allowanceSpender, 0);

        assertEq(token.balanceOf(account), 50e18);
        assertEq(token.balanceOf(to), 50e18);
    }

    function test_transferRevert() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);
        uint256 balanceSender = token.balanceOf(account);
        assertEq(balanceSender, 100e18);

        address receiver = makeAddr("receiver");

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        vm.prank(account);
        token.transfer(address(0), 50e18);
    }

    function test_transferRevert2() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);
        uint256 balanceSender = token.balanceOf(account);
        assertEq(balanceSender, 100e18);

        address receiver = makeAddr("receiver");

        vm.prank(account);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, account, 100e18, 101e18));
        token.transfer(receiver, 101e18);
    }

    function test_spendallowanceRevert() public {
        address account = makeAddr("account");
        token.mint(account, 100e18);

        address spender = makeAddr("spender");
        address to = makeAddr("to");

        vm.prank(account);
        token.approve(spender, 50e18);
        uint256 allowanceSpender = token.allowance(account, spender);
        assertEq(allowanceSpender, 50e18);

        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, 50e18, 51e18));
        token.transferFrom(account, to, 51e18);
    }

    function test_mintRevert() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(address(0), 50e18);
    }

    function test_burnRevert() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0)));
        token.burn(address(0), 50e18);
    }

    function test_approveRevert() public {
        address account = makeAddr("account");

        vm.prank(account);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 0);
    }
}
