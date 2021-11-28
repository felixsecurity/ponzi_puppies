// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


//This contract is only needed for local testing, it is a placeholder of the "real" wETH contract.
contract WETH is ERC20 {

    constructor() ERC20("wrapped Ether", "wETH") {
        _mint(msg.sender, 100000000000000000000000);
    }
}