//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

contract UserRegistry {
    /// @notice User information
    /// @dev User information lives in EAS
    struct UserInfo {
        bool isUser;
        string profilePhoto;
        string name;
        string description;
        string[] skills; // atestations
    }

    mapping(address => UserInfo) private s_UserInformation;
    mapping(address => bool) private s_Admin;

    error UserRegistry__NotAdmin();
    error UserRegistry__NotUser();

    // Users may be SafeMultisig Wallets with a custom module of our own to
    // pay ourselfs the transactions

    modifier onlyUser() {
        if (isUser(msg.sender) != true) {
            revert UserRegistry__NotUser();
        }
        _;
    }

    modifier onlyAdmin() {
        if (s_Admin[msg.sender] != true) {
            revert UserRegistry__NotAdmin();
        }
        _;
    }

    constructor(address _admin) {
        s_Admin[_admin] = true;
        s_Admin[msg.sender] = true;
    }

    /*
     *   Only Admin Functions
     */
    function addAdmin(address _admin) public onlyAdmin {
        s_Admin[_admin] = true;
    }

    function addUser(address _user) public onlyAdmin {
        s_UserInformation[_user].isUser = true;
    }

    /*
     *   Getter and helper Functions
     */

    /// @notice Checks if address is user in DAO
    /// @param _user address
    /// @return boolean
    function isUser(address _user) public view returns (bool) {
        return s_UserInformation[_user].isUser;
    }

    /// @notice Gets information about User
    /// @dev returns UID of EAS attestations
    /// @param _user address
    /// @return Info about the user
    function getUserInfo(
        address _user
    ) external view returns (UserInfo memory) {
        return s_UserInformation[_user];
    }

    function isAdmin(address _user) external view returns (bool) {
        return s_Admin[_user];
    }
}
