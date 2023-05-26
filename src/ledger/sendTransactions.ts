import TransportNodeHid from "@ledgerhq/hw-transport-node-hid";
import Eth from "@ledgerhq/hw-app-eth";
import { ethers } from "ethers";
import { Interface } from "ethers/lib/utils";


const provider = new ethers.providers.JsonRpcProvider("https://rpc-mumbai.maticvigil.com/");
const ABI = require("GDST_metadata").output.abi
const iface = new Interface(ABI);


//连接ledger钱包
const connectLedger = async(): Promise<Eth> => {
    const transport = await TransportNodeHid.create();
    const eth = new Eth(transport);
    return eth;
}

const sendTransaction = async(e:Eth) => {
    const account = await e.getAddress("44'/60'/0'/0/0");
    console.log(account);
    console.log("--------------");

    //修改交易参数
    const data = iface.encodeFunctionData("increaseSupply",[10000000, account.address]);


    console.log(data);
    console.log("--------------");
    
    //修改交易参数
    const unsignedTx = {
        to: "0x813706e11B64039A2Af4b6458532Cf349514e34E",
        gasPrice: (await provider.getGasPrice())._hex,
        gasLimit: ethers.utils.hexlify(100000),
        nonce: await provider.getTransactionCount(account.address, "latest"),
        chainId: 80001,
        data: data,
        }
    
    const est_gas = await provider.estimateGas(unsignedTx);
    console.log("estimate gas:", est_gas);
    console.log("--------------");
    
    const serializedTx = ethers.utils.serializeTransaction(unsignedTx).slice(2);

    console.log(serializedTx);
    const signature = await e.signTransaction(
        "44'/60'/0'/0/0",
        serializedTx
        );
    console.log(signature);

    //Parse the signature

    const sig = {
        r: "0x" + signature.r,
        s: "0x" + signature.s,
        v: parseInt("0x"+signature.v),
        from: account.address
    }
    const signedTx = ethers.utils.serializeTransaction(unsignedTx,sig);
    const response = await provider.sendTransaction(signedTx);
    const receipt = await response.wait();
    console.log(receipt);
}

const main = async() => {
    const e = await connectLedger();
    await sendTransaction(e);    
}
main();
