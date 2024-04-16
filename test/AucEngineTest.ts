import { loadFixture, ethers, expect } from "./setup";

describe("AucEngine", function () {
    async function deploy() {
        const [owner, buyer, seller] = await ethers.getSigners();
        const Factory = await ethers.getContractFactory("AcuEngine");
        const aucEngine = await Factory.deploy();
        await aucEngine.waitForDeployment();

        return { owner, buyer, seller, aucEngine }
    }

    async function getTimestamp(bn: number) {
        return (
            await ethers.provider.getBlock(bn)
        )?.timestamp;

    }

    async function delay (ms:number) {
        return new Promise( resolve => setTimeout(resolve,ms))
    }

    it("set owner ", async function () {
        const { owner, buyer, seller, aucEngine } = await loadFixture(deploy);

        const correntOwner = await aucEngine.owner();
        expect(correntOwner).to.eq(owner.address);



    })

    it("create Auction", async function () {
        const { owner, buyer, seller, aucEngine } = await loadFixture(deploy)
        const duration = 60;

        const tx = await aucEngine.createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            duration
        );

        await tx.wait();

        const cAuction = await aucEngine.auctions(0);

        // console.log(cAuction);

        expect((cAuction).item).to.eq("test item");

        if (tx.blockNumber != null) {
            const ts = await getTimestamp(tx.blockNumber);
            if (ts != undefined) {
                expect(cAuction.endsAt).to.eq(ts + duration);
            } else {
                throw new Error("Block timestamp is undefined");
            }

        }
    })
    it("buy", async function () {
        const { owner, buyer, seller, aucEngine } = await loadFixture(deploy)

        const tx = await aucEngine.createAuction(
            ethers.parseEther("0.0001"),
            3,
            "test item",
            60
        );

        this.timeout(5000)// 5s
        delay(1000);




    })

})

