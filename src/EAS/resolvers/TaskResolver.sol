// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// lib/openzeppelin-contracts/contracts/utils/Address.sol

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

/**
 * @title A sample schema resolver that pays attesters (and expects the payment to be returned during revocations)
 */
contract TaskResolver is SchemaResolver, Ownable {
    using Address for address payable;

    error InvalidValue();

    uint256 private immutable s_meritToken;

    constructor(IEAS eas, uint256 incentive) SchemaResolver(eas) {
        s_meritToken = incentive;
    }

    function isPayable() public pure override returns (bool) {
        return true;
    }

    function onAttest(Attestation calldata attestation, uint256 value)
        internal
        override
        returns (bool)
    {
        if (value > 0) {
            return false;
        }

        return true;
    }

    function onRevoke(
        Attestation calldata, /*attestation*/
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function setMeritToken(address _meritToken) public onlyOwner {
        i_meritToken = _meritToken;
    }

    function getMeritTokenAddress() public view returns (address) {
        return i_meritToken;
    }
}
