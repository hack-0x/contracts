// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {IEAS, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "@eas/contracts/Common.sol";

contract Attester {
    // The address of the global EAS contract.

    bytes32 private s_attestSkillSchema;
    bytes32 private s_endorseSkillSchema;
    IEAS private immutable s_eas;
    mapping(address => bool) private s_Authorized;

    error Attester__InvalidEAS();
    error Attester__NotAuthorized();

    modifier onlyAuthorized() {
        if (s_Authorized[msg.sender] != true) {
            revert Attester__NotAuthorized();
        }
        _;
    }

    function setAttestSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        s_attestSkillSchema = _schemaId;
    }

    function setEndorseSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        s_endorseSkillSchema = _schemaId;
    }

    constructor(address _eas) {
        if (address(_eas) == address(0)) {
            revert Attester__InvalidEAS();
        }

        s_eas = IEAS(_eas);
        s_Authorized[msg.sender] = true;
    }

    function endorseSkill(
        bytes32 _refUID,
        address _user,
        bool _endorse
    ) internal returns (bytes32) {
        return
            s_eas.attest(
                AttestationRequest({
                    schema: s_endorseSkillSchema, //endore schema
                    data: AttestationRequestData({
                        recipient: _user,
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: _refUID,
                        data: abi.encode(_endorse),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    function attestSkill(
        address _user,
        string memory _skill
    ) internal returns (bytes32) {
        return
            s_eas.attest(
                AttestationRequest({
                    schema: s_attestSkillSchema, // attest skill schema
                    data: AttestationRequestData({
                        recipient: _user, // No recipient
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: EMPTY_UID, // No references UI
                        data: abi.encode(_skill),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    function isAuthorized(address _user) public returns (bool isAuthorized) {
        return s_Authorized[_user];
    }
}
