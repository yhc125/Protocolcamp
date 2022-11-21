const ethers = require("ethers")
const { Framework } = require("@superfluid-finance/sdk-core")
const EmploymentFactoryABI =
    require("../artifacts/contracts/EmploymentFactory.sol/EmploymentFactory.json").abi
require("dotenv").config()

//place deployed address of the loan factory here...
const EmploymentFactoryAddress = "0x8b1F22D13aFfC0Cc7f3bb7332707625cEfc2ca09"


//NOTE: this is set as the goerli url, but can be changed to reflect your RPC URL and network of choice
const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function main() {
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    })

    const employmentFactory = new ethers.Contract(
        EmploymentFactoryAddress,
        EmploymentFactoryABI,
        customHttpProvider
    )

    const employmentID = await employmentFactory.getEmployeeIdList()

    console.log(`The address of loan ${employmentID}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
