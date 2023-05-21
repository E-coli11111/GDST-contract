import { ethers } from "ethers";
import { utils } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";

const provider = new JsonRpcProvider();
const sk = "1cccbfee70391607dc222d327be27a94f911b39b9ae4264e89fecd6038fb65c5";
const wallet = new ethers.Wallet(sk, provider);
const file = "this is a file";
const filehash = utils.arrayify(utils.hashMessage(file));
console.log(filehash);
console.log(utils.hashMessage(file));

let sig = wallet.signMessage(file);
let signature = sig.then((signature) => {
    console.log(signature);
    console.log(utils.recoverAddress(filehash, signature));
},(reason) => {
    console.error();
});
console.log(wallet.address)
    // 0a6f169bd2c0e260b8783634873cdd54d10df473bbd001530c926f9675724dfd