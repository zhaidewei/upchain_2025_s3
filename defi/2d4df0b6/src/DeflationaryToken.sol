// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeflationaryToken
 * @dev 一个通缩的ERC20代币，每年增发一次，但增发数量按年递减1%
 * 使用gons作为内部记账单位，用户看到的是fragments
 */
contract DeflationaryToken is ERC20, Ownable {
    using SafeMath for uint256;

    // 事件：记录rebase操作
    event LogRebase(uint256 indexed epoch, uint256 totalSupply, uint256 gonsPerFragment);
    event LogMint(uint256 indexed year, uint256 amount, uint256 timestamp);

    // 代币精度：18位小数
    uint256 private constant DECIMALS = 18;
    // 初始代币供应量：1亿 * 10^18
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100 * 10 ** 6 * 10 ** DECIMALS;

    // 一年时间（秒）
    uint256 private constant YEAR_IN_SECONDS = 365 days;

    // 每年递减比例：1%
    uint256 private constant DECREASE_RATE = 100; // 100 = 1%
    uint256 private constant RATE_DENOMINATOR = 10000; // 10000 = 100%

    // 最大uint256值
    uint256 private constant MAX_UINT256 = type(uint256).max;

    // TOTAL_GONS 是 INITIAL_FRAGMENTS_SUPPLY 的倍数，这样 _gonsPerFragment 就是一个整数
    // 使用更小的值避免溢出
    uint256 private constant TOTAL_GONS = INITIAL_FRAGMENTS_SUPPLY * 10 ** 9;

    // 当前代币总供应量（以fragments为单位）
    uint256 private _totalSupply;
    // 每个fragment对应的gons数量（转换率）
    uint256 private _gonsPerFragment;
    // 每个地址的gons余额映射
    mapping(address => uint256) private _gonBalances;

    // 记录上次mint的时间
    uint256 private _lastMintTime;
    // 记录当前年份（从部署开始计算）
    uint256 private _currentYear;

    // 修饰符：验证接收地址的有效性
    modifier validRecipient(address to) {
        require(to != address(0x0), "Invalid recipient: zero address");
        require(to != address(this), "Invalid recipient: contract address");
        _;
    }

    constructor() ERC20("DeflationaryToken", "DEFL") Ownable(msg.sender) {
        // 设置初始总供应量
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        // 将所有初始gons分配给部署者
        _gonBalances[msg.sender] = TOTAL_GONS;
        // 计算初始转换率
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // 记录部署时间
        _lastMintTime = block.timestamp;
        _currentYear = 1;

        // 发出初始转移事件
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev 检查是否可以mint新币
     * @return 是否可以mint
     */
    function canMint() public view returns (bool) {
        return block.timestamp >= _lastMintTime + YEAR_IN_SECONDS;
    }

    /**
     * @dev 计算当前年份应该mint的数量
     * @return mint数量
     */
    function calculateMintAmount() public view returns (uint256) {
        // 第一年mint初始供应量的99%
        if (_currentYear == 1) {
            return INITIAL_FRAGMENTS_SUPPLY * 99 / 100; // 99%
        }

        // 计算递减后的mint数量
        // 每年递减1%，即乘以 (10000 - 100) / 10000 = 0.99
        uint256 baseAmount = INITIAL_FRAGMENTS_SUPPLY;
        uint256 decreaseMultiplier = RATE_DENOMINATOR - DECREASE_RATE;

        // 计算第N年的mint数量：baseAmount * (0.99)^(N-1)
        uint256 mintAmount = baseAmount;
        for (uint256 i = 1; i < _currentYear; i++) {
            mintAmount = mintAmount.mul(decreaseMultiplier).div(RATE_DENOMINATOR);
        }

        return mintAmount;
    }

    /**
     * @dev 执行年度mint操作
     * 只能由owner调用，且必须满足时间条件
     */
    function mint() external onlyOwner {
        require(canMint(), "Cannot mint yet");

        uint256 mintAmount = calculateMintAmount();
        require(mintAmount > 0, "No mint amount for this year");

        // 更新时间和年份
        _lastMintTime = block.timestamp;
        _currentYear = _currentYear + 1;

        // 增加总供应量
        _totalSupply = _totalSupply.add(mintAmount);

        // 重新计算转换率
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // 在rebase机制中，所有用户的gons余额保持不变
        // 新mint的代币通过调整_gonsPerFragment来体现
        // 不需要手动增加owner的gons余额

        emit LogMint(_currentYear - 1, mintAmount, block.timestamp);
        emit Transfer(address(0x0), owner(), mintAmount);
        emit LogRebase(_currentYear - 1, _totalSupply, _gonsPerFragment);
    }

    /**
     * @dev 获取当前年份
     */
    function getCurrentYear() external view returns (uint256) {
        return _currentYear;
    }

    /**
     * @dev 获取上次mint时间
     */
    function getLastMintTime() external view returns (uint256) {
        return _lastMintTime;
    }

    /**
     * @dev 获取距离下次mint的剩余时间
     */
    function getTimeUntilNextMint() external view returns (uint256) {
        if (canMint()) {
            return 0;
        }
        return _lastMintTime + YEAR_IN_SECONDS - block.timestamp;
    }

    /**
     * @dev 获取gons总供应量
     */
    function scaledTotalSupply() external pure returns (uint256) {
        return TOTAL_GONS;
    }

    /**
     * @dev 获取指定地址的gons余额
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    /**
     * @dev 获取当前gons per fragment比率
     */
    function getGonsPerFragment() external view returns (uint256) {
        return _gonsPerFragment;
    }

    /**
     * @dev 重写totalSupply函数
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev 重写balanceOf函数
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    /**
     * @dev 重写transfer函数
     */
    function transfer(address to, uint256 amount) public override validRecipient(to) returns (bool) {
        require(amount > 0, "Transfer amount must be greater than 0");

        uint256 gonValue = amount.mul(_gonsPerFragment);
        require(_gonBalances[msg.sender] >= gonValue, "Insufficient balance");

        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev 重写transferFrom函数
     */
    function transferFrom(address from, address to, uint256 amount) public override validRecipient(to) returns (bool) {
        require(amount > 0, "Transfer amount must be greater than 0");

        uint256 gonValue = amount.mul(_gonsPerFragment);
        require(_gonBalances[from] >= gonValue, "Insufficient balance");
        require(allowance(from, msg.sender) >= amount, "Insufficient allowance");

        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        _allowances[from][msg.sender] = allowance(from, msg.sender).sub(amount);

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev 重写approve函数
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(msg.sender != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev 获取授权额度
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // 存储授权额度的映射
    mapping(address => mapping(address => uint256)) private _allowances;
}
