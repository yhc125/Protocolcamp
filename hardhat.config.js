require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
require("dotenv").config()

task("accounts", "Prints the list of accounts", async (_, hre) => {
    const accounts = await hre.ethers.getSigners()

    for (const account of accounts) {
        console.log(account.address)
    }
})

module.exports = {
    solidity: "0.8.14",
    settings: {
        optimizer: {
            enabled: true,
            runs: 1000
        }
    },
    // UNCOMMENT WHEN RUNNING SCRIPTS
    networks: {
        hardhat: {
            blockGasLimit: 100000000
        },
        goerli: {
            url: `${process.env.GOERLI_URL}`,
            accounts: [
                `${process.env.EMPLOYEE_PRIVATE_KEY}`,
                `${process.env.EMPLOYER_PRIVATE_KEY}`
            ]
        },
        mumbai: {
          url: `${process.env.MUMBAI_URL}`,
          accounts: [
            `${process.env.EMPLOYEE_PRIVATE_KEY}`,
            `${process.env.EMPLOYER_PRIVATE_KEY}`
          ],
          gas: 2100000,
          gasPrice: 8000000000
        }
    },
    namedAccounts: {
        deployer: 0
    }
}
