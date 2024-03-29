// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DapsToken is ERC20 {
    address private admin;
    mapping(address => bool) private minters;
    uint256 public maxSupply = 300000000;

    constructor() ERC20("DapsToken", "DPST") {
        admin = msg.sender;
    }

    function setMaxSupply(uint256 newMaxSupply) public adminOnly {
        maxSupply = newMaxSupply;
    }

    function setMinter(address _minter) public adminOnly {
        minters[_minter] = true;
    }

    function devMint(address to, uint256 amount) public adminOnly {
        uint256 totalSupply = totalSupply();

        require(totalSupply + amount <= maxSupply, "reached max supply");

        _mint(to, amount);
    }

    function mint(address to, uint256 amount) public {
        require(minters[msg.sender], "minter only");

        uint256 totalSupply = totalSupply();

        require(totalSupply + amount <= maxSupply, "reached max supply");

        _mint(to, amount);
    }

    function burn(address msgSender, uint256 amount) external {
        _burn(msgSender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    modifier adminOnly() {
        require(admin == msg.sender, "not admin");
        _;
    }
}
