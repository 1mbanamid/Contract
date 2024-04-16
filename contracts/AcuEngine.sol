// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AcuEngine {
    address public owner;
    uint constant DURATION = 2 days;

    uint constant FEE = 10; //10%

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;

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

    constructor() {
        owner = msg.sender;
    }

    function createAuction(
        uint _stratingPrice,
        uint _descountRate,
        string calldata _item,
        uint _duration
    ) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(
            _stratingPrice >= _duration * duration,
            "Incorrect starting price"
        );

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _stratingPrice,
            finalPrice: _stratingPrice,
            discountRate: _descountRate,
            startAt: block.timestamp, //now
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(
            auctions.length - 1,
            _item,
            _stratingPrice,
            duration
        );
    }

    function getPriceFor(uint index) public view returns (uint) {
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "Stopped!");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discount = cAuction.discountRate * elapsed;
        return cAuction.startingPrice - discount;
    }
    // function stop (uint index ){
    //     Auction storage cAuction  = auctions[index];
    //     cAuction.stopped = true;
    // }
    function buy(uint index) external payable {
        Auction storage cAuction = auctions[index];
        require(!cAuction.stopped, "Stopped!");
        require(block.timestamp < cAuction.endsAt, "Endet!");
        uint cPrice = getPriceFor(index);
        require(msg.value >= cPrice, "Not enough funds!");
        cAuction.stopped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        cAuction.seller.transfer(
            cPrice - ((cPrice*FEE) / 100) //fee 10%
        );

        emit AuctionEndet(index, cPrice, msg.sender);
    }
}
