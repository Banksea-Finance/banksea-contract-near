// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./LibAsset.sol";
library LibOrder {
    enum TradeDir { sell, buy }
    struct Order {
        TradeDir dir;

        address maker;
        LibAsset.Asset makerAsset;

        address taker;
        LibAsset.Asset takerAsset;

        uint256 fee;
        address feeRecipient;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
    }


    function hash(Order memory order) internal pure returns(bytes32) {
        return keccak256(abi.encode(order.dir, order.maker, LibAsset.hash(order.makerAsset), order.taker, LibAsset.hash(order.takerAsset), order.fee, order.feeRecipient, order.startTime, order.endTime, order.salt));
    }


    function verifySign(bytes32 hashBytes, bytes memory sign) internal pure returns (address) {
        address addr = ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashBytes)),sign);
        return addr;
    }

    function matchSign(Order memory order, bytes memory sign) internal pure returns (bool){
        return (order.maker == verifySign(hash(order), sign));
    }

    function matchOrder(Order memory leftOrder, Order memory rightOrder) internal view returns (LibAsset.BaseAsset memory, LibAsset.BaseAsset memory) {
        require(LibAsset.matchCode(leftOrder.makerAsset.baseAsset.code, rightOrder.takerAsset.baseAsset.code), "Sell asset code is not match");
        require(LibAsset.matchCode(leftOrder.takerAsset.baseAsset.code, rightOrder.makerAsset.baseAsset.code), "Buy asset code is not match");
        require(leftOrder.maker == rightOrder.taker || rightOrder.taker == address(0));
        require(rightOrder.maker == leftOrder.taker || leftOrder.taker == address(0));
        

        LibAsset.BaseAsset memory leftMakerAsset = LibAsset.settleAsset(leftOrder.makerAsset, leftOrder.startTime, leftOrder.endTime);
        LibAsset.BaseAsset memory leftTakerAsset = LibAsset.settleAsset(leftOrder.takerAsset, leftOrder.startTime, leftOrder.endTime);

        LibAsset.BaseAsset memory rightMakerAsset = LibAsset.settleAsset(rightOrder.makerAsset, rightOrder.startTime, rightOrder.endTime);
        LibAsset.BaseAsset memory rightTakerAsset = LibAsset.settleAsset(rightOrder.takerAsset, rightOrder.startTime, rightOrder.endTime);

        require(leftMakerAsset.value == rightTakerAsset.value, "Sell asset value is not match");
        require(leftTakerAsset.value <= rightMakerAsset.value, "Buy asset value is not match");
        
        return (leftMakerAsset, rightMakerAsset);
    }
}