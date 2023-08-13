// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin-latest/contracts/access/IAccessControl.sol";
import "@openzeppelin-latest/contracts/token/ERC20/IERC20.sol";

interface IHack0xMerit is IAccessControl, IERC20 {
    function mint(address to, uint256 amount) external;
}
