// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Common.sol";
import "../../interfaces/IHack0x.sol";
import {SkillAttester} from "./SkillAttester.sol";
import {TaskAttester} from "./TaskAttester.sol";
import {ProjectAttester} from "./ProjectAttester.sol";

contract Attester is SkillAttester, TaskAttester, ProjectAttester {
    address s_hackContract;
    IEAS private immutable i_eas;
    mapping(address => bool) private s_Authorized;

    error Attester__HackContractNotDefined();
    error Attester__InvalidHackContract();
    error Attester__NotDaoUser();
    error Attester__InvalidEAS();
    error Attester__NotAuthorized();

    modifier onlyAuthorized() {
        if (s_Authorized[msg.sender] != true) {
            revert Attester__NotAuthorized();
        }
        _;
    }

    modifier onlyUser() {
        if (s_hackContract == address(0)) {
            revert Attester__HackContractNotDefined();
        }

        if (IHack0x(s_hackContract).isUserInDao(msg.sender) == false) {
            revert Attester__NotDaoUser();
        }

        _;
    }

    constructor(
        address _eas,
        address _authorized,
        bytes32 _attestSkillSchema,
        bytes32 _endorseSkillSchema,
        bytes32 _attestTaskSchema,
        bytes32 _doneTaskSkillSchema,
        bytes32 _projectCreationSchema
    )
        SkillAttester(_attestSkillSchema, _endorseSkillSchema)
        TaskAttester(_attestTaskSchema, _doneTaskSkillSchema)
        ProjectAttester(_projectCreationSchema)
    {
        if (address(_eas) == address(0)) {
            revert Attester__InvalidEAS();
        }

        i_eas = IEAS(_eas);
        s_Authorized[_authorized] = true;
    }

    function setHack0xContract(address _hackContract) public onlyAuthorized {
        if (_hackContract == address(0)) {
            revert Attester__InvalidHackContract();
        }

        s_hackContract = _hackContract;
    }

    function addAuthorized(address _authorized) public onlyAuthorized {
        s_Authorized[_authorized] = true;
    }

    /*
     *   Setters Functions
     */

    function setAttestSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        _setAttestSkillSchema(_schemaId);
    }

    function setEndorseSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        _setEndorseSkillSchema(_schemaId);
    }

    function setTaskSchema(bytes32 _schemaId) public onlyAuthorized {
        _setTaskSchema(_schemaId);
    }

    function setDoneTaskSkillSchema(bytes32 _schemaId) public onlyAuthorized {
        _setDoneTaskSkillSchema(_schemaId);
    }

    function setProjectCreationSchema(bytes32 _schemaId) public onlyAuthorized {
        _setProjectCreationSchema(_schemaId);
    }

    /*
     *   Attestments Functions
     */
    function attestSkill(address _user, string calldata _skill) public {
        _attestSkill(i_eas, _user, _skill);
    }

    function endorseSkill(
        bytes32 _refUID,
        address _from,
        address _user,
        bool _endorse
    ) public {
        _endorseSkill(i_eas, _refUID, _from, _user, _endorse);
    }

    function attestTask(
        uint256 _projectId,
        uint256 _taskDeadline,
        uint256 _taskWeight,
        string memory _taskTitle,
        string memory _taskDescription
    ) public {
        _attestTask(
            i_eas,
            _projectId,
            _taskDeadline,
            _taskWeight,
            _taskTitle,
            _taskDescription
        );
    }

    function attestDoneTask(
        bytes32 _refUID,
        address _user,
        bool _done
    ) public onlyUser {
        _attestDoneTask(i_eas, _refUID, _user, _done);
    }

    function attestProjectCreation(
        uint _projectId,
        address _creator
    ) public onlyUser {
        _attestProjectCreation(i_eas, _projectId, _creator);
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
