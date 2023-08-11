// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";
import {SkillAttester} from "./SkillAttester.sol";
import {TaskAttester} from "./TaskAttester.sol";

contract Attester is SkillAttester, TaskAttester {
    // The address of the global EAS contract.

    IEAS private immutable i_eas;
    mapping(address => bool) private s_Authorized;

    error Attester__InvalidEAS();
    error Attester__NotAuthorized();

    modifier onlyAuthorized() {
        if (s_Authorized[msg.sender] != true) {
            revert Attester__NotAuthorized();
        }
        _;
    }

    constructor(
        address _eas,
        address _authorized,
        bytes32 _attestSkillSchema,
        bytes32 _endorseSkillSchema,
        bytes32 _attestTaskSchema,
        bytes32 _doneTaskSkillSchema
    )
        SkillAttester(_attestSkillSchema, _endorseSkillSchema)
        TaskAttester(_attestTaskSchema, _doneTaskSkillSchema)
    {
        if (address(_eas) == address(0)) {
            revert Attester__InvalidEAS();
        }

        i_eas = IEAS(_eas);
        s_Authorized[_authorized] = true;
    }

    function setAttestSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        _setAttestSkillSchema(_schemaId);
    }

    function setEndorseSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        _setEndorseSkillSchema(_schemaId);
    }

    function setTaskSchema(bytes32 _schemaId) public onlyAuthorized {
        _setTaskSchema(_schemaId);
    }

    function setDoneTaskSkillSchema(
        bytes32 _schemaId
    ) public override onlyAuthorized {
        _setDoneTaskSkillSchema(_schemaId);
    }

    /*
     *   Getter Functions
     */

    function isAdminAuthorized(
        address _user
    ) public view returns (bool isAuthorized) {
        return s_Authorized[_user];
    }

    function getEAS() public view returns (IEAS) {
        return i_eas;
    }
}
