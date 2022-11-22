const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers } = require("ethers");
const { daiABI } = require("../config");

const url = process.env.MUMBAI_URL

const customHttpProvider = new ethers.providers.JsonRpcProvider(url)

async function approveToken(amt) {
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
      const DAI = new ethers.Contract(
        "0x88271d333C72e51516B67f5567c728E702b3eeE8",
        daiABI,
        signer
      );
      try {
        console.log("approving DAI spend");
        await DAI.approve(
          signer.address,
          ethers.utils.parseEther(amt.toString())
        ).then(function (tx) {
          console.log(
            `Congrats, you just approved your DAI spend. You can see this tx at https://goerli.etherscan.io/tx/${tx.hash}`
          );
          console.log(tx.hash);
        });
      } catch (error) {
        console.error(error);
      }
}

approveToken()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })