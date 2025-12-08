// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
}

contract MissingApprovalOnSpendTest is Test {
    Token token;
    address owner = address(0xA1);
    address spender = address(0xB2);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        token = new Token();
        token.mint(owner, 100);
        vm.prank(owner);
        token.approve(spender, 60);
    }

    function testTransferFromReducesAllowanceButNoApprovalEvent() public {
        // Expect an Approval event when allowance changes (common practice)
        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, 30); // after spending 30 from 60
        token.transferFrom(owner, address(0xC3), 30);
    }
}
