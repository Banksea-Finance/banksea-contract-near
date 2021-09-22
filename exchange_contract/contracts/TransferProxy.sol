// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./LibAsset.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TransferProxy is Ownable {
    address public accessAddr;
    function setAccessible(address addr) public onlyOwner {
        accessAddr = addr;
    }

    function transferFrom(address from, address to, LibAsset.BaseAsset memory baseAsset) public {
        require(accessAddr == msg.sender, "Msg sender is not accessible");
        LibAsset.transferFrom(from, to, baseAsset);
    }
}