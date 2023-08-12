// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Common.sol";

/*
 *   Task Attestation Data Structure
 *
 *    data: abi.encode(
 *        _projectId,
 *        _taskTitle,
 *        _taskDescription,
 *        _taskDeadline,
 *        _taskWeight
 *    ),
 *
 *        uint256 _projectId,
 *        uint256 _taskDeadline,
 *        uint256 _taskWeight,
 *        string memory _taskTitle,
 *        string memory _taskDescription
 */

/**
 * @title A sample schema resolver that pays attesters (and expects the payment to be returned during revocations)
 */
contract TaskDoneResolver is SchemaResolver {
    using Address for address payable;

    IERC20 private immutable i_meritToken;
    IEAS private immutable i_eas;

    constructor(IEAS _eas, address _meritToken) SchemaResolver(_eas) {
        i_eas = _eas;
        i_meritToken = IERC20(_meritToken);
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 value
    ) internal override returns (bool) {
        if (value > 0) {
            return false;
        }

        // tasks attestation
        Attestation memory refAttestation = i_eas.getAttestation(
            attestation.refUID
        );

        (, , uint256 weight, , ) = abi.decode(
            refAttestation.data,
            (uint256, uint256, uint256, string, string)
        );

        // i_meritToken.mint(attestation.recipient, weight);

        return true;
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        // i_meritToken.burn(attestation.recipient, weight);

        return true;
    }

    function getMeritTokenAddress() public view returns (address) {
        return i_meritToken;
    }
}
