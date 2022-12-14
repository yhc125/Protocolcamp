const ethers = require("ethers")
const { Framework } = require("@superfluid-finance/sdk-core")

const EmploymentAddress = "0x46a48497F15221Bdd1D01fBeE881F620480E573a"

const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function updateFlowPermissions(
    operator = EmploymentAddress,
    flowRateAllowance = "38580246913580",
    permissionType = 7
) {
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    })
    // consol  e.log(sf.settings.config);

    const employer = sf.createSigner({
        privateKey: process.env.EMPLOYEE_PRIVATE_KEY,
        provider: customHttpProvider
    })

    const DAIxContract = await sf.loadSuperToken("fDAIx");
    const DAIx = DAIxContract.address;
    
    console.log(DAIx);
    // console.log(sf.cfaV1);
    try {
        const updateFlowOperatorOperation = sf.cfaV1.updateFlowOperatorPermissions({
            flowOperator: operator,
            permissions: permissionType,
            flowRateAllowance: flowRateAllowance,
            superToken: DAIx
            // userData?: string
        });

        console.log("Updating your flow permissions...");


        const result = await updateFlowOperatorOperation.exec(employer);

        console.log(result);

        console.log(
            `Congrats - you've just updated flow permissions for ${EmploymentAddress}
      Network: Mumbai
      Super Token: DAIx
      Operator: ${operator}
      Permission Type: ${permissionType},
      Flow Rate Allowance: ${flowRateAllowance}
      `
        );
    } catch (error) {
        console.log(
            "Hmmm, your transaction threw an error. Make sure that this stream does not already exist, and that you've entered a valid Ethereum address!"
        );
        console.error(error);
    }
}

updateFlowPermissions()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })