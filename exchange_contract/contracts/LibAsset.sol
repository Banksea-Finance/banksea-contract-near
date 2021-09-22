// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library LibAsset {
    enum AssetType { 
        none, 
        eth,
        erc20, 
        erc721, 
        erc1155
    }

    enum SettleType { 
        none, 
        timeDown
    }

    struct Code {
        AssetType baseType;
        uint256 extraType;
        address contractAddr;
    }
    struct BaseAsset {
        Code code;
        uint256 value;
    }

    struct Asset {
        SettleType settleType;
        BaseAsset  baseAsset;
        uint256    extraValue;
    }

    function matchCode(Code memory leftCode, Code memory rightCode) internal pure returns (bool) {
        if(leftCode.baseType == rightCode.baseType &&
            leftCode.extraType == rightCode.extraType &&
            leftCode.contractAddr == rightCode.contractAddr) {
            return true;
        }
        return false;
    }

    function settleAsset(Asset memory asset, uint256 startTime, uint256 endTime) internal view returns (BaseAsset memory) {
        BaseAsset memory resultAsset = BaseAsset(asset.baseAsset.code, asset.baseAsset.value);
        
        if(asset.settleType == SettleType.timeDown) {
            require(block.timestamp <= endTime, "trade has been finished");
            uint256 chgValue = SafeMath.div(SafeMath.mul(SafeMath.sub(block.timestamp, startTime), SafeMath.sub(asset.baseAsset.value, asset.extraValue)), SafeMath.sub(endTime, startTime));
            resultAsset.value = SafeMath.sub(resultAsset.value, chgValue);
        }
        return resultAsset;
    }

    function hash(Asset memory asset) internal pure returns(bytes32) {
        return keccak256(abi.encode(asset.settleType, asset.baseAsset.code.baseType, asset.baseAsset.code.extraType, asset.baseAsset.code.contractAddr, asset.baseAsset.value, asset.extraValue));
    }

    function transferFrom(address from, address to, BaseAsset memory baseAsset) internal {
        if(baseAsset.code.baseType == AssetType.eth) {
            require(msg.sender == from, "ETH : msg.sender is not the payer");
            require(msg.value == baseAsset.value, "ETH : msg.value != baseAsset.value");
            Address.sendValue(payable(to), baseAsset.value);

        } else if(baseAsset.code.baseType == AssetType.erc20) {
            IERC20(baseAsset.code.contractAddr).transferFrom(from, to, baseAsset.value);
        } else if(baseAsset.code.baseType == AssetType.erc721) {
            require(baseAsset.value == 1, "ERC721 : baseAsset.value != 1");
            IERC721(baseAsset.code.contractAddr).safeTransferFrom(from, to, baseAsset.code.extraType);

        } else if(baseAsset.code.baseType == AssetType.erc1155) {
            bytes memory callData;
            IERC1155(baseAsset.code.contractAddr).safeTransferFrom(from, to, baseAsset.code.extraType, baseAsset.value, callData);
            
        } else {
            revert("baseAsset.code.baseType is error");
        }
        
    }
}