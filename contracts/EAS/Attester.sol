// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {IEAS, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "@eas/contracts/Common.sol";

contract Attester {
    // The address of the global EAS contract.
    IEAS private immutable s_eas;

    error InvalidEAS();

    constructor(IEAS eas) {
        if (address(eas) == address(0)) {
            revert InvalidEAS();
        }

        s_eas = eas;
    }

    function endorseSkill(
        bytes32 schema,
        bytes32 refUID,
        address user,
        bool endorse
    ) internal returns (bytes32) {
        return
            s_eas.attest(
                AttestationRequest({
                    schema: schema, //endore schema
                    data: AttestationRequestData({
                        recipient: user,
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: refUID,
                        data: abi.encode(endorse),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    function attestSkill(
        bytes32 schema,
        string memory input
    ) internal returns (bytes32) {
        return
            s_eas.attest(
                AttestationRequest({
                    schema: schema,
                    data: AttestationRequestData({
                        recipient: address(0), // No recipient
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: EMPTY_UID, // No references UI
                        data: abi.encode(input),
                        value: 0 // No value/ETH
                    })
                })
            );
    }
}
