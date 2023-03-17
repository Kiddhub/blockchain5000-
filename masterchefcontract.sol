// //SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// has 13 function: poolLength , add ,set ,setMigrator, migrate, getMultiplier,pendingSushi,massUpdatePools,updatePool
// deposit,withdraw,emergencyWithdraw,safeSushiTransfer



contract MasterCheftContract is Ownable {
    using SafeERC20 for IERC20;
    //Info each user
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;

    }
    //Info each pool
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    IERC20 public rewardToken;
    uint256 public rewardPerBlock;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);


    constructor (
        IERC20 _rewardToken,
        uint256 _rewardPerBlock
    ) public {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
    }

    //add a new 
    function add (
        uint256 _allocPoint,
        IERC20 _lpToken
    ) public onlyOwner // can be called by owner
    {
        require(_lpToken.balanceOf(address(this)) == 0, "LP token already added");
        totalAllocPoint += _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken:_lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: block.number,
            accRewardPerShare: 0
        }));
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }



    //pending reward
    function pendingReward(uint256 _pid, address _user) external view returns(uint256){
        PoolInfo storage pool = poolInfo[_pid];
        userInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if(block.number > pool.lastRewardBlock && lpSupply != 0){
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
            accRewardPerShare += reward * 1e12 / lpSupply;
        }
        return user.amount * accRewardPerShare / 1e12 - user.rewardDebt;

    }

    // deposit
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0){
            uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
            if(pending > 0){
                rewardToken.safeTransfer(msg.sender,pending);
            }
        }
        if(_amount > 0){
            pool.lpToken.safeTransferFrom(msg.sender,address(this),_amount);
            user.amount += _amount;
        }
    }

    //withdraw 
    function withdraw(uint256 _pid, uint256 _amount)public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accRewardPerShare / 1e12) - user.rewardDebt;
        if(pending > 0){
                safeRewardTransfer(msg.sender, pending);
            }
        if(_amount > 0){
            user.amount -= _amount;
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
        emit Withdraw (msg.sender, _pid , _amount);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock){
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0){
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - pool.lastRewardBlock;
        uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        rewardToken.mint(address(this),reward);
        pool.accRewardPerShare += reward * 1e12 /lpSupply;
        pool.lastRewardBlock = block.number;
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(msg.sender, amount);
    }

}

