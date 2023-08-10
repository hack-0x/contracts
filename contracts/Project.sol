// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IUserRegistry.sol";

contract Project {
    address private owner;
    IUserRegistry private userContract;
    address[] private teamMembers;

    // Add merit for team members, and modular functionality for changing merit

    bool public prueba = true;

    mapping(address => bool) private managers;

    error NotOwner();
    error NotDaoUser();

    modifier onlyUser(address user) {
        IUserRegistry(user).isUser(user);
        _;
    }

    // modifier onlyOwner {
    //     if (msg.sender != owner) {
    //         revert NotOwner();
    //     }
    //     _;
    // }

    // modifier onlyManagers {
    //     if (msg.sender )
    //     _;
    // }

    constructor(address _owner, address _userContract) {
        owner = _owner;
        userContract = IUserRegistry(_userContract);
    }
}
