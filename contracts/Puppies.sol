// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Royal721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Puppies is Royal721 {
    using Strings for uint256;

    string projecturl;


    event NewPuppy(uint256 id, string name, uint256 dna);

    struct Puppy {
        string name;
        uint256 dna;
    }

    struct Details {
        string name;
        uint256 dna;
        uint256 id;
        uint256 price;
        address owner;
    }

    Puppy[] public nfts;
    mapping(string => uint) namemap;
    mapping(uint => uint) dnamap;




    constructor(string memory name_, string memory symbol_, address weth_) Royal721(name_, symbol_, weth_) {
        mintingfee = 1000000000;
        lastfeeupdate = block.timestamp;

        baseurl = "https://ponzipuppies.com/api/v1/meta/";
        projecturl = "https://ponzipuppies.com/api/v1/project/";

        _mint("Rare Pupper", 0xe9c6afffe6d5ffd5d5008000008000ffaaaaffe6d51a1a1aff8080d7eef4);
        _mint("Ghost", 0xffffffffffffffffffc491c100f700000000ffffff1a1a1affaaaa000000);
        _mint("Froggy", 0x84f547c1f9bb83cf5f188809188809ffccccc1f9bb1a1a1affc1c1f9f2c8);
        _mint("Husko", 0xd8d8d8ffffffffffff37e3e337e3e3ffb9b9ffffff1a1a1aff99996db8c2);
        _mint("Gary Wee", 0x125740ffffffffffff000000000000ffffffffffff1a1a1aff919161deb6);
        _mint("Browny", 0x44402de4e0a52f2413dadd6446b533ffb9b9f2efb31a1a1affb3b3edd3eb);
        _mint("Elon Husk", 0xcc0000ffffffcc0000000000000000ffffffcc0000ffffffffffffffffff);
        _mint("woof.i.am", 0x624831eb6354ef98e75c4023564829ff8c8c6248311a1a1affaaaad7eef4);
        _mint("Dogtor Poolittle", 0x915a3effffff322c219f7d2d3cb53c413625ffffff1a1a1aff7979d7eef4);
        _mint("Taylor Sniff", 0xffffff000000000000000000000000000000ffffff1a1a1aff7979a5e2d8);
        _mint("Poogle", 0xffffff2db51ee0c927000000000000e83515ffffff1a1a1a787efadadada);
        _mint("Bark - James Bark", 0x000000ffffffffffff46cec853d7cdf2a49dffffff1a1a1af88b83c0c8f3);
        _mint("Vincent Van Dog", 0xebf51840eb32e93407e9a2524b62debe43bb41f5ed1a1a1a9d1409d25ea0);
        _mint("Steve Dogs",      0x100000000000000000000000000000000000ffffff000000000000ffffff);
        _mint("Dwayne (The Stick) Barkson", 0xda9f78cecececfcfcf804040804040ffaaaacfcfcf1a1a1aff9d9d7de2ff);
        _mint("Poop Doggy Dog", 0x43484b7979797070700723c00f49b58b8d8c7272721a1a1affaaaaffffff);
        _mint("FearMe", 0x9f0b0b701816771717c77030c28b47530b09870e0e1a1a1a6f0000eca29f);
        _mint("JSON Dogulo", 0x3f2007bb060bbd0409c77030c28b47b30409c6040a1a1a1aff777797627b);
        _mint("Kim Kardogian", 0x4a2c06dcc8a0dcc8a0000000000000dcc8a0dcc8a01a1a1a5a395effffff);
        _mint("Dognald Dump", 0xe1c973d7ab28e6c86e5cd3d35cc4cfeab4a2dab0321a1a1ae0a398929fc9);
        _mint("Sniffy McSniffsnout", 0x54364e6c4a5953313e5bbfd56adb17ffaaaafadcdfe31a4dff8080f3f1e4);
    }

// ---------------------- API ---------------------------------


    function getDetails(uint256 tokenid) public view returns (Details memory) {
        Puppy memory p = nfts[tokenid - 1];
        return Details(p.name, p.dna, tokenid, sellprice[tokenid], _ownerOf(tokenid));
    }

    function getMyPuppies(address addr) external view returns (Details[] memory) {
        uint256 lenny = balanceOf(addr);
        Details[] memory thenfts = new Details[](lenny);

        for(uint index = 0; index < lenny; index++){
            uint tokenId = tokenOfOwnerByIndex(addr, index);
            thenfts[index] = getDetails(tokenId);
        }
        return thenfts;
    }

    function getAllPuppies() external view returns (Details[] memory) {
        uint256 lenny = totalSupply();
        Details[] memory thenfts = new Details[](lenny);

        for(uint index = 0; index < lenny; index++){
            thenfts[index] = getDetails(index + 1);
        }
        return thenfts;
    }

// ---------------------- Minting ---------------------------------


    function _mint(string memory _name, uint256 _dna) internal  {
        require(bytes(_name).length < 100, "Dogname too long");
        require(namemap[_name] == 0, "Dogname already taken");
        require(dnamap[_dna] == 0, "Colorscheme already taken");

        nfts.push(Puppy(_name, _dna));
        nextId = nfts.length + 1;

        tokenOwners[nextId - 1] = msg.sender;
        ownerHistory[nextId-1].push(msg.sender);

        namemap[_name] = nextId-1;
        dnamap[_dna] = nextId-1;

        emit NewPuppy(nextId - 1, _name, _dna);
    }


    function mint(string memory _name, uint256 _dna) whenNotPaused external {
        require(mintcounter[msg.sender] < 3, "You already minted three puppies");

        //payment aspects of minting
        _mint_helper();
        _mint(_name, _dna);
    }

    function reserveChange(uint256 tokenId, string memory _name, uint256 _dna) onlyOwner isTokenOwner(tokenId, msg.sender)  external {
        // change Puppies in reserve only if they are still in reserve
        require(tokenId <= 21, "Attempt to change non-reserve token");
        Puppy storage p = nfts[tokenId - 1];
        namemap[p.name] = 0;
        dnamap[p.dna] = 0;
        nfts[tokenId - 1] = Puppy(_name, _dna);
        namemap[_name] = tokenId;
        dnamap[_dna] = tokenId;
    }

    function airdropReserve(uint256 tokenId, address newowner) onlyOwner isTokenOwner(tokenId, msg.sender)  external {
        // change Puppies in reserve only if they are still in reserve
        require(tokenId <= 21, "Attempt to airdrop non-reserve token");
        _transferNFT(newowner, tokenId);
    }


// -------------------- Metadata -------------------------------------

    function setProjectURL(string memory url) external onlyOwner {
        projecturl = url;
    }

    function contractURI() public view returns (string memory) {
        return projecturl;
    }

    //Overwrite tokenURI for state-less backend
    // this means all metadata is on-chain, the api-endpoint simply reflects the data back in a trait-based JSON
    // format and displays the appropriate image
    function tokenURI(uint256 tokenId) external view virtual override tokenExists(tokenId)  returns (string memory){
        string memory _dna = nfts[tokenId - 1].dna.toHexString(32);
        string memory _name = nfts[tokenId - 1].name;
        return string(abi.encodePacked(baseurl, "?dna=", _dna, "&name=", _name));
    }

}