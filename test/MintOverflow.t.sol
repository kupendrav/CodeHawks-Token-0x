// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
}

contract MintOverflowTest is Test {
    Token token;
    address user = address(0x123);

    function setUp() public {
        token = new Token();
    }

    function testTotalSupplyOverflow() public {
        // Mint near-maximum to user
        uint256 nearMax = type(uint256).max - 10;
        token.mint(user, nearMax);
        assertEq(token.totalSupply(), nearMax);
        assertEq(token.balanceOf(user), nearMax);

        // Mint more to overflow totalSupply and balance
        token.mint(user, 20);
        // Expected wrap: nearMax + 20 = (2^256 - 10) + 20 -> 9 mod 2^256
        assertEq(token.totalSupply(), 9);
        assertEq(token.balanceOf(user), 9);
    }
}
