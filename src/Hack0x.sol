// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "./interfaces/IHack0xMerit.sol";
import "./Hack0xManifesto.sol";
import "./Hack0xDAOPrizePool.sol";
import "./EAS/Attesters/Attester.sol";
import "@openzeppelin-latest/contracts/access/Ownable.sol";
import "@openzeppelin-latest/contracts/security/ReentrancyGuard.sol";

contract Hack0x is Ownable, Attester, ReentrancyGuard {
    enum PrizeDistributionType {
        EQUAL,
        MERIT
    }

    struct UserInfo {
        // roles, skills - offchain
        bool joined;
        uint256[] projects; // array of project ids the user is a part of
        uint256 totalInvested; // total amount invested by user
    }

    struct HackathonInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct Task {
        address taskCreator;
        address taskBuidler;
        address pickedUpBy;
        uint256 taskValue;
        uint256 taskDeadline;
        bool taskCompleted;
        bytes32 easUID;
    }

    struct OnboardingQuest {
        address questCreator;
        address questBuidler;
        uint256 questDeadline;
        bool questCompleted;
    }

    struct ProjectInfo {
        address SAFE;
        uint256 hackathonId;
        PrizeDistributionType prizeDistributionType;
        uint256 predictiveValue;
        uint256 prize;
        uint256 totalInvestment;
        address creator;
        address[] team;
        Task[] tasks;
        bool closed;
        uint256 totalMerits; // total merits earned on project
        mapping(address => uint256) projectMerits; // mapping of creator/buidler address to merits earned on project
        mapping(address => string) joinRequests; // mapping of buidler address to link to their work
        mapping(address => bool) isBuidler;
        mapping(address => uint256) investors; // mapping of investor address to amount invested
    }

    Hack0xMerit public immutable merit;
    Hack0xManifesto public immutable manifesto;
    Hack0xDAOPrizePool public immutable prizePool;

    mapping(address => UserInfo) public userInfos;
    HackathonInfo[] public hackathonInfos;
    ProjectInfo[] public projectInfos;

    uint256 constant MAX_INT = 2 ** 256 - 1;
    uint256 constant DAOSharePercentage = 40; // 40% of all prizes go to the DAO
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyCreator(uint256 projectId) {
        require(projectInfos[projectId].creator == msg.sender, "User must be the creator of the project");
        _;
    }

    modifier projectExists(uint256 projectId) {
        require(projectInfos[projectId].creator != address(0), "Project must exist");
        _;
    }

    modifier projectLive(uint256 projectId) {
        ProjectInfo storage project = projectInfos[projectId];
        require(projectInfos[projectId].creator != address(0), "Project must exist");
        require(
            hackathonInfos[project.hackathonId].endTimestamp > block.timestamp,
            "Project's hackathon must not have ended"
        );
        require(project.closed == false, "Project must not be closed");
        _;
    }

    constructor(
        address EAS,
        bytes32 _attestTaskSchema,
        bytes32 _doneTaskSchema,
        bytes32 _projectCreationSchema,
        bytes32 _attestUserSchema
    )
        Attester(EAS, msg.sender, _attestTaskSchema, _doneTaskSchema, _projectCreationSchema, _attestUserSchema)
        Ownable()
    {
        // _owner = msg.sender;
        manifesto = new Hack0xManifesto(); // create manifesto token from within the contract, making this contract it's admin
        merit = new Hack0xMerit(); // create merit Token to be able to mint to within the contract
        merit.grantRole(DEFAULT_ADMIN_ROLE, address(this)); // grant EAS the ability to mint merit tokens
        prizePool = new Hack0xDAOPrizePool(address(merit)); // create DAO prize pool contract
        merit.grantRole(DEFAULT_ADMIN_ROLE, address(prizePool)); //
        createHackathon(0, MAX_INT); // hackathon 0 that means no hackathon
    }

    /**
     * @dev Creates a new hackathon
     * @param startTimestamp The timestamp when the hackathon starts
     * @param endTimestamp The timestamp when the hackathon ends
     * @return The id of the hackathon
     */
    function createHackathon(uint256 startTimestamp, uint256 endTimestamp) public onlyOwner returns (uint256) {
        require(startTimestamp < endTimestamp, "startTimestamp must be before endTimestamp");
        HackathonInfo memory hackathonInfo = HackathonInfo(startTimestamp, endTimestamp);
        hackathonInfos.push(hackathonInfo);
        return hackathonInfos.length - 1;
    }

    function signManifestoAndJoinDAO() public payable {
        require(userInfos[msg.sender].joined == false, "User already joined");
        require(msg.value == 10 ether, "Must send 10 OP to join DAO");
        manifesto.sign(); // mints 1 manifesto NFT to the sender
        userInfos[msg.sender].joined = true;
    }

    function createProject(uint256 hackathonId, PrizeDistributionType prizeDistributionType, uint256 predictiveValue)
        public
        returns (uint256 projectId)
    {
        require(hackathonInfos[hackathonId].endTimestamp > block.timestamp, "Hackathon must not have ended");
        require(userInfos[msg.sender].joined == true, "User must have joined DAO");

        projectId = projectInfos.length;
        ProjectInfo storage project = projectInfos.push();

        project.hackathonId = hackathonId;
        project.prizeDistributionType = prizeDistributionType;
        project.predictiveValue = predictiveValue;
        project.prize = 0;
        project.team.push(msg.sender);
        project.creator = msg.sender;

        attestProjectCreation(msg.sender, projectId);

        userInfos[msg.sender].projects.push(projectId);
    }

    function setSAFEAddress(uint256 projectId, address SAFE) public onlyCreator(projectId) {
        projectInfos[projectId].SAFE = SAFE;
    }

    function requestToJoinProject(uint256 projectId, string memory link) external projectExists(projectId) {
        projectInfos[projectId].joinRequests[msg.sender] = link;
    }

    function getJoinRequestLink(uint256 projectId, address buidler) external view returns (string memory) {
        return projectInfos[projectId].joinRequests[buidler];
    }

    function approveJoinRequest(uint256 projectId, address buidler)
        external
        projectLive(projectId)
        onlyCreator(projectId)
    {
        ProjectInfo storage project = projectInfos[projectId];
        require(
            keccak256(abi.encodePacked(project.joinRequests[buidler])) != keccak256(abi.encodePacked("")),
            "buidler must have requested to join"
        );
        require(!project.isBuidler[buidler], "buidler is already a buidler on this project");
        if (buidler != project.creator && project.investors[buidler] == 0) project.team.push(buidler);
        project.isBuidler[buidler] = true;
        userInfos[buidler].projects.push(projectId);
        project.team.push(buidler);
        _addMerit(project, project.creator, 1); // reward creator with 1 merit for accepting a new buidler
        delete project.joinRequests[buidler];
    }

    function createTask(uint256 projectId, uint256 value, uint256 deadline)
        external
        projectLive(projectId)
        onlyCreator(projectId)
        returns (uint256)
    {
        require(value > 0 && value < 6, "Task value must be between 1 and 5");
        require(deadline > block.timestamp, "Deadline must be in the future");
        ProjectInfo storage project = projectInfos[projectId];
        Task memory task;

        task.taskValue = value;
        task.taskCreator = msg.sender;
        task.taskDeadline = deadline;
        task.taskCompleted = false;
        task.easUID = attestTask(msg.sender, deadline);

        project.tasks.push(task);

        // add task UID to task after attesting

        return project.tasks.length - 1;
    }

    function pickUpTask(uint256 projectId, uint256 taskId) external projectLive(projectId) {
        ProjectInfo storage project = projectInfos[projectId];
        Task storage task = project.tasks[taskId];
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(project.isBuidler[msg.sender], "User must be a buidler of the project");
        require(task.pickedUpBy == address(0), "Task already picked up");
        task.pickedUpBy = msg.sender;
    }

    function dropTask(uint256 projectId, uint256 taskId) external projectLive(projectId) {
        ProjectInfo storage project = projectInfos[projectId];
        Task storage task = project.tasks[taskId];
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(task.pickedUpBy == msg.sender, "Task must have been picked up by the sender");
        task.pickedUpBy = address(0);
    }

    function approveTaskDone(uint256 projectId, uint256 taskId, address buidler)
        external
        projectLive(projectId)
        onlyCreator(projectId)
    {
        ProjectInfo storage project = projectInfos[projectId];
        Task storage task = project.tasks[taskId];

        // get task UID

        require(task.taskCreator == msg.sender, "Approver must be the creator of the task");
        require(!task.taskCompleted, "Task must not be done");
        require(task.taskDeadline > block.timestamp, "Task must not be overdue");
        require(task.pickedUpBy == buidler, "Task must have been picked up by the buidler");

        attestApproveTaskDone(msg.sender, buidler, task.easUID);

        _addMerit(project, buidler, task.taskValue);
        _addMerit(project, project.creator, 1); // reward creator with 1 merit for a task done
        task.taskCompleted = true;
    }

    function invest(uint256 projectId) external payable projectLive(projectId) {
        require(msg.value > 0, "Must send more than 0 OP");
        require(userInfos[msg.sender].joined, "Sender must have joined the DAO");
        ProjectInfo storage project = projectInfos[projectId];
        //  if (project.investors[msg.sender] == 0 && project.creator != msg.sender && !project.isBuidler[msg.sender])
        //    project.team.push(msg.sender);
        project.investors[msg.sender] += msg.value;
        project.totalInvestment += msg.value;
        project.prize += msg.value;
        userInfos[msg.sender].totalInvested += msg.value;
    }

    function win(uint256 projectId) external payable {
        require(msg.value > 0, "Must send more than 0 OP");
        ProjectInfo storage project = projectInfos[projectId];
        require(!project.closed, "Project is closed");
        project.prize += msg.value;
    }

    function closeProject(uint256 projectId) external onlyCreator(projectId) nonReentrant {
        ProjectInfo storage project = projectInfos[projectId];
        _addMerit(project, msg.sender, 3); // reward creator with 3 merits for finishing project

        uint256 DAOShare = project.prize * DAOSharePercentage / 100;
        uint256 teamShare = project.prize - DAOShare;

        // send DOA share to DAOPrizePool
        bool sent = payable(prizePool).send(DAOShare); //TODO: safer? OZ Address?
        require(sent, "Failed to send OP to DAO Prize Pool");

        if (project.prizeDistributionType == PrizeDistributionType.EQUAL) {
            // send team share to all team members
            for (uint256 i = 0; i < project.team.length; i++) {
                uint256 memberShare = teamShare / project.team.length;
                address payable teamMember = payable(project.team[i]);
                sent = teamMember.send(memberShare);
                require(sent, "Failed to send OP to team member");
            }
        } else if (project.prizeDistributionType == PrizeDistributionType.MERIT) {
            // send team share by merit
            for (uint256 i = 0; i < project.team.length; i++) {
                uint256 memberShare = (project.projectMerits[project.team[i]] / project.totalMerits) * teamShare;
                address payable teamMember = payable(project.team[i]);
                sent = teamMember.send(memberShare);
                require(sent, "Failed to send OP to team member");
            }
        }
        project.closed = true;
    }

    function _addMerit(ProjectInfo storage project, address user, uint256 value) internal {
        merit.mint(user, value);
        project.projectMerits[user] += value;
        project.totalMerits += value;
    }

    /*
     *     Helper functions
     */
    function isUserInDao(address _user) public view returns (bool) {
        return userInfos[_user].joined == true;
    }
}
