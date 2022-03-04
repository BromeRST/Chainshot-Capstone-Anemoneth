// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AnemonethV1 is ERC20CappedUpgradeable, OwnableUpgradeable {
    event Distribution(address indexed _addr, uint256 _amount);
    uint256 entryFee = .000000001 ether; // How hard do we want to make it to register?

    struct User {
        address addr;
        string username;
        string userImageURI; // added user image url (Max)
        uint256 joinDate;
        bool isUser;
    }

    User[] users; // <= don't know if we still need this after mapping. But if we remove it we should find a different solution for

    // user address => weekNumber => weeklyEarning
    mapping(address => mapping(uint256 => uint256)) historicalEarnings;
    //user address => User struct
    mapping(address => User) public addressToUser;

    // Tracks weekly mints of NEM
    struct WeeklyInfo {
        uint256 weekNumber;
        uint256 weeksNem;
    }
    WeeklyInfo[] weeklyInfoArr;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        uint256 initSupply
    ) public initializer {
        __ERC20Capped_init(cap_);
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        _mint(address(this), initSupply);
    }

    function register(string memory _username) external payable {
        require(msg.value >= entryFee);
        uint256 _amount = msg.value * 10000000000000000000000; // Establish exchange rate
        transferFrom(address(this), msg.sender, _amount);

        User storage newUser = addressToUser[msg.sender];
        newUser.isUser = true;
        newUser.username = _username;
        newUser.addr = msg.sender;
        newUser.joinDate = block.timestamp;

        users.push(newUser);
    }

    function weeklyEarnings() internal {
        // Calculate how much NEM to give to each EAO and how much total NEM to mint
        // This will be hard. Each post/comment/interaction cannot be an eth tx due to prohibitive
        // tx costs. We will have to aggregate IPFS data for each user and somehow get that data
        // into the contract... total mint hardcoded for now at 1000 and a fake user will be given
        // it
        WeeklyInfo memory thisWeek = WeeklyInfo(weeklyInfoArr.length, 0);
        uint256 sum;
        for (uint256 i = 0; i < users.length; i++) {
            address userAddr = users[i].addr;
            uint256 thisWeekEarnings = 1000; // this is going to hard. Probably will need to seperate into another function
            historicalEarnings[userAddr][
                thisWeek.weekNumber
            ] = thisWeekEarnings;
            sum += thisWeekEarnings;
        }
        thisWeek.weeksNem = sum;
        require(
            (thisWeek.weekNumber >= ((weeklyInfoArr.length - 1) + 1 weeks)) ||
                weeklyInfoArr.length == 0
        );
        weeklyInfoArr.push(thisWeek);
        // we need to emit an event here and check for it in the mint function.
        // Otherwise something might go wrong, it doesnt update weeklyInfoArr
        // and mint() would mint last weeks amount again
    }

    function mint() internal {
        // mint enough NEM to cover weeklyEarnings() and possibly estimated tx fees
        // check that weeklyEarnings() completed already
        _mint(address(this), weeklyInfoArr[weeklyInfoArr.length].weeksNem);
    }

    function distribute() internal {
        // increase balance of user addresses
        // This is really poorly gas-optimized, we can find a better solution
        // reference ERC20Upgradable line 231
        for (uint256 i = 0; i < users.length; i++) {
            address to = users[i].addr;
            uint256 weekNumber = weeklyInfoArr[weeklyInfoArr.length].weekNumber;
            uint256 amount = historicalEarnings[users[i].addr][weekNumber];
            _transfer(address(this), to, amount);
        }
    }

    function settleUP() external onlyOwner {
        weeklyEarnings();
        mint();
        distribute();
    }

    modifier OnlyUsers() {
        require(addressToUser[msg.sender].isUser);
        _;
    }

    // catch for Ether
    receive() external payable {}

    fallback() external payable {}
}
