// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AcuEngine
 * @dev A smart contract for creating and managing auctions.
 */
contract AcuEngine {
    // State variables
    address public owner; // Address of the contract owner
    uint constant DURATION = 2 days; // Default duration for auctions
    uint constant FEE = 10; // Fee percentage charged to the seller on successful auction

    // Struct to store auction details
    struct Auction {
        address payable seller; // Address of the seller
        uint startingPrice; // Starting price of the auction
        uint finalPrice; // Final price of the auction
        uint startAt; // Timestamp when the auction starts
        uint endsAt; // Timestamp when the auction ends
        uint discountRate; // Rate at which the price decreases over time
        string item; // Description of the item being auctioned
        bool stopped; // Flag indicating if the auction has been stopped
    }

    // Array to store all auctions
    Auction[] public auctions;

    // Events
    event AuctionCreated(
        uint index,
        string _item,
        uint _startPrice,
        uint duration
    );

    event AuctionEndet(
        uint index,
        uint finalPrice,
        address buyer
    );

    // Constructor
    constructor() {
        owner = msg.sender; // Set the contract owner
    }

    /**
     * @dev Function to create a new auction.
     * @param _startingPrice Starting price of the auction.
     * @param _discountRate Rate at which the price decreases over time.
     * @param _item Description of the item being auctioned.
     * @param _duration Duration of the auction in seconds.
     */
    function createAuction(
        uint _startingPrice,
        uint _discountRate,
        string calldata _item,
        uint _duration
    ) external {
        // Set the auction duration, default to 2 days if not provided
        uint duration = _duration == 0 ? DURATION : _duration;

        // Ensure that the starting price is greater than or equal to the discounted price at the end of the auction
        require(
            _startingPrice >= _discountRate * duration,
            "Incorrect starting price"
        );

        // Create a new auction with the provided details
        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        // Add the new auction to the array
        auctions.push(newAuction);

        // Emit an event to notify that a new auction has been created
        emit AuctionCreated(
            auctions.length - 1,
            _item,
            _startingPrice,
            duration
        );
    }

    /**
     * @dev Function to get the current price for a given auction.
     * @param index Index of the auction in the array.
     * @return Current price of the auction.
     */
    function getPriceFor(uint index) public view returns (uint) {
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "Stopped!"); // Ensure the auction is not stopped
        uint elapsed = block.timestamp - cAuction.startAt; // Calculate elapsed time since the auction started
        uint discount = cAuction.discountRate * elapsed; // Calculate the discount based on the elapsed time
        return cAuction.startingPrice - discount; // Calculate and return the current price
    }

    /**
     * @dev Function to stop an ongoing auction.
     * @param index Index of the auction in the array.
     */
    function stopAuction(uint index) external {
        auctions[index].stopped = true; // Set the stopped flag to true
    }

    /**
     * @dev Function to buy an item from an auction.
     * @param index Index of the auction in the array.
     */
    function buy(uint index) external payable {
        Auction storage cAuction = auctions[index]; // Get a reference to the auction
        require(!cAuction.stopped, "Stopped!"); // Ensure the auction is not stopped
        require(block.timestamp < cAuction.endsAt, "Endet!"); // Ensure the auction has not ended
        uint cPrice = getPriceFor(index); // Get the current price of the auction
        require(msg.value >= cPrice, "Not enough funds!"); // Ensure the buyer has sent enough funds

        // Update auction details
        cAuction.stopped = true; // Set the stopped flag to true
        cAuction.finalPrice = cPrice; // Set the final price of the auction

        // Calculate refund amount if any
        uint refund = msg.value - cPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund); // Transfer excess funds back to the buyer
        }

        // Transfer funds to the seller after deducting the fee
        cAuction.seller.transfer(
            cPrice - ((cPrice * FEE) / 100) // Calculate the seller's share after deducting the fee
        );

        // Emit an event to notify that the auction has ended
        emit AuctionEndet(index, cPrice, msg.sender);
    }
}
