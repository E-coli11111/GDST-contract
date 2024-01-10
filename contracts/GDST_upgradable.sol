// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract GDST is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint;

    mapping(address => bool) private _admin;
    mapping(address => bool) private _frozen;
    mapping(address => uint) private _predecreased; // Set to the value of decreaseSupply before decreaseSupply is called
    // If true, all transfers are blocked
    bool private _frozenAll = false;

    uint public fee = 0;
    address public feeReciever;
    uint public totalFee = 0;
    uint public constant ONE = 10**6;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    // Can be called by admin only
    modifier onlyAdmin{
        require(isAdmin(_msgSender()), "GDST::Caller is not the admin contract");
        _;
    }

    /*
     * @dev Initialize this contract. Acts as a constructor
     * @param targetFee The fee to be charged on each transfer
     * @param reciever The address to recieve the fee
     */
    function initialize(uint targetFee, address reciever) initializer public{
        __Context_init();
        __ERC20_init("GoldToken", "GDST"); // Official name to be finalized
        __Ownable_init();
        __UUPSUpgradeable_init();
        fee = targetFee;
        feeReciever = reciever;
    }

    /*
     * @dev Returns the decimal of the token. 
     * Applications should use this method to get the token precision.
     *
     * @return The decimal of the token.
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    //#### Fee ####

    /*
     * @dev Set the fee to be charged on each transfer
     * Actual fee rate = targetFee / 10**6
     *
     * @param target The fee to be charged on each transfer
     */
    function setFee(uint target) external onlyAdmin{
        require(target <= ONE, "GDST::Cannot set fee over 100%");
        fee = target;
    }

    /*
     * @dev Set the address to recieve the fee
     *
     * @param reciever The address to recieve the fee. Cannot be the null address
     */
    function setFeeReciever(address reciever) external onlyAdmin{
        require(reciever != address(0), "GDST::Cannot set fee reciever to zero address");
        feeReciever = reciever;
    }

    /*
     * @dev Calculate the fee to be charged on a transfer
     *
     * @param amount The amount to be transfered
     * @return The fee to be charged
     */
    function calcFee(uint amount) public view returns (uint){
        return amount.mul(fee).div(ONE);
    }

    //#### Transfer ####

    /*
     * @dev Transfer tokens from the caller to another
     * Emits 2 {Transfer} events
     *
     * @param to The address to transfer to
     * @param amount The amount to be transfered
     * @return True if the transfer is successful
     */
    function transfer(address to, uint256 amount) public override returns (bool){
        require(!isfrozenAll(), "GDST::Currently not allow any transfer");// Check global frozen
        require(!isFrozen(_msgSender()), "GDST::Account is frozen");

        // Calculate fee and transfer amount
        uint feeAmount = calcFee(amount);
        uint transferAmount = amount.sub(feeAmount);

        // Activate 2 transfer. First transfer the amount, then transfer the fee
        // Two events will be emitted
        super._transfer(msg.sender, to, transferAmount);
        
        if(feeAmount > 0){
            super._transfer(msg.sender, feeReciever, feeAmount);
        }

        totalFee = totalFee.add(feeAmount);

        return true;
    }

    /*
     * @dev Transfer tokens from one address to another
     * Caller needs to have allowance for ``from``'s tokens
     * Emits 2 {Transfer} events
     *
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to be transfered
     * @return True if the transfer is successful
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!isfrozenAll(), "GDST::Currently not allow any transfer");
        require(!isFrozen(from), "GDST::Account is frozen");

        uint feeAmount = calcFee(amount);
        uint transferAmount = amount.sub(feeAmount);

        super._transfer(from, to, transferAmount);
        
        if(feeAmount > 0){
            super._transfer(from, feeReciever, feeAmount);
        }

        totalFee = totalFee.add(feeAmount);
        
        return true;
    }

    //#### Admin setting ####

    /*
     * @dev Set the admin status of an account
     * Admin can freeze/unfreeze accounts
     *
     * @param account The account to set admin status
     * @param status The admin status to be set
     */
    function setAdmin(address account, bool status) external onlyOwner{
        _admin[account] = status;
    }

    /*
     * @dev Check if an account is admin
     *
     * @param account The account to check
     * @return True if the account is admin
     */
    function isAdmin(address account) public view returns (bool){
        return _admin[account];
    }


    //#### Freeze ####

    /*
     * @dev Freeze/Unfreeze an account
     * Frozen accounts cannot transfer tokens
     *
     * @param account The account to freeze/unfreeze
     * @param freeze The freeze status to be set
     */
    function _freezeAccount(address account, bool freeze) internal{
        _frozen[account] = freeze;
    }

    /*
     * @dev Freeze/Unfreeze an account
     * Frozen accounts cannot transfer tokens
     *
     * @param account The account to freeze/unfreeze
     * @param freeze The freeze status to be set
     */
    function freezeAccount(address account, bool freeze) external onlyOwner{
        _freezeAccount(account, freeze);
    }

    /*
     * @dev Freeze/Unfreeze global transfer
     *
     * @param freeze The freeze status to be set
     */
    function freezeAll(bool freeze) external onlyOwner{
        _frozenAll = freeze;
    }

    /*
     * @dev Check if an account is frozen
     *
     * @param account The account to check
     * @return True if the account is frozen
     */
    function isFrozen(address account) public view returns (bool){
        return _frozen[account];
    }

    /*
     * @dev Check if global transfer is frozen
     *
     * @return True if global transfer is frozen
     */
    function isfrozenAll() public view returns (bool){
        return _frozenAll;
    }

    //#### ERC621 Implementation ####

    /*
     * @dev Increase the total supply of the token. Similar to minting
     * Can only be called by admin
     *
     * @param value The amount to increase
     * @param to The address to receive the increased amount
     * @return True if the increase is successful
     */
    function increaseSupply(uint value, address to) public onlyAdmin returns (bool) {
        _mint(to, value);
        return true;
    }

    /*
     * @dev Preparation before decreasing the total supply of the token
     * Can only be called by admin
     *
     * @param value The amount to decrease
     * @param from The address to decrease the amount from
     * @return True if the decrease is successful
     */
    function predecreaseSupply(uint value, address from) public onlyAdmin returns (bool){
        require(balanceOf(from) >= value); // Must have enough balance to predecrease
        _freezeAccount(from, true);
        _predecreased[from] = value;
        return true; // Freeze account and set predecrease value
    }

    /*
     * @dev Decrease the total supply of the token
     * Can only be called by admin
     *
     * @param value The amount to decrease
     * @param from The address to decrease the amount from (must be the same as the one in predecreaseSupply)
     * @return True if the decrease is successful
     */
    function decreaseSupply(uint value, address from) public onlyAdmin returns (bool) {
        require(predecreasedValue(from)<=value, "GDST::PredecreaseSupply requirements not met");// Check predecrease value
        _burn(from, value); 
        _predecreased[from] = 0;// Clear predecrease value
        _freezeAccount(from, false); // Unfreeze account
        return true;
    }

    /*
     * @dev Get the predecrease value of an account
     *
     * @param account The account to check
     * @return The predecrease value of the account
     */
    function predecreasedValue(address account) public view returns (uint){
        return _predecreased[account];
    }
    
    //#### UUPS Upgrade ####
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}

// 0x8C9628550473F6A658061bbd7B1C7549c5439845