// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IUserRegistry {
    struct UserInfo {
        bool isUser;
        string name;
        string description;
        string[] skills;
    }

    /// @notice Checks if address is user in DAO
    /// @param user address
    /// @return boolean
    function isUser(address user) external view returns (bool);

    /// @notice Gets information about User
    /// @dev returns UID of EAS attestations
    /// @param user address
    /// @return Info about the user
    function getUserInfo(address user) external view returns (UserInfo memory);
}
