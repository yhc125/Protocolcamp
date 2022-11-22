const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("ethers");

const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function downgradeToken(amt) {
    const network = await customHttpProvider.getNetwork()

    const sf = await Framework.create({
        chainId: network.chainId,
        provider: customHttpProvider
    });

    const signer = sf.createSigner({
        privateKey: process.env.EMPLOYER_PRIVATE_KEY,
        provider: customHttpProvider
    });

    //fDAI on goerli: you can find network addresses here: https://docs.superfluid.finance/superfluid/developers/networks
    //note that this abi is the one found here: https://goerli.etherscan.io/address/0x88271d333C72e51516B67f5567c728E702b3eeE8
    const DAIx = await sf.loadSuperToken('fDAIx');

    console.log(DAIx.address);

    try {
        console.log(`Downgrading ${amt} fDAIx...`);
        const amtToDowngrade = ethers.utils.parseEther(amt.toString());
        const downgradeOperation = DAIx.downgrade({
            amount: amtToDowngrade.toString()
        });
        const downgradeTxn = await downgradeOperation.exec(signer);
        await downgradeTxn.wait().then(function (tx) {
            console.log(
                `
        Congrats - you've just downgraded DAIx to DAI!
        You can see this tx at https://goerli.etherscan.io/tx/${tx.transactionHash}
        Network: Goerli
        NOTE: you downgraded the dai of 0xDCB45e4f6762C3D7C61a00e96Fb94ADb7Cf27721.
        You can use this code to allow your users to do it in your project.
        Or you can downgrade tokens at app.superfluid.finance/dashboard.
      `
            );
        });
    } catch (error) {
        console.error(error);
    }
}

downgradeToken()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })