// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Lender {
    address paymentTokenAddress;

    event ERC721LendUpdated(
        address lenderAddress,
        address tokenAddress,
        uint256 tokenId
    );

    struct ERC721ForLend {
        uint256 lendDuration;
        uint256 initialWorth;
        uint256 earningGoal;
        uint256 borrowedAtTimestamp;
        address borrower;
        bool lenderClaimedCollateral;
        uint256 index;
    }

    struct ERC721TokenInit {
        address lenderAddress;
        address tokenAddress;
        uint256 tokenId;
        bool listed;
    }

    ERC721TokenInit[] allNFTToLend;
    // mapping for token address => tokenId =>  lender address => Information
    mapping(address => mapping(uint256 => mapping(address => ERC721ForLend)))
        public NFTForLend;

    mapping(address => ERC721TokenInit[]) allBorrowedNFT;
    mapping(address => uint256) lenderBalance;

    function listNFT(
        address _NFTAddress,
        uint256 _tokenId,
        uint256 _lendDuration,
        uint256 _initialWorth,
        uint256 _earningGoals
    ) public {
        require(
            _initialWorth > 0,
            "Lending: Initial token worth must be above 0"
        );
        require(_earningGoals > 0, "Lending: Earning goal must be above 0");
        require(_lendDuration > 0, "Lending: Lending duration must be above 0");
        require(
            NFTForLend[_NFTAddress][_tokenId][msg.sender].borrower ==
                address(0),
            "Lending: Cannot change settings, NFT already lent"
        );
        require(
            NFTForLend[_NFTAddress][_tokenId][msg.sender]
                .lenderClaimedCollateral == false,
            "Lending: Collateral already claimed"
        );

        // transfer NFT to this contract
        IERC721(_NFTAddress).transferFrom(msg.sender, address(this), _tokenId);

        allNFTToLend.push(
            ERC721TokenInit(msg.sender, _NFTAddress, _tokenId, true)
        );

        NFTForLend[_NFTAddress][_tokenId][msg.sender] = ERC721ForLend(
            _lendDuration,
            _initialWorth,
            _earningGoals,
            0,
            address(0),
            false,
            allNFTToLend.length - 1
        );

        emit ERC721LendUpdated(msg.sender, _NFTAddress, _tokenId);
    }

    function borrowNFT(
        address _lenderAddress,
        address _NFTAddress,
        uint256 _tokenId
    ) public {
        require(
            NFTForLend[_NFTAddress][_tokenId][_lenderAddress].borrower ==
                address(0),
            "Borrowing: Already lent"
        );
        require(
            NFTForLend[_NFTAddress][_tokenId][_lenderAddress].earningGoal > 0,
            "Borrowing: Lender did not set earning goal yet"
        );
        require(
            NFTForLend[_NFTAddress][_tokenId][_lenderAddress].initialWorth > 0,
            "Borrowing: Lender did not set initial worth yet"
        );

        IERC20 _payToken = IERC20(paymentTokenAddress);
        uint256 _requiredSum = calculateLendSum(
            _lenderAddress,
            _NFTAddress,
            _tokenId
        );
        uint256 _allowedCollateral = _payToken.allowance(
            msg.sender,
            address(this)
        );
        require(
            _allowedCollateral >= _requiredSum,
            "Borrowing: Not enough collateral received"
        );

        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _requiredSum
        );

        IERC721(_NFTAddress).transferFrom(address(this), msg.sender, _tokenId);
        NFTForLend[_NFTAddress][_tokenId][_lenderAddress].borrower = msg.sender;
        NFTForLend[_NFTAddress][_tokenId][_lenderAddress]
            .borrowedAtTimestamp = block.timestamp;

        uint256 index = NFTForLend[_NFTAddress][_tokenId][_lenderAddress].index;

        allNFTToLend[index].listed = false;
        allBorrowedNFT[msg.sender].push(
            ERC721TokenInit(_lenderAddress, _NFTAddress, _tokenId, true)
        );

        emit ERC721LendUpdated(_lenderAddress, _NFTAddress, _tokenId);
    }

    function stopborrowNFT(
        address _lenderAddress,
        address _NFTAddress,
        uint256 _tokenId
    ) public {
        // assuming token transfer is approved
        address _borrower = NFTForLend[_NFTAddress][_tokenId][_lenderAddress]
            .borrower;
        require(
            _borrower == msg.sender,
            "Borrowing: Can be stopped only by active borrower"
        );
        require(
            NFTForLend[_NFTAddress][_tokenId][_lenderAddress]
                .lenderClaimedCollateral == false,
            "Borrowing: Too late, lender claimed collateral"
        );

        IERC721(_NFTAddress).transferFrom(msg.sender, address(this), _tokenId);

        uint256 _initialWorth = NFTForLend[_NFTAddress][_tokenId][
            _lenderAddress
        ].initialWorth;

        IERC20(paymentTokenAddress).transfer(_borrower, _initialWorth);

        NFTForLend[_NFTAddress][_tokenId][_lenderAddress].borrower = address(0);
        NFTForLend[_NFTAddress][_tokenId][_lenderAddress]
            .borrowedAtTimestamp = 0;

        uint256 index = NFTForLend[_NFTAddress][_tokenId][_lenderAddress].index;
        allNFTToLend[index].listed = true;

        // lender earning from lending NFT
        lenderBalance[_lenderAddress] =
            (NFTForLend[_NFTAddress][_tokenId][_lenderAddress].earningGoal *
                95) /
            100;

        uint256 findIndex = findArrayIndex(
            _lenderAddress,
            _NFTAddress,
            _tokenId,
            allBorrowedNFT[msg.sender]
        );

        while (findIndex < allBorrowedNFT[msg.sender].length - 1) {
            allBorrowedNFT[msg.sender][findIndex] = allBorrowedNFT[msg.sender][
                findIndex + 1
            ];
            findIndex++;
        }

        allBorrowedNFT[msg.sender].pop();

        emit ERC721LendUpdated(_lenderAddress, _NFTAddress, _tokenId);
    }

    function withdrawEarning() public {
        uint256 amount = lenderBalance[msg.sender];
        IERC20(paymentTokenAddress).transfer(msg.sender, amount);
        lenderBalance[msg.sender] = 0;
    }

    function cancelListing(address _NFTAddress, uint256 _tokenId) public {
        require(
            NFTForLend[_NFTAddress][_tokenId][msg.sender].borrower ==
                address(0),
            "Lending: Cannot cancel if lent"
        );
        require(
            NFTForLend[_NFTAddress][_tokenId][msg.sender]
                .lenderClaimedCollateral == false,
            "Lending: Collateral claimed"
        );
        IERC721(_NFTAddress).transferFrom(address(this), msg.sender, _tokenId);
        NFTForLend[_NFTAddress][_tokenId][msg.sender] = ERC721ForLend(
            0,
            0,
            0,
            0,
            address(0),
            false,
            0
        ); // reset details

        uint256 index = NFTForLend[_NFTAddress][_tokenId][msg.sender].index;
        allNFTToLend[index].listed = false;
    }

    function claimColateral(address _NFTAddress, uint256 _tokenId) public {
        uint256 _borrowedAtTimestamp = NFTForLend[_NFTAddress][_tokenId][
            msg.sender
        ].borrowedAtTimestamp;
        uint256 _lenderDuration = NFTForLend[_NFTAddress][_tokenId][msg.sender]
            .lendDuration;
        require(
            isDurationExpired(_borrowedAtTimestamp, _lenderDuration),
            "Claim: Cannot claim before lending expired"
        );

        require(
            NFTForLend[_NFTAddress][_tokenId][msg.sender]
                .lenderClaimedCollateral == false,
            "Claim: Already claimed"
        );

        NFTForLend[_NFTAddress][_tokenId][msg.sender]
            .lenderClaimedCollateral = true;

        uint256 collateralAmount = calculateLendSum(
            msg.sender,
            _NFTAddress,
            _tokenId
        );

        IERC20(paymentTokenAddress).transfer(msg.sender, collateralAmount);
    }

    function calculateLendSum(
        address _lenderAddress,
        address _tokenAddress,
        uint256 _tokenId
    ) public view returns (uint256) {
        uint256 _earningGoal = NFTForLend[_tokenAddress][_tokenId][
            _lenderAddress
        ].earningGoal;
        uint256 _initialWorth = NFTForLend[_tokenAddress][_tokenId][
            _lenderAddress
        ].initialWorth;
        return _initialWorth + _earningGoal;
    }

    function isDurationExpired(
        uint256 _borrowedAtTimestamp,
        uint256 _lendDuration
    ) public view returns (bool) {
        uint256 secondsPassed = block.timestamp - _borrowedAtTimestamp;
        uint256 secondsDuration = _lendDuration * 60 * 60;
        return secondsDuration > secondsPassed;
    }

    function findArrayIndex(
        address _lenderAddress,
        address _NFTAddress,
        uint256 _tokenId,
        ERC721TokenInit[] memory array
    ) private pure returns (uint256) {
        uint256 index = 0;

        while (
            array[index].lenderAddress != _lenderAddress &&
            array[index].tokenAddress != _NFTAddress &&
            array[index].tokenId != _tokenId
        ) {
            index++;
        }

        return index;
    }
}
