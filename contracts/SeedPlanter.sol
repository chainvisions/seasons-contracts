pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import "./EpochManager.sol";
import "./Seeds.sol";

// SeedPlanter is in charge of creating new SEEDS.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SEEDS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SeedPlanter is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SEEDS
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSeedsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSeedsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SEEDS to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SEEDS distribution occurs.
        uint256 accSeedsPerShare; // Accumulated SEEDS per share, times 1e12. See below.
        uint256 totalStaked;      // Simplifies the process of calculating pool TVL.
    }

    // The SEEDS TOKEN!
    Seeds public seeds;
    // Epoch Manager for emission control.
    EpochManager public epochManager;
    // Dev address.
    address public devaddr;
    // SEEDS tokens created per block.
    uint256 public seedsPerBlock;
    // Bonus muliplier for early seeds makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SEEDS mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SystemUpgrade(address indexed prevManager, address indexed newManager);

    constructor(
        Seeds _seeds,
        address _devaddr,
        uint256 _seedsPerBlock,
        uint256 _startBlock
    ) public {
        seeds = _seeds;
        devaddr = _devaddr;
        seedsPerBlock = _seedsPerBlock;
        startBlock = _startBlock;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSeedsPerShare: 0,
            totalStakeds: 0
        }));
    }

    // Update the given pool's SEEDS allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending SEEDS on frontend.
    function pendingSeeds(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSeedsPerShare = pool.accSeedsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 seedsReward = multiplier.mul(seedsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSeedsPerShare = accSeedsPerShare.add(seedsReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSeedsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 seedsReward = multiplier.mul(seedsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if(epochManager.emissionEndTime() >= now) {
            return;
        } else if(epochManager.emissionStartTime() > now) {
            return;
        } else {
            seeds.mint(devaddr, seedsReward.div(10));
            seeds.mint(address(syrup), seedsReward);
            pool.accSeedsPerShare = pool.accSeedsPerShare.add(seedsReward.mul(1e12).div(lpSupply));
            pool.lastRewardBlock = block.number;
        }
    }

    // Deposit LP tokens to SeedPlanter for SEEDS allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSeedsPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSeedsTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            pool.totalStaked = pool.totalStaked.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSeedsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from SeedPlanter.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSeedsPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeSeedsTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSeedsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        pool.totalStaked = pool.totalStaked.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe seeds transfer function, just in case if rounding error causes pool to not have enough SEEDS.
    function safeSeedsTransfer(address _to, uint256 _amount) internal {
        // TODO: remove syrup.safeCakeTransfer
        syrup.safeCakeTransfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Adjust the amount of SEEDS emitted every block.
    function adjustEmission(uint256 _seedsPerBlock) public onlyOwner {
        require(_seedsPerBlock > 0, "SeedPlanter: seedsPerBlock Cannot be 0!");
        seedsPerBlock = _seedsPerBlock;
    }

    /// @notice Function to upgrade the epoch system
    /// @dev This allows for security upgrades and more, allowing
    /// the protocol to evolve.
    function systemUpgrade(address _epochManager) public onlyOwner {
        address prevManager = epochManager;
        epochManager = _epochManager;
        emit SystemUpgrade(prevManager, epochManager);
    }

}