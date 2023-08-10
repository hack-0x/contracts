// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {Project, ProjectData} from "./Project.sol";
import "./interfaces/IUserRegistry.sol";

contract ProjectFactory {
    event ProjectCreated(address indexed project, address owner);

    error ProjectFactory__NotDaoUser();

    function createProject(ProjectData memory _projectData) public {
        if (isUser(msg.sender) != true) {
            revert ProjectFactory__NotDaoUser();
        }

        /// @dev the constructor of Project needs to be passed two arguments:
        /// @param _owner the address of the owner of the project
        /// @param _projectData the data of the project
        Project project = new Project(msg.sender, _projectData);

        emit ProjectCreated(address(project), msg.sender);

        // return address(project);
    }

    function isUser(address _user) public view returns (bool) {
        return IUserRegistry(_user).isUser(_user);
    }
}
