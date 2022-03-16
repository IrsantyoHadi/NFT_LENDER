// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Signed.sol";

contract DapsNFT is ERC721A, Ownable, ReentrancyGuard, Signed {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    string public baseExtension;
    string public unrevealURI;
    bool public isPresale = false;
    bool public isReveal = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(uint256 maxAmountPerMint, uint256 maxCollection)
        ERC721A("DapsNFTstd", "DAPS", maxAmountPerMint, maxCollection)
    {}

    //SETUP ONLY OWNER
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function flipPresale() external onlyOwner {
        isPresale = !isPresale;
    }

    // MINTING
    function mint(uint8 amount, bytes calldata signature)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(amount > 0, "You can get no fewer than 1");

        require(amount <= maxBatchSize, "too much");

        uint256 supply = totalSupply();

        require(supply + amount <= collectionSize, "reached max supply");

        if (isPresale) verifySignature(signature);

        _safeMint(msg.sender, amount);
    }

    // URL MATTER
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!isReveal) {
            return unrevealURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isReveal = _isReveal;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
