# Staking-Contract-with-Rewards1
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract StakingRewards {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    address public owner;

    uint public rewardRate = 100; // reward tokens per day per staked token
    uint public constant SECONDS_IN_A_DAY = 86400;

    struct Stake {
        uint amount;
        uint timestamp;
        uint rewardClaimed;
    }

    mapping(address => Stake) public stakes;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        owner = msg.sender;
    }

    function stake(uint _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount > 0) {
            uint rewards = calculateReward(msg.sender);
            userStake.rewardClaimed += rewards;
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        userStake.amount += _amount;
        userStake.timestamp = block.timestamp;
    }

    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "Nothing to unstake");

        uint rewards = calculateReward(msg.sender);
        uint totalRewards = rewards + userStake.rewardClaimed;

        stakingToken.transfer(msg.sender, userStake.amount);
        rewardToken.transfer(msg.sender, totalRewards);

        delete stakes[msg.sender];
    }

    function calculateReward(address _user) public view returns (uint) {
        Stake storage userStake = stakes[_user];
        if (userStake.amount == 0) {
            return 0;
        }

        uint timeStaked = block.timestamp - userStake.timestamp;
        uint daysStaked = timeStaked / SECONDS_IN_A_DAY;

        return (userStake.amount * rewardRate * daysStaked) / 1000; // adjust as needed
    }

    function updateRewardRate(uint _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    function withdrawRewardTokens(uint _amount) external onlyOwner {
        rewardToken.transfer(owner, _amount);
    }
}

