const ethers = require("ethers")
const { Framework } = require("@superfluid-finance/sdk-core")
const EmploymentABI =
    require("../artifacts/contracts/Employment.sol/Employment.json").abi
require("dotenv").config()
const { calculateFlowRate } = require("./calculateFlowRate");


//place deployed address of the loan factory here...
// 현재 id = 1에 대한 employmentAddress
const EmploymentAddress = "0xB68871F55cEC84a6cf118d55cbc5A499e027D1a8"


//place the ID of your loan here. Note that loanIds start at 1
const LoanId = 1
const amountInEther = 10;
//NOTE: this is set as the goerli url, but can be changed to reflect your RPC URL and network of choice
const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)


async function main() {
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    })

    const employer = sf.createSigner({
        privateKey: process.env.EMPLOYER_PRIVATE_KEY,
        provider: customHttpProvider
    })

    const DAIxContract = await sf.loadSuperToken("fDAIx");
    const DAIx = DAIxContract.address;

    const employment = new ethers.Contract(
        EmploymentAddress,
        EmploymentABI,
        customHttpProvider
    )

    try {
        const calculatedFlowRate = calculateFlowRate(amountInEther);
        console.log(calculatedFlowRate);

        await employment
            .connect(employer)
            .createFlowIntoContract(DAIx, calculatedFlowRate)
            .then(tx => {
                console.log(
                    "createFlowOperation successful! here is your tx hash: ",
                    tx.hash,
                    `https://mumbai.polygonscan.com/tx/${tx.hash}`
                )
            });

        console.log("Creating your stream...");


        console.log(
            `Congrats - you've just created a money stream!
      View Your Stream At: https://app.superfluid.finance/
      Network: Mumbai
      Super Token: DAIx
      Sender: ${employer.address},
      Receiver: ${EmploymentAddress},
      FlowRate: ${calculatedFlowRate}
      `
        );
    } catch (error) {
        console.log(
            "Hmmm, your transaction threw an error. Make sure that this stream does not already exist, and that you've entered a valid Ethereum address!"
        );
        console.error(error);
    }

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
