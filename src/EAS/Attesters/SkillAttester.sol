// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";

contract SkillAttester {
    bytes32 private s_attestSkillSchema;
    bytes32 private s_endorseSkillSchema;

    constructor(bytes32 _attestSkillSchema, bytes32 _endorseSkillSchema) {
        s_attestSkillSchema = _attestSkillSchema;
        s_endorseSkillSchema = _endorseSkillSchema;
    }

    function _setAttestSkillSchema(bytes32 _schemaId) public virtual {
        s_attestSkillSchema = _schemaId;
    }

    function _setEndorseSkillSchema(bytes32 _schemaId) public virtual {
        s_endorseSkillSchema = _schemaId;
    }

    function _attestSkill(IEAS eas, address _user, string memory _skill) internal returns (bytes32) {
        return eas.attest(
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

    function _endorseSkill(IEAS eas, bytes32 _refUID, address _from, address _user, bool _endorse)
        internal
        returns (bytes32)
    {
        return eas.attest(
            AttestationRequest({
                schema: s_endorseSkillSchema, //endore schema
                data: AttestationRequestData({
                    recipient: _user,
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: true,
                    refUID: _refUID,
                    data: abi.encode(_from, _endorse),
                    value: 0 // No value/ETH
                })
            })
        );
    }

    /*
     *    Getter Functions
     */

    function getAttestSkillSchema() public view returns (bytes32) {
        return s_attestSkillSchema;
    }

    function getEndorseSkillSchema() public view returns (bytes32) {
        return s_endorseSkillSchema;
    }
}
