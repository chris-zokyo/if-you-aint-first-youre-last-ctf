// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



contract FlashVault is ERC1155 {

    using Math for uint256;

    mapping(address => uint256) assetToId;
    mapping(uint256 => address) idToAsset;

    mapping(uint256 => uint256) private _totalAssetSupply;

    uint256 private _nextAssetId = 0;

    string name;
    string symbol;

    address admin;
    address strategy;

    uint256 fee = 1; // 1000 = 100%
    mapping(address => uint256) protocolFees;

    event Deposit(address, uint256);
    event Withdraw(address, uint256);
    event NewFee(uint256);

    error InvalidReceiver(address);

    modifier onlyOwner() {
        require(admin == msg.sender, "Unauthorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC1155("") {   

        name = _name;
        symbol = _symbol;  
        admin = msg.sender;       

    }

    function setStrategy(address _newStrategy) external onlyOwner {
        strategy = _newStrategy;
    }

    function setFees(uint256 _newFee) external onlyOwner {
        fee = _newFee;
        emit NewFee(_newFee);
    }

    function withdrawFees(address asset) external onlyOwner {
        uint256 assetFees = protocolFees[asset];
        protocolFees[asset] = 0;
        ERC20(asset).transfer(admin, assetFees);
    }

    function deposit(uint256 assets, address asset, address receiver) public returns(uint256 shares) {
        if(receiver == address(0)) revert InvalidReceiver(address(0));

        uint256 assetId = assetToId[asset];
        if(assetId == 0) { // NonExistent
            assetId = ++_nextAssetId;
            assetToId[asset] = assetId;
            idToAsset[assetId] = asset;
        }

        shares = convertToShares(assets, assetId);
        uint256 protocolFee = (assets * fee) / 1000;
        protocolFees[asset] += protocolFee;

        ERC20(asset).transferFrom(msg.sender, address(this), assets + protocolFee);
        
        _totalAssetSupply[assetId] += shares;
        _mint(receiver, assetId, shares, "");

        emit Deposit(msg.sender, assets);
    }

    function withdraw(uint256 assets, address asset, address receiver, address owner) public returns (uint256 shares) {
        if(receiver == address(0)) revert InvalidReceiver(address(0));

        uint256 assetId = assetToId[asset];
        shares = convertToShares(assets, assetId);

        _totalAssetSupply[assetId] -= shares;
        _burn(owner, assetId, shares);

        ERC20(asset).transfer(msg.sender, assets);

        emit Withdraw(msg.sender, assets);
    }

    function mint(uint256 shares, uint256 assetId, address receiver) public returns (uint256 assets)  {
        if(receiver == address(0)) revert InvalidReceiver(address(0));

        assets = convertToAssets(shares, assetId);

        _totalAssetSupply[assetId] += shares;
        _mint(receiver, assetId, shares, "");

        address asset = idToAsset[assetId];
        uint256 protocolFee = (assets * fee) / 1000;
        protocolFees[asset] += protocolFee;
        ERC20(asset).transferFrom(msg.sender, address(this), assets + protocolFee);

        emit Deposit(msg.sender, shares);
    }

    function redeem(uint256 shares, uint256 assetId, address receiver, address owner) public returns(uint256 assets) {
        if(receiver == address(0)) revert InvalidReceiver(address(0));

        assets = convertToAssets(shares, assetId);
        
        _totalAssetSupply[assetId] -= shares;
        _burn(owner, assetId, shares);
        address asset = idToAsset[assetId];
        ERC20(asset).transfer(receiver, assets);

        emit Withdraw(msg.sender, assets);
    }

    function convertToShares(uint256 assets, uint256 id) public view returns(uint256) {
        uint256 supply = totalSupply(id);
        address asset = idToAsset[id];

        return 
            supply == 0
                ? assets
                : assets.mulDiv(supply, totalAssets(asset), Math.Rounding.Floor);
    }

    function convertToAssets(uint256 shares, uint256 id) public view returns(uint256) {
        uint256 supply = totalSupply(id);
        address asset = idToAsset[id];
        
        return 
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(asset), supply, Math.Rounding.Floor);
    }

    function totalAssets(address asset) public view returns(uint256) {
        return ERC20(asset).balanceOf(address(this)) - protocolFees[asset];
    }

    function totalSupply(uint256 id) public view returns(uint256) {
        return _totalAssetSupply[id];
    }

}