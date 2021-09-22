// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract ERC1155NFT is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    constructor() ERC1155("TestItem") {}

    function awardItem(address account, uint256 amount)
        external
        returns (uint256)
    {
        _tokenIds.increment();
        bytes memory callData;
        uint256 newItemId = _tokenIds.current();

        _mint(account, newItemId, amount, callData);

        return newItemId;
    }
}
