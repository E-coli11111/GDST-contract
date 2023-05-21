import { hdkey } from 'ethereumjs-wallet';
import { mnemonicToSeed } from "ethereum-cryptography/bip39";
// import { keccak } from 'ethereumjs-util'
// import { bufferToHex } from 'ethereumjs-util'


export const generate = async(index: number) => {
    const seed = await mnemonicToSeed("dad argue shy card ceiling worth taxi margin have need chat mutual");
    let hdwallet = hdkey.fromMasterSeed(seed);
    let wallet = hdwallet.deriveChild(index).getWallet();
    console.log("Address: " + wallet.getAddressString());
    console.log("Private Key: " + wallet.getPrivateKeyString());
}


let index = parseInt(process.argv[2]);
generate(index);
