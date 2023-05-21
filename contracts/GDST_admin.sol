// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Mintable } from "./interface/IERC20.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


contract Admin {

    enum Operations {
        None,
        Mint,
        Burn
    }
    /*
     * Data structure for each file, each file need to collect enough number of signature to 
     * execute the operation specified in the data structure.
     */
    struct File{
        Operations operation;
        uint amount;
        uint minSigner;
        uint createTime;
        address[] collected;
    }

    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isOwner;
    mapping(address => bool) private _authorizedSigner; // Only authorized signer can give signature to the files
    mapping(bytes32 => File) public files;
    

    IERC20Mintable _GDST;

    constructor(address GDST){
        _GDST = IERC20Mintable(GDST);
        _isOwner[msg.sender] = true;
    }

    modifier onlyOwner{
        require(isOwner(msg.sender), "Admin::Caller is not owner");
        _;
    }

    modifier onlyAdmin{
        require(isAdmin(msg.sender), "Admin::Caller is not admin");
        _;
    }

    /*
     * @dev signature is generated offchain and is validated in this function. 
     * Only authorized address's signature is valid.
     */
    function sign(bytes32 fileHash, bytes memory signature) external{
        require(isFileCreated(fileHash), "Admin::File not exist");
        address signer = ECDSAUpgradeable.recover(fileHash, signature);
        // address signer = msg.sender;
        require(isAuthorizedSigner(signer), "Admin::Signer is not authorized");
        
        for(uint i = 0;i < files[fileHash].collected.length; i++){
            require(signer != files[fileHash].collected[i], "Admin::Sign Duplicated signer");
        }
        files[fileHash].collected.push(signer);
    }

    function addAdmin(address account, bool status) external onlyOwner{
        _isAdmin[account] = status;
    }

    function addOwner(address account, bool status) external onlyOwner{
        _isOwner[account] = status;
    }

    function authorizeSigner(address signer, bool status) external onlyOwner{
        _authorizedSigner[signer] = status; 
    }

    function addFile(Operations operation, uint amount, bytes32 fileHash, uint minSigner) external onlyOwner{
        require(!isFileCreated(fileHash),"Admin::FileHash has been created");
        // files[fileHash] = File({createTime: block.timestamp, collected: []});
        files[fileHash].operation = operation;
        files[fileHash].amount = amount;
        files[fileHash].createTime = block.timestamp;
        files[fileHash].minSigner = minSigner;
    }
    /* 
     * @dev The mint function can only be called by an admin. Each operation need to be supported
     * by a file. The file's allowance amount will be deducted when the mint operation is done.
     */
    function increaseSupply(address to, uint256 amount, bytes32 fileHash) public onlyAdmin {
        require(isFileCreated(fileHash), "Admin::File not exist");
        require(files[fileHash].collected.length >= files[fileHash].minSigner, "Admin::Not enough signer");
        require(files[fileHash].operation == Operations.Mint, "Admin::Wrong file type");
        require(files[fileHash].amount >= amount, "Admin::Mint amount exceed specified amount");
        _GDST.increaseSupply(to, amount);
        files[fileHash].amount -= amount;
    }

    function decreaseSupply(address from, uint256 amount, bytes32 fileHash) public onlyAdmin {
        require(isFileCreated(fileHash), "Admin::File not exist");
        require(files[fileHash].collected.length >= files[fileHash].minSigner, "Admin::Not enough signer");
        require(files[fileHash].operation == Operations.Burn, "Admin::Wrong file type");
        require(files[fileHash].amount >= amount, "Admin::Mint amount exceed specified amount");
        _GDST.decreaseSupply(from, amount);
        files[fileHash].amount -= amount;
    }

    // #### Utils Functions ####
    
    function isAuthorizedSigner(address signer) public view returns (bool){
        return _authorizedSigner[signer];
    }

    function isAdmin(address account) public view returns (bool){
        return _isAdmin[account];
    }

    function isOwner(address account) public view returns (bool){
        return _isOwner[account];
    }

    function isFileCreated(bytes32 fileHash) public view returns (bool){
        return files[fileHash].createTime > 0;
    }

    function getFileSigner(bytes32 fileHash) public view returns (address[] memory){
        return files[fileHash].collected;
    }
}

// 0xE4928Db13D762D262D583d5b46C32509d36f21a1
// 0xA110A4F5C007C9C80eb69828A67FAedf226d6E46 token