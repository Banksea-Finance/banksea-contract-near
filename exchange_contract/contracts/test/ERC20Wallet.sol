// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Wallet is ERC20 {

    constructor() ERC20("ERC20TEST", "ET") {}
    function mint(address addr, uint256 amount) public {
        _mint(addr, amount);
    }

}
