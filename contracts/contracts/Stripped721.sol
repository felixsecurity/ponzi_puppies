// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Stripped721 is IERC721, IERC721Enumerable, IERC721Metadata, Pausable, Ownable {
    using Strings for uint256;
    using Address for address;

    // Base
    mapping(uint256 => address) tokenOwners;
    uint256 nextId = 1;

    // Base unused
    mapping(uint256 => address) private oneApprove;
    mapping(address => mapping(address => bool)) private allApprove;

    //Meta
    string private _name;
    string private _symbol;
    string baseurl;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokenOwners[tokenId] != address(0));
        _;
    }

    modifier isTokenOwner(uint256 tokenId, address owner) {
        require(tokenOwners[tokenId] == owner);
        _;
    }

    function balanceOf(address owner) public view override returns (uint256){
        uint256 acc = 0;
        for(uint256 index = 1; index < nextId; index++) {
            if (tokenOwners[index] == owner) {
                acc += 1;
            }
        }
        return acc;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return _ownerOf(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view tokenExists(tokenId) returns (address) {
        return tokenOwners[tokenId];
    }

// ----------- transfer functions -------------------

    function safeTransferFrom(address from,address to, uint256 tokenId) external override {
        _transferToken(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _transferToken(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _transferToken(from, to, tokenId);
    }

    function _transferToken(address from, address to, uint256 tokenId)  internal {
        require(false, "To ensure royalties, regular transfer is disabled");
    }



    //provided for interface compliance, not used
    //anybody can transferFrom if price is paid
    function approve(address to, uint256 tokenId) external override isTokenOwner(tokenId, msg.sender) {
        oneApprove[tokenId] = to;
    }

    //provided for interface compliance, not used
    //anybody can transferFrom if price is paid
    function getApproved(uint256 tokenId) external view override tokenExists(tokenId) returns (address ) {
        return oneApprove[tokenId];
    }


    //provided for interface compliance, not used
    //anybody can transferFrom if price is paid
    function setApprovalForAll(address operator, bool _approved) external override {
        allApprove[msg.sender][operator] = _approved;
    }


    //provided for interface compliance, not used
    //anybody can transferFrom if price is paid
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return allApprove[owner][operator];
    }




// ------ IERC721 helper --------------------

function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }



//------------------- IERC721Enumerable ---------------------------------

    function totalSupply() public view override returns (uint256){
        return nextId - 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256){
        uint256 acc = 0;
        for(uint256 locind = 1; locind < nextId; locind++) {
            if (tokenOwners[locind] == owner) {
                if (acc == index) {
                    return locind;
                }
                acc += 1;
            }
        }
        require(false, "Index exceeds tokens owned by address");
        return 0;
    }

    function tokenByIndex(uint256 index) external view override tokenExists(index + 1) returns (uint256) {
        return index + 1;
    }

// ------------- IERC721Metadata ----------------------

    function name() external view override returns (string memory){
        return _name;
    }

    function symbol() external view override returns (string memory){
        return _symbol;
    }

    //Standard use cases for http and ipfs possible without override
    function tokenURI(uint256 tokenId) external view virtual override  returns (string memory){
        return string(abi.encodePacked(baseurl, tokenId.toString() ));
    }

//---------------------- additional for Meta -----------------------
    function setBaseURI(string memory newbase) external onlyOwner {
        baseurl = newbase;
    }


// ---------------------------- IERC165 -------------------------------------
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId;
    }

//-------------------------- Security -------------------------------------

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

}