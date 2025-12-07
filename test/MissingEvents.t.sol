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

contract MissingEventsTest is Test {
    Token token;
    address user = address(0x1);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        token = new Token();
    }

    function testMintEmitsTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 100);
        token.mint(user, 100);
    }

    function testBurnEmitsTransfer() public {
        token.mint(user, 100);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(0), 50);
        token.burn(user, 50);
    }
}
