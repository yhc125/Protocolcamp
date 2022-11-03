const ethers = require("ethers")
const { Framework } = require("@superfluid-finance/sdk-core")
const EmploymentFactoryABI =
    require("../artifacts/contracts/EmploymentFactory.sol/EmploymentFactory.json").abi
require("dotenv").config()

//place deployed address of the loan factory here...
const EmploymentFactoryAddress = "0xf626d07439dB0cE8693F7D2E5118D2dE6d25b4de"

//NOTE: this is set as the goerli url, but can be changed to reflect your RPC URL and network of choice
const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function main() {
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    })

    const employee = sf.createSigner({
        privateKey: process.env.EMPLOYEE_PRIVATE_KEY,
        provider: customHttpProvider
    })

    const employer = sf.createSigner({
        privateKey: process.env.EMPLOYER_PRIVATE_KEY,
        provider: customHttpProvider
    })

    const daix = await sf.loadSuperToken("fDAIx") //get fDAIx on goerli

    const employmentFactory = new ethers.Contract(
        EmploymentFactoryAddress,
        EmploymentFactoryABI,
        customHttpProvider
    )

    await employmentFactory
        .connect(employer)
        .createNewEmployment(
            ethers.utils.parseEther("1000"), //borrow amount = 1000 dai
            employer.address, //address of employer who will be effectively whitelisted in this case
            employee.address, // address of borrower
            daix.address, //daix address - this is the token we'll be using: borrowing in and paying back
            sf.settings.config.hostAddress //address of host
        )
        .then(tx => {
            console.log(
                "deployment successful! here is your tx hash: ",
                tx.hash
            )
        })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
