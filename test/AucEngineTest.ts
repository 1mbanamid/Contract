// Import necessary libraries and setup function from the setup file
import { loadFixture, ethers, expect } from "./setup";

// Describe block for the AcuEngine contract tests
describe("AucEngine", function () {
    // Function to deploy the contract
    async function deploy() {
        // Get signers
        const [owner, buyer, seller] = await ethers.getSigners();
        // Get contract factory and deploy the contract
        const Factory = await ethers.getContractFactory("AcuEngine");
        const aucEngine = await Factory.deploy();
        await aucEngine.waitForDeployment();

        return { owner, buyer, seller, aucEngine };
    }

    // Function to get timestamp from block number
    async function getTimestamp(bn: number) {
        return (
            await ethers.provider.getBlock(bn)
        )?.timestamp;
    }

    // Function to add delay
    async function delay(ms: number) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Test case to check if the owner is correctly set
    it("set owner ", async function () {
        const { owner, aucEngine } = await loadFixture(deploy);

        const currentOwner = await aucEngine.owner();
        expect(currentOwner).to.eq(owner.address);
    })

    // Test case to create an auction
    it("create Auction", async function () {
        const { owner, aucEngine } = await loadFixture(deploy);
        const duration = 60;

        const tx = await aucEngine.createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            duration
        );

        await tx.wait();

        const cAuction = await aucEngine.auctions(0);

        // Check if auction item matches the expected value
        expect((cAuction).item).to.eq("test item");

        // Check if auction endsAt timestamp is correctly set
        if (tx.blockNumber != null) {
            const ts = await getTimestamp(tx.blockNumber);
            if (ts != undefined) {
                expect(cAuction.endsAt).to.eq(ts + duration);
            } else {
                throw new Error("Block timestamp is undefined");
            }
        }
    })

    // Test case to allow buying an auction
    it("allow buy", async function () {
        const { seller, buyer, aucEngine } = await loadFixture(deploy)

        // Create an auction
        await aucEngine.connect(seller).createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            60
        );

        this.timeout(5000) // 5s
        delay(1000);

        // Purchase the auction
        const buyTx = await aucEngine.connect(buyer)
            .buy(0, { value: ethers.parseEther("0.0001") });

        const cAuction = await aucEngine.auctions(0);

        const finalPrice = cAuction.finalPrice;

        const sellerPrice = finalPrice - ((finalPrice * 10n) / 100n);

        // Check if seller's balance changes correctly after purchase
        await expect(() => buyTx)
            .to.changeEtherBalance(seller, sellerPrice)

        // Check if AuctionEndet event is emitted with correct arguments
        await expect(buyTx)
            .to.emit(aucEngine, 'AuctionEndet')
            .withArgs(0, finalPrice, buyer.address)

        // Check if buying the same auction again is reverted with 'Stopped!' message
        await expect(
            aucEngine.connect(buyer).buy(0, { value: ethers.parseEther("0.0001") })
        ).to.be.revertedWith('Stopped!')
    });

    // Test case for duration == 0
    it("duration == 0", async function () {
        const { seller, aucEngine } = await loadFixture(deploy);
        const tx = await aucEngine.connect(seller).createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            0
        );

        await tx.wait();

        const cAuction = await aucEngine.auctions(0);
        expect(cAuction.endsAt).to.eq(cAuction.startAt + (2n * 24n * 60n * 60n));
    });

    // Test case for exception if starting price >= discount rate * duration
    it("Exeption if starting price >= discount rate * duration ", async function () {
        const { aucEngine } = await loadFixture(deploy);
        await expect(
            aucEngine.createAuction(
                60,
                3,
                "test item",
                60
            )
        ).to.be.revertedWith('Incorrect starting price')
    });

    // Test case to check if auction cannot be purchased after it ends
    it("auction cannot be purchased after it ends", async function () {
        const { buyer, aucEngine } = await loadFixture(deploy);

        // Create an auction with short duration
        await aucEngine.createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            1 // 1 second duration
        );

        // Wait for the auction to end
        await delay(2000);

        // Attempt to purchase the ended auction
        await expect(
            aucEngine.connect(buyer).buy(0, { value: ethers.parseEther("0.0001") })
        ).to.be.revertedWith('Endet!');
    });

    // Test case to check if auction cannot be purchased if stopped
    it("auction cannot be purchased if stopped", async function () {
        const { seller, buyer, aucEngine } = await loadFixture(deploy);

        // Create an auction
        await aucEngine.connect(seller).createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            60
        );

        // Stop the auction
        await aucEngine.stopAuction(0);

        // Attempt to purchase the stopped auction
        await expect(
            aucEngine.connect(buyer).buy(0, { value: ethers.parseEther("0.0001") })
        ).to.be.revertedWith('Stopped!');
    });
})
