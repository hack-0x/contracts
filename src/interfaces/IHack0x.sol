// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

interface IHack0x {
    function isUserInDao(address) external view returns (bool);
}
