// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-latest/contracts/access/AccessControl.sol";
import "@openzeppelin-latest/contracts/token/ERC20/ERC20.sol";

contract Hack0xMerit is ERC20, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");

    constructor() ERC20("Merit", "MERIT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER) {
        _mint(to, amount);
    }

    function addMinter(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER, to);
    }

    function _transfer(address, /*from*/ address, /*to*/ uint256 /*value*/ ) internal pure override {
        revert("Merit is not transferable");
    }
}
