// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Daps1155 is ERC1155(""), Ownable {
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => uint256) public currentSupplies;
    uint256 public maxSupply = 5000;
    uint256 public currentSupply = 0;
    uint256 maxPerMint = 10;
    uint256 mintId = 1;
    string public stringUri;
    string public baseExtension = ".json";

    constructor() {
        maxSupplies[1] = 625;
        maxSupplies[2] = 625;
        maxSupplies[3] = 625;
        maxSupplies[4] = 625;
        maxSupplies[5] = 625;
        maxSupplies[6] = 625;
        maxSupplies[7] = 625;
        maxSupplies[8] = 625;
    }

    function setUriExtension(
        string calldata _stringUri,
        string calldata _baseExtension
    ) public {
        stringUri = _stringUri;
        baseExtension = _baseExtension;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    stringUri,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    function mint(uint256 _qty) external {
        require(currentSupply + _qty < maxSupply, "Max supply exceed");

        for (uint256 i = 0; i < _qty; i++) {
            _mint(msg.sender, mintId, 1, "");
            currentSupplies[mintId]++;
            currentSupply++;
            if (mintId < 8) {
                mintId++;
            } else {
                mintId = 1;
            }
        }
    }

    /**
     * @dev only owner can burn their own token
     */
    function burn(uint256 _id, uint256 _amount) external onlyOwner {
        _burn(msg.sender, _id, _amount);
        currentSupply -= _amount;
        currentSupplies[_id] -= _amount;
    }
}
