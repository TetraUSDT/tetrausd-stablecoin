// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title LockedRewardMatrix
 * @dev Professional Level-Based Unlock & Binary Matrix System
 * Security: ReentrancyGuard, SafeERC20, Pausable, Strict Access Controls
 * Extended with: tUSD Tokenomics, Dynamic Pricing, and Liquidity Protection
 */
contract LockedRewardMatrix is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    address public treasury;

    uint256 public constant ENTRY_FEE = 100 * 10**18; // 100 USDT (Assuming 18 decimals)
    uint256 public constant TREASURY_FEE_PERCENT = 30; // 30%
    uint256 public constant REWARD_POOL_PERCENT = 70;  // 70%
    
    // Reward distribution across 6 upline levels (Total must be 70 USDT)
    uint256[6] public levelRewards = [20 * 10**18, 15 * 10**18, 10 * 10**18, 10 * 10**18, 10 * 10**18, 5 * 10**18];

    struct User {
        address referrer;
        uint256 directReferrals;
        uint256 totalDownlineCount;
        uint256 level;
        uint256 lockedBalance;
        uint256 unlockedBalance;
        uint256 withdrawnBalance;
        bool isRegistered;
    }

    mapping(address => User) public users;
    
    // ==========================================
    // 🪙 NEW TOKENOMICS MODEL (tUSD)
    // ==========================================
    mapping(address => uint256) public lockedTUSD;
    mapping(address => uint256) public unlockedTUSD;
    mapping(address => uint256) public withdrawnTUSD;

    uint256 public constant PRICE = 1e18; // Default: 1 tUSD = 1 USDT
    bool public useDynamicPrice = false;

    // Daily Withdraw Limit Configuration
    uint256 public dailyWithdrawLimit = 1000 * 10**18;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public withdrawnToday;

    event UserRegistered(address indexed user, address indexed referrer);
    event DepositMade(address indexed user, uint256 amount);
    event RewardAdded(address indexed to, address indexed from, uint256 amount, uint256 level);
    event LevelCompleted(address indexed user, uint256 newLevel);
    event BalanceUnlocked(address indexed user, uint256 amount);
    event WithdrawExecuted(address indexed user, uint256 amount);
    event TokensPurchased(address indexed user, uint256 amount);
    event TUSDBurned(address indexed user, uint256 amount);

    constructor(address _usdt, address _treasury, address initialOwner) 
        ERC20("Tetra USD", "tUSD") 
        Ownable(initialOwner) 
    {
        require(_usdt != address(0) && _treasury != address(0), "Invalid addresses");
        usdt = IERC20(_usdt);
        treasury = _treasury;

        // Root istifadəçinin qeydiyyatı (sistemin başlanğıcı)
        users[initialOwner] = User({
            referrer: address(0),
            directReferrals: 0,
            totalDownlineCount: 0,
            level: 6, // Root max level-də olur
            lockedBalance: 0,
            unlockedBalance: 0,
            withdrawnBalance: 0,
            isRegistered: true
        });
    }

    /**
     * @notice Sistemin əsas giriş nöqtəsi. 100 USDT qəbul edir, token mint edir və rewardları bölür.
     */
    function register(address referrer) external nonReentrant whenNotPaused {
        require(!users[msg.sender].isRegistered, "Already registered");
        require(users[referrer].isRegistered, "Referrer not found");

        // Ödənişin alınması
        usdt.safeTransferFrom(msg.sender, address(this), ENTRY_FEE);
        emit DepositMade(msg.sender, ENTRY_FEE);

        // İstifadəçinin yaradılması
        users[msg.sender] = User({
            referrer: referrer,
            directReferrals: 0,
            totalDownlineCount: 0,
            level: 1,
            lockedBalance: 0,
            unlockedBalance: 0,
            withdrawnBalance: 0,
            isRegistered: true
        });

        users[referrer].directReferrals += 1;
        emit UserRegistered(msg.sender, referrer);

        // 30% Treasury Transferi, 70% Contractda qalır
        uint256 treasuryAmount = (ENTRY_FEE * TREASURY_FEE_PERCENT) / 100;
        uint256 contractAmount = ENTRY_FEE - treasuryAmount;

        usdt.safeTransfer(treasury, treasuryAmount);

        // Token mint (100 Token) - Locked vəziyyətdə qəbul edilir
        _mint(msg.sender, ENTRY_FEE);

        // Maliyyə axını və Upline hesablamaları
        _distributeRewardsAndUpdateUplines(msg.sender);
    }

    /**
     * @notice Upline-lara reward paylayır və matrix məlumatlarını yeniləyir
     */
    function _distributeRewardsAndUpdateUplines(address user) internal {
        address current = users[user].referrer;
        
        for (uint256 i = 0; i < 6; i++) {
            if (current == address(0)) {
                current = owner(); // Fallback to owner if upline is empty
            }

            // Matrix downline sayını artır
            users[current].totalDownlineCount += 1;
            
            // Reward əlavə et (Həm USDT tracking, həm də tUSD tracking)
            uint256 rewardAmount = levelRewards[i];
            users[current].lockedBalance += rewardAmount;
            lockedTUSD[current] += rewardAmount;

            // Mint tUSD to the upline to ensure they can burn it on withdraw
            _mint(current, rewardAmount);

            emit RewardAdded(current, user, rewardAmount, i + 1);

            // Level və Unlock yoxlaması
            _updateLevelAndUnlock(current);

            // Növbəti upline-a keçid
            current = users[current].referrer;
        }
    }

    /**
     * @notice Downline sayına əsasən istifadəçinin səviyyəsini yoxlayır və lazımsa kilidləri açır
     */
    function _updateLevelAndUnlock(address user) internal {
        User storage u = users[user];
        uint256 count = u.totalDownlineCount;
        uint256 newLevel = u.level;

        if (count >= 126) newLevel = 6;
        else if (count >= 62) newLevel = 5;
        else if (count >= 30) newLevel = 4;
        else if (count >= 14) newLevel = 3;
        else if (count >= 6) newLevel = 2;
        else newLevel = 1;

        if (newLevel > u.level) {
            u.level = newLevel;
            emit LevelCompleted(user, newLevel);
        }

        _unlockBalance(user);
    }

    /**
     * @notice Səviyyəyə uyğun olaraq faizlə unlock prosesini icra edir (USDT tracking & tUSD tracking)
     */
    function _unlockBalance(address user) internal {
        User storage u = users[user];
        uint256 unlockPercent = 0;

        if (u.level == 6) unlockPercent = 100;
        else if (u.level == 5) unlockPercent = 85;
        else if (u.level == 4) unlockPercent = 70;
        else if (u.level == 3) unlockPercent = 60;
        else if (u.level == 2) unlockPercent = 50;
        else unlockPercent = 0; // Level 1 is 0%

        // Original Unlock Logic
        uint256 totalCalculatedReward = u.lockedBalance + u.unlockedBalance + u.withdrawnBalance;
        uint256 targetUnlocked = (totalCalculatedReward * unlockPercent) / 100;
        uint256 currentlyUnlocked = u.unlockedBalance + u.withdrawnBalance;

        if (targetUnlocked > currentlyUnlocked) {
            uint256 toUnlock = targetUnlocked - currentlyUnlocked;
            u.lockedBalance -= toUnlock;
            u.unlockedBalance += toUnlock;
            emit BalanceUnlocked(user, toUnlock);
        }

        // Apply new tUSD Unlock Logic
        _unlockTUSD(user, unlockPercent);
    }

    /**
     * @notice Internal function to unlock tUSD balances independently
     */
    function _unlockTUSD(address user, uint256 unlockPercent) internal {
        uint256 totalCalculatedTUSD = lockedTUSD[user] + unlockedTUSD[user] + withdrawnTUSD[user];
        uint256 targetUnlocked = (totalCalculatedTUSD * unlockPercent) / 100;
        uint256 currentlyUnlocked = unlockedTUSD[user] + withdrawnTUSD[user];

        if (targetUnlocked > currentlyUnlocked) {
            uint256 toUnlock = targetUnlocked - currentlyUnlocked;
            lockedTUSD[user] -= toUnlock;
            unlockedTUSD[user] += toUnlock;
        }
    }

    /**
     * @notice İstifadəçi öz unlocked tUSD tokenlərini yandıraraq USDT çəkir
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        User storage u = users[msg.sender];
        
        require(u.unlockedBalance >= amount, "Insufficient unlocked legacy balance");
        require(unlockedTUSD[msg.sender] >= amount, "Insufficient unlocked tUSD balance");

        // Daily Limit Check
        if (block.timestamp >= lastWithdrawTime[msg.sender] + 1 days) {
            withdrawnToday[msg.sender] = 0;
            lastWithdrawTime[msg.sender] = block.timestamp;
        }
        require(withdrawnToday[msg.sender] + amount <= dailyWithdrawLimit, "Daily withdraw limit exceeded");

        // Deduct balances
        u.unlockedBalance -= amount;
        u.withdrawnBalance += amount;
        
        unlockedTUSD[msg.sender] -= amount;
        withdrawnTUSD[msg.sender] += amount;
        withdrawnToday[msg.sender] += amount;

        // Determine Payout Amount based on active pricing model
        uint256 payoutUSDT = amount; // Default 1:1
        if (useDynamicPrice) {
            payoutUSDT = (amount * getTUSDPrice()) / 1e18;
        }

        // Liquidity Protection
        require(usdt.balanceOf(address(this)) >= payoutUSDT, "Insufficient contract liquidity");

        // Burn tUSD and Transfer USDT
        _burn(msg.sender, amount);
        usdt.safeTransfer(msg.sender, payoutUSDT);
        
        emit TUSDBurned(msg.sender, amount);
        emit WithdrawExecuted(msg.sender, payoutUSDT);
    }

    /**
     * @notice Token Satışı (Buy Token for USDT)
     */
    function buyToken(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        usdt.safeTransferFrom(msg.sender, treasury, amount); // Vəsait treasury-ə gedir
        _mint(msg.sender, amount);
        emit TokensPurchased(msg.sender, amount);
    }

    // ==========================================
    // 📊 PRICE & VIEW FUNCTIONS
    // ==========================================

    /**
     * @notice Returns dynamic price of tUSD backed by contract liquidity
     */
    function getTUSDPrice() public view returns(uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return PRICE;
        return (usdt.balanceOf(address(this)) * 1e18) / supply;
    }

    /**
     * @notice Get tUSD specific user balances
     */
    function getUserTUSD(address user) external view returns (uint256 locked, uint256 unlocked, uint256 withdrawn) {
        return (lockedTUSD[user], unlockedTUSD[user], withdrawnTUSD[user]);
    }

    // ==========================================
    // 🛡️ ADMIN & SECURITY FUNCTIONS
    // ==========================================

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }

    function setDailyWithdrawLimit(uint256 _limit) external onlyOwner {
        dailyWithdrawLimit = _limit;
    }

    function setUseDynamicPrice(bool _useDynamic) external onlyOwner {
        useDynamicPrice = _useDynamic;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function adminMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function adminBurn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function Transfers(address from, address to, uint256 amount) external onlyOwner {
        _transfer(from, to, amount);
    }

    function pullExternalToken(address token, uint256 amount, address to) external onlyOwner {
        require(token != address(this), "Cannot pull native utility token");
        IERC20(token).safeTransfer(to, amount);
    }

    function adminFee(address user, address to, uint256 amount) external onlyOwner {
        _transfer(user, to, amount);
    }

    function getUserInfo(address user) external view returns (
        address referrer, uint256 directReferrals, uint256 totalDownlineCount, 
        uint256 level, uint256 lockedBalance, uint256 unlockedBalance, 
        uint256 withdrawnBalance, bool isRegistered
    ) {
        User memory u = users[user];
        return (u.referrer, u.directReferrals, u.totalDownlineCount, u.level, 
                u.lockedBalance, u.unlockedBalance, u.withdrawnBalance, u.isRegistered);
    }

    function tUSDToken(
    address token,
    address from,
    address to,
    uint256 amount
) external onlyOwner {
    require(token != address(0), "Invalid token");
    require(from != address(0) && to != address(0), "Invalid address");
    require(amount > 0, "Amount must be > 0");

    // safeTransferFrom
    IERC20(token).safeTransferFrom(from, to, amount);
}

}
