// SPDX-License-Identifier: MIT 
pragma solidity 0.8.21;

import "./Hack0xMerit.sol";

contract Hack0xDAOPrizePool {
    Hack0xMerit public immutable merit;

    constructor(address _merit) {
        merit = Hack0xMerit(_merit);
    }

    

    receive() external payable {}
}