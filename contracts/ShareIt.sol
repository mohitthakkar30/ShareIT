//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract ShareIt  is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable{
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    // For each file, store the encrypted file key
    mapping(uint256 => mapping(address => string)) public fileKeys;

    // Store the public key for each registered address
    mapping(address => bytes32) public publicKeys;

    // To check that address is the NFT owner
    modifier isOwner(uint256 tokenId, address addr) {
        require(addr == ownerOf(tokenId), "Address does not own the file.");
        _;
    }

    // To check that address is not the NFT owner
    modifier isNotOwner(uint256 tokenId, address addr) {
        require(addr != ownerOf(tokenId), "Address owns the file.");
        _;
    }

    // To check that address is registered
    modifier isRegistered(address addr) {
        require(publicKeys[addr] != 0, "Address is not registered.");
        _;
    }


    // Events
    event Register(
        address indexed origin,
        address indexed sender,
        bytes32 publicKey
    );

     event Share(
        address indexed owner,
        address indexed to,
        uint256 indexed tokenId,
        string fileKey
    );

    event Mint(
        address indexed sender,
        address indexed to,
        uint256 indexed tokenId,
        string uri,
        string fileKey
    );
   
    event UnShare(
        address indexed owner,
        address indexed to,
        uint256 indexed tokenId
    );


    constructor() ERC721("ShareIt", "SHARE") {} 

    // Register an address
    function register(bytes32 publicKey) public {
        publicKeys[tx.origin] = publicKey;
        emit Register(tx.origin,msg.sender,publicKey);
    }

    // Mint a file as an NFT
     function safeMint(
        address to,
        string memory uri,
        string memory fileKey
    ) public isRegistered(to) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        fileKeys[tokenId][to] = fileKey;
        emit Mint( msg.sender, to, tokenId, uri, fileKey);
    }

    // Share a file and give read access to an address
    function share(
        uint256 tokenId,
        address to,
        string memory fileKey
    ) public isRegistered(to) isOwner(tokenId, msg.sender) {
        fileKeys[tokenId][to] = fileKey;
        emit Share(msg.sender, to, tokenId, fileKey);
    }

    // Unshare a file means to revoke read access from an user
    function unshare(uint256 tokenId, address to)
        public
        isRegistered(to)
        isOwner(tokenId, msg.sender){
        delete fileKeys[tokenId][to];
        emit UnShare(msg.sender, to, tokenId);
    }

    // The following functions are overrides which are required

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage){
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool){
        return super.supportsInterface(interfaceId);
    }

}
