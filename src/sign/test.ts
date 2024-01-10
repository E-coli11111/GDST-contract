import { providers } from "ethers";
import { Contract } from "ethers";
const Goerli_abi = [{ "inputs": [{ "internalType": "address", "name": "account", "type": "address" }], "name": "balanceOf", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }]
const provider = new providers.JsonRpcProvider("https://eth-goerli.api.onfinality.io/public")
const contractAddress = "0x0A5DAd97E0686A6d3568B2c447A0D022a80b6836"
const account = "0x0A5DAd97E0686A6d3568B2c447A0D022a80b6836"
let tokenContract = new Contract(contractAddress, Goerli_abi, provider);

tokenContract.balanceOf(account).then((balance: any) => {
    console.log(balance, "balance")
})
