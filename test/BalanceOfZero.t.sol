// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
}

contract BalanceOfZeroTest is Test {
    Token token;

    function setUp() public {
        token = new Token();
    }

    function testBalanceOfZeroAddressReverts() public {
        vm.expectRevert();
        token.balanceOf(address(0));
    }
}
