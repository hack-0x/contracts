// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-latest/contracts/access/AccessControl.sol";
import "@openzeppelin-latest/contracts/token/ERC20/ERC20.sol";

contract Hack0xMerit is ERC20, AccessControl {
    constructor() ERC20("Merit", "MERIT") {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function _transfer(address, /*from*/ address, /*to*/ uint256 /*value*/ ) internal pure override {
        revert("Merit is not transferable");
    }
}
