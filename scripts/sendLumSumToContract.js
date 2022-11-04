const { Framework } = require("@superfluid-finance/sdk-core")
const { ethers } = require("ethers")
const EmploymentABI =
    require("../artifacts/contracts/Employment.sol/Employment.json").abi
require("dotenv").config()

//to run this script:
//1) Make sure you've created your own .env file
//2) Make sure that you have your network and accounts specified in hardhat.config.js
//3) Make sure that you add the address of your own money router contract
//4) Make sure that you change the 'amount' field in the sendLumpSumToContract function to reflect the proper amount
//3) run: npx hardhat run scripts/sendLumpSumToContract.js --network goerli
const EmploymentAddress = "0x5CE84E535bc749eaF40d7f8E7F9244700f2a09a6"

const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    //NOTE - make sure you add the address of the previously deployed money router contract on your network
 
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    })

    const employer = sf.createSigner({
        privateKey: process.env.EMPLOYER_PRIVATE_KEY,
        provider: customHttpProvider
    })

    const employment = new ethers.Contract(
        EmploymentAddress,
        EmploymentABI,
        customHttpProvider
    )

    const daix = await sf.loadSuperToken("fDAIx")

    //call money router send lump sum method from signers[0]
    await employment
        .connect(employer)
        .sendLumpSumToContract(daix.address, ethers.utils.parseEther("500"), {gasLimit : 100000})
        .then(function (tx) {
            console.log(`
        Congrats! You just successfully sent funds to the money router contract. 
        Tx Hash: ${tx.hash}
    `)
        })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error)
    process.exitCode = 1
})