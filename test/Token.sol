// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "../src/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {}

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }

    function burn(address account, uint256 value) public {
        _burn(account, value);
    }
}
