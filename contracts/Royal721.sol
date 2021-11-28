// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Stripped721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Royal721 is Stripped721 {

    address beneficiary = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    address weth;

    mapping(uint256 => uint256) sellprice;
    mapping(uint256 => address[])  ownerHistory;


    //minting stuff
    uint256 public mintingfee; 
    uint256 public lastfeeupdate;
    mapping(address => uint) mintcounter;

    constructor (string memory name_, string memory symbol_, address weth_) Stripped721(name_, symbol_) {
        weth = weth_;
    }

// --------------- ownerHistory --------------------

    function getHistory(uint256 tokenId) external view returns(address[] memory) {
        return ownerHistory[tokenId];
    }

// ------------ transfer and royalties --------------------

    // make first 10 owners available in contract to transfer royalties
    function _transferNFT(address newowner, uint256 tokenId) internal whenNotPaused {
        tokenOwners[tokenId] = newowner;
        if (ownerHistory[tokenId].length < 10) {
            ownerHistory[tokenId].push(newowner);
        }
    }

    function _payroyalties(uint256 tokenId, uint256 price) internal whenNotPaused {
        IERC20 ctrweth = IERC20(weth);

        //pay royalties to history of 10 owners
        uint _baseroyal = price * 25 / 1000;
        uint accu = 0;
        for(uint index = 0; index < ownerHistory[tokenId].length; index++) {
            uint localfee = (_baseroyal >> index);
            address locowner = ownerHistory[tokenId][index];
            ctrweth.transfer(locowner, localfee);
            accu += localfee;
        }

        //pay contract fee
        ctrweth.transfer(beneficiary, price / 100);
        accu += price / 100;

        //pay seller
        ctrweth.transfer(_ownerOf(tokenId), price - accu);
    }

    function withdraw() external onlyOwner {
        IERC20 ctrweth = IERC20(weth);
        uint256 _bal = ctrweth.balanceOf(address(this));
        ctrweth.transfer(beneficiary, _bal);
    }


// ----------- Seller initiated purchase flow ------------------

    // The token owner can set a price. Price = 0 indicates not for sale.
    function setPrice(uint256 tokenId, uint256 price) external whenNotPaused isTokenOwner(tokenId, msg.sender) {
        sellprice[tokenId] = price;
    }

    function getPrice(uint256 tokenId) external view returns (uint256) {
        return sellprice[tokenId];
    }

    function buynow(uint256 tokenId, uint256 price) external whenNotPaused {
        require(sellprice[tokenId] != 0, "Royal721: NFT is not for sale");
        require(_ownerOf(tokenId) != msg.sender, "Royal721: Cannot sell NFT to yourself");
        require(sellprice[tokenId] <= price, "Royal721: buynow - price of NFT is higher than you are willing to pay");
        IERC20 ctrweth = IERC20(weth);
        bool success = ctrweth.transferFrom(msg.sender, address(this), price);
        require(success, "Royal721: wETH transferFrom failed");
        _payroyalties(tokenId, price);
        sellprice[tokenId] = 0;
        _transferNFT(msg.sender, tokenId);
    }



// --------- Minting  -----------------------



    function _mint_helper() internal {

        //must have allowance
        IERC20 ctrweth = IERC20(weth);
        bool success = ctrweth.transferFrom(msg.sender, beneficiary, mintingfee);
        require(success, "Royal721: wETH transferFrom failed");

        //The minting fee lies on a dynamic bonding curve involing both time and quanity
        // - The fee increases by 10% every 18.2 hours
        // - The fee increases by 1% after each mint.

        //time based update
        //seconds shifted 16 digits, is equal to 18.2 hours
        uint256 dur = (block.timestamp - lastfeeupdate) >> 16;
        if (dur > 0) {
            mintingfee = 11**dur * mintingfee / (10**dur);
            lastfeeupdate = block.timestamp;
        }

        //volume based update
        mintingfee = 101 * mintingfee / 100;
        mintcounter[msg.sender] += 1;
    }


}