// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";

contract TaskAttester {
    bytes32 private s_taskSchema;
    bytes32 private s_doneTaskSkillSchema;

    constructor(bytes32 _taskSchema, bytes32 _doneTaskSkillSchema) {
        s_taskSchema = _taskSchema;
        s_doneTaskSkillSchema = _doneTaskSkillSchema;
    }

    function _setTaskSchema(bytes32 _schemaId) internal {
        s_taskSchema = _schemaId;
    }

    function _setDoneTaskSkillSchema(bytes32 _schemaId) internal {
        s_doneTaskSkillSchema = _schemaId;
    }

    function _attestTask(
        IEAS eas,
        uint256 _projectId,
        uint256 _taskDeadline,
        uint256 _taskWeight,
        string memory _taskTitle,
        string memory _taskDescription
    ) internal returns (bytes32) {
        return
            eas.attest(
                AttestationRequest({
                    schema: s_taskSchema, // attest skill schema
                    data: AttestationRequestData({
                        recipient: address(0), // No recipient
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: EMPTY_UID, // No references UI
                        data: abi.encode(
                            _projectId,
                            _taskTitle,
                            _taskDescription,
                            _taskDeadline,
                            _taskWeight
                        ),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    function _attestDoneTask(
        IEAS eas,
        bytes32 _refUID,
        address _user,
        bool _done
    ) internal returns (bytes32) {
        return
            eas.attest(
                AttestationRequest({
                    schema: s_doneTaskSkillSchema, //endore schema
                    data: AttestationRequestData({
                        recipient: address(0),
                        expirationTime: NO_EXPIRATION_TIME, // No expiration time
                        revocable: true,
                        refUID: _refUID,
                        data: abi.encode(_user, _done),
                        value: 0 // No value/ETH
                    })
                })
            );
    }

    /*
     *    Getter Functions
     */

    function getTaskSchema() public view returns (bytes32) {
        return s_taskSchema;
    }

    function getDoneTaskSkillSchema() public view returns (bytes32) {
        return s_doneTaskSkillSchema;
    }
}
