// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";

contract UserAttester {
    bytes32 s_userAttesterSchema;

    constructor(bytes32 _userAtteserSchema) {
        s_userAttesterSchema = _userAtteserSchema;
    }

    function _setUserSchema(bytes32 _schemaId) internal {
        s_userAttesterSchema = _schemaId;
    }

    function _attestUser(
        IEAS eas,
        address _user,
        bool _isUser
    ) internal returns (bytes32) {
        return
            eas.attest(
                AttestationRequest({
                    schema: s_userAttesterSchema, // Attest user schema
                    data: AttestationRequestData({
                        recipient: _user,
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: EMPTY_UID,
                        data: abi.encode(_isUser),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    function getUserAttesterSchema() public view returns (bytes32) {
        return s_userAttesterSchema;
    }
}
