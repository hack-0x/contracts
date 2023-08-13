// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";

contract ProjectAttester {
    bytes32 private s_projectCreationSchema;

    constructor(bytes32 _projectCreationSchema) {
        s_projectCreationSchema = _projectCreationSchema;
    }

    function _setProjectCreationSchema(bytes32 _schemaId) internal {
        s_projectCreationSchema = _schemaId;
    }

    function _attestProjectCreation(IEAS eas, address _creator, uint256 _projectId) internal returns (bytes32) {
        return eas.attest(
            AttestationRequest({
                schema: s_projectCreationSchema, // attest skill schema
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: true,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(_creator, _projectId),
                    value: 0 // No value/ETH
                })
            })
        );
    }

    /*
     *    Getter Functions
     */

    function getProjectCreatedSchema() public view returns (bytes32) {
        return s_projectCreationSchema;
    }
}
