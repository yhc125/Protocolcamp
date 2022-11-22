const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("ethers");

const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function upgradeToken(amt) {
  const network = await customHttpProvider.getNetwork()

  const sf = await Framework.create({
    chainId: network.chainId,
    provider: customHttpProvider
  });

  const signer = sf.createSigner({
    privateKey: process.env.EMPLOYER_PRIVATE_KEY,
    provider: customHttpProvider
  });

  const DAIx = await sf.loadSuperToken("fDAIx");

  try {
    console.log(`upgrading ${amt} DAI to DAIx`);
    const amtToUpgrade = ethers.utils.parseEther(amt.toString());
    const upgradeOperation = DAIx.upgrade({
      amount: amtToUpgrade.toString()
    });
    const upgradeTxn = await upgradeOperation.exec(signer);
    await upgradeTxn.wait().then(function (tx) {
      console.log(
        `
            Congrats - you've just upgraded DAI to DAIx!
          `
      );
      console.log(tx.hash);
    });
  } catch (error) {
    console.error(error);
  }
}

upgradeToken()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })