// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./LibOrder.sol";
import "./TransferProxy.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exchange is Ownable {
    mapping(bytes32 => bool) cancelOrder;
    address proxyAddr;
    
    function setProxy(address transferProxy) external onlyOwner {
        proxyAddr = transferProxy;
    }
   
    function cancelSingle(LibOrder.Order memory order) public {
        bytes32 hashBytes = LibOrder.hash(order);
        require(cancelOrder[hashBytes] == false, "the order has been canceled");
        cancelOrder[hashBytes] = true;
    }
    
    function isCanceled(LibOrder.Order memory order) internal view returns (bool) {
        bytes32 hashBytes = LibOrder.hash(order);
        return cancelOrder[hashBytes];
    }

    function byteToString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    function addressToString(address account) public pure returns(string memory) {
        return byteToString(abi.encodePacked(account));
    }

    function matchSingle(LibOrder.Order memory leftOrder, bytes memory leftSign, LibOrder.Order memory rightOrder, bytes memory rightSign) public payable {

        require(leftOrder.dir == LibOrder.TradeDir.sell && rightOrder.dir == LibOrder.TradeDir.buy, "trade direction is invalid");
        require(!isCanceled(leftOrder) && !isCanceled(rightOrder), "Order is canceled");
        require(leftOrder.maker == msg.sender || rightOrder.maker == msg.sender, "No exchange authority");
        require(LibOrder.matchSign(leftOrder, leftSign), "Left order sign error");
        require(LibOrder.matchSign(rightOrder, rightSign), "Right order sign error");
        
        (LibAsset.BaseAsset memory leftAsset, LibAsset.BaseAsset memory rightAsset) = LibOrder.matchOrder(leftOrder, rightOrder);

        cancelSingle(leftOrder);
        cancelSingle(rightOrder);

        transferFrom(leftOrder.maker, rightOrder.maker, leftAsset);
        transferFrom(rightOrder.maker, leftOrder.maker, rightAsset);
    }

    function transferFrom(address from, address to, LibAsset.BaseAsset memory baseAsset) internal {
      if(baseAsset.code.baseType == LibAsset.AssetType.eth) {
        LibAsset.transferFrom(from, to, baseAsset);
      } else {
        TransferProxy(proxyAddr).transferFrom(from, to, baseAsset);
      }
  
    }
}