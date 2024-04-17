# Dutch Auction Smart Contract

## Overview

This repository contains a Solidity smart contract for implementing a Dutch auction, along with TypeScript tests written using Hardhat.

### What is a Dutch Auction?

A Dutch auction is a type of auction where the price of an item is gradually lowered until a buyer is willing to accept the current price. Unlike traditional auctions where the price starts low and increases with bids, in a Dutch auction, the price starts high and decreases over time until a buyer makes a purchase.

## Contract Details

The main smart contract in this repository is called `AcuEngine`. Here's a brief overview of its functionality:

- **Auction Creation**: Allows the creation of new auctions with specified starting prices, durations, and item descriptions.
- **Price Calculation**: Calculates the current price of an auction based on its starting price, duration, and discount rate.
- **Auction Stoppage**: Allows the owner to stop an ongoing auction.
- **Item Purchase**: Enables buyers to purchase items from an auction by sending the required funds.

## TypeScript Tests

The repository also includes TypeScript tests to ensure the functionality of the smart contract. These tests are written using Hardhat and cover various scenarios such as:

- Setting the owner of the contract.
- Creating auctions with different parameters.
- Buying items from auctions.
- Handling edge cases such as auctions with zero duration or incorrect starting prices.

## Usage

To use the smart contract and run the tests, follow these steps:

1. Clone the repository to your local machine.
2. Install dependencies using `npm install`.
3. Run Hardhat tests using `npx hardhat test`.

## Contributing

Contributions to improve the functionality, documentation, or tests of the smart contract are welcome. Please fork the repository, make your changes, and submit a pull request.

## License

This smart contract is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
