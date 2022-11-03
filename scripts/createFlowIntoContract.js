const ethers = require("ethers")
const { Framework } = require("@superfluid-finance/sdk-core")
const EmploymentABI =
    require("../artifacts/contracts/Employment.sol/Employment.json").abi
require("dotenv").config()


//place deployed address of the loan factory here...
// 현재 id = 1에 대한 employmentAddress
const EmploymentAddress = "0xd22254B20aEB002380C28bB2Bb0149b462720bca"


//place the ID of your loan here. Note that loanIds start at 1
const LoanId = 1
const flowRate = 10;
//NOTE: this is set as the goerli url, but can be changed to reflect your RPC URL and network of choice
const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

function calculateFlowRate(amountInEther) {
    if (
      typeof Number(amountInEther) !== "number" ||
      isNaN(Number(amountInEther)) === true
    ) {
      console.log(typeof Number(amountInEther));
      alert("You can only calculate a flowRate based on a number");
      return;
    } else if (typeof Number(amountInEther) === "number") {
      const monthlyAmount = ethers.utils.parseEther(amountInEther.toString());
      const calculatedFlowRate = Math.floor(monthlyAmount / 3600 / 24 / 30);
      return calculatedFlowRate;
    }
}

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
        const calculatedFlowRate = calculateFlowRate(flowRate);

        await employment
            .connect(employer)
            .createFlowIntoContract(DAIx, calculatedFlowRate, { 
                gasLimit: 100000,
               })
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
