// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// lib/openzeppelin-contracts/contracts/utils/Address.sol

import {Address} from "@openzeppelin-latest/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin-latest/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin-latest/contracts/token/ERC20/ERC20.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

/**
 * @title A sample schema resolver that pays attesters (and expects the payment to be returned during revocations)
 */
contract TaskDoneResolver is SchemaResolver, ERC20 {
    using Address for address payable;

    error InvalidValue();

    address private immutable i_meritToken;

    constructor(IEAS eas, uint256 incentive)
        SchemaResolver(eas)
        ERC20("Merit", "MERIT")
    {
        i_meritToken = incentive;
    }

    /*
     *   For Merit Token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        revert("Merit is not transferable");
    }

    /*
     *   For SchemaResolver
     */
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

        // task data: name, description, weight
        (, , uint256 weight) = abi.decode(
            attestation.data,
            (string, string, uint256)
        );

        _mint(attestation.attester, weight);

        return true;
    }

    function onRevoke(
        Attestation calldata, /*attestation*/
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function getMeritTokenAddress() public view returns (address) {
        return i_meritToken;
    }
}
