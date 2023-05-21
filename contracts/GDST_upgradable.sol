// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GDST is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    
    mapping(address => bool) private _admin;
    mapping(address => bool) private _frozen;
    mapping(address => uint) private _predecreased;//用于判断是否已经predecrease，存储需要销毁代币的数量
    //frozenAll全局冻结，不允许任何转账进行
    bool private _frozenAll = false;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    //管理员权限才能使用
    modifier onlyAdmin{
        require(isAdmin(_msgSender()), "GDST::Caller is not the admin contract");
        _;
    }

    //代理合约部署时调用
    function initialize() initializer public{
        __Context_init();
        __ERC20_init("GoldToken", "GDST");//名字待定
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function decimals() public view override returns (uint8) {
        return 8;
    }

    function transfer(address to, uint256 amount) public override returns (bool){
        require(!isfrozenAll(), "GDST::Currently not allow any transfer");//需要检查全局frozen
        require(!isFrozen(_msgSender()), "GDST::Account is frozen");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!isfrozenAll(), "GDST::Currently not allow any transfer");//需要检查全局frozen
        require(!isFrozen(from), "GDST::Account is frozen");
        return super.transferFrom(from, to, amount);
    }


    //#### 管理员权限设置 ####
    function setAdmin(address account, bool status) external onlyOwner{
        _admin[account] = status;
    }

    function isAdmin(address account) public view returns (bool){
        return _admin[account];
    }


    //#### 冻结全局或冻结某个账户 ####
    function _freezeAccount(address account, bool freeze) internal{
        _frozen[account] = freeze;
    }

    function freezeAccount(address account, bool freeze) external onlyOwner{
        _freezeAccount(account, freeze);
    }

    function freezeAll(bool freeze) external onlyOwner{
        _frozenAll = freeze;
    }

    function isFrozen(address account) public view returns (bool){
        return _frozen[account];
    }

    function isfrozenAll() public view returns (bool){
        return _frozenAll;
    }

    //#### ERC621 Implementation ####
    function increaseSupply(uint value, address to) public onlyAdmin returns (bool) {
        _mint(to, value);
        return true;
    }

    function predecreaseSupply(uint value, address from) public onlyAdmin returns (bool){
        require(balanceOf(from) >= value);//需要超额冻结
        _freezeAccount(from, true);
        _predecreased[from] = value;
        return true;//要求冻结账户
    }

    function decreaseSupply(uint value, address from) public onlyAdmin returns (bool) {
        require(predecreasedValue(from)<=value, "GDST::PredecreaseSupply requirements not met");//要求decrease的数量必须和predecrease的数量相同（可能更改）
        _burn(from, value); 
        _predecreased[from] = 0;//decrease结束后设定predecrease的值为0，避免一次predecrease后存在多次decrease
        _freezeAccount(from, false);
        return true;
    }

    function predecreasedValue(address account) public view returns (uint){
        return _predecreased[account];
    }
    //#### UUPS 更新 ####
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
//0xf234bD8930B784b607F88BC6ACa9b52766400B2C