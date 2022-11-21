const { Framework } = require("@superfluid-finance/sdk-core")
const { assert } = require("chai")
const { ethers, network } = require("hardhat")
const EmploymentArtifact = require("../artifacts/contracts/Employment.sol/Employment.json")
const { deployFramework, deployWrapperSuperToken, calculateFlowRate } = require("./util/deploy-sf")

let contractsFramework
let sf
let dai
let daix
let employee
let employer
let hardhatEmploymentFactory
let employment
let flowRateAllowance = "38580246913580"

const alotOfEth = ethers.utils.parseEther("100000")

before(async function () {
    //get accounts from hardhat
    [admin, employee, employer] = await ethers.getSigners()

    contractsFramework = await deployFramework(admin)

    //initialize the superfluid framework...put custom and web3 only bc we are using hardhat locally
    sf = await Framework.create({
        chainId: 31337,
        provider: admin.provider,
        resolverAddress: contractsFramework.resolver,
        protocolReleaseVersion: "test"
    })

    const tokenDeployment = await deployWrapperSuperToken(
        admin,
        contractsFramework.superTokenFactory,
        "fDAI",
        "fDAI"
    )

    dai = tokenDeployment.underlyingToken
    daix = tokenDeployment.superToken

    const employmentFactory = await ethers.getContractFactory("employmentFactory", admin) 
    hardhatEmploymentFactory = await employmentFactory.deploy()
    
    await hardhatEmploymentFactory.deployed()

    let salaryFlowRate = calculateFlowRate(10);
    let employeeId = 125;

    await hardhatEmploymentFactory.createNewEmployment(
        salaryFlowRate,
        employeeId,
        employer.address, //address of employer
        employee.address, //address of borrower
        daix.address,
        sf.settings.config.hostAddress
    )

    let employmentAddress = await hardhatEmploymentFactory.getEmploymentById(employeeId);

    employment = new ethers.Contract(employmentAddress, EmploymentArtifact.abi, admin)
})

beforeEach(async function () {
    await dai.mint(admin.address, alotOfEth)

    await dai.mint(employer.address, alotOfEth)

    await dai.mint(employee.address, alotOfEth)

    await dai.approve(daix.address, alotOfEth)

    await dai.connect(employer).approve(daix.address, alotOfEth)

    await dai.connect(employee).approve(daix.address, alotOfEth)

    await daix.upgrade(alotOfEth)

    await daix.connect(employer).upgrade(alotOfEth)

    await daix.connect(employee).upgrade(alotOfEth)

    await daix.transfer(employment.address, alotOfEth)
})

describe("EmploymentFactory deployment", async function () {
    it("0 deloys correctly", async function () {

        let employeeId = 125;

        let actualEmploymentIdList = await employment.getEmployeeIdList();


        assert.exists(
            employeeId,
            actualEmploymentIdList,
            "employeeId does not exist to intended employeeId"
        )

    })

    it("1 SendLumSumIntoContract works correctly", async function () {
        
    })

    it("2 Create flow into contract works correctly", async function () {

        const aclAgreement = sf.cfaV1.updateFlowOperatorPermissions({
            flowOperator: employment.address,
            permissions: 7,
            flowRateAllowance: flowRateAllowance,
            superToken: daix.address
        })

        await aclAgreement.exec(employer)

        await employment.connect(employer).createFlowIntoContract({
            superToken: daix.address,
            flowRate: flowRateAllowance
        }) 

        let employerNetFlowRate = await sf.cfaV1.getNetFlow({
            superToken: daix.address,
            account: employer.address,
            providerOrSigner: employer
        })

        assert.equal(employerNetFlowRate, flowRateAllowance);
    })

})

