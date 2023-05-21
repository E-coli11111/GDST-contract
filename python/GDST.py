import json
from web3 import Web3, HTTPProvider


w3 = Web3(HTTPProvider('https://goerli.infura.io/v3/5d138d63a6df477e8c95a89a10884daa')) #选择区块链
#abi是合约能够调用的所有接口的信息
with open("../contracts/artifacts/GDST_metadata.json") as f:
    metadata = json.load(f)
abi = metadata["output"]["abi"]
print(abi)
GDST_contract = w3.eth.contract(address="0x0A5DAd97E0686A6d3568B2c447A0D022a80b6836", abi=abi) #创建合约对象

#调用格式为 合约对象.functions.合约函数名(调用参数).call({'from':发起人地址})
def totalSupply():
    return GDST_contract.functions.totalSupply().call({'from':'0x974b1829D4EEEe518afeaB23f8a3d6c53A651cb3'})

def balanceOf(address):
    return GDST_contract.functions.balanceOf(address).call({'from':'0x974b1829D4EEEe518afeaB23f8a3d6c53A651cb3'})

if __name__ == "__main__":
    address = "0x974b1829D4EEEe518afeaB23f8a3d6c53A651cb3"
    print("GDST发行量 =", totalSupply())
    print("用户", address, "持有GDST数量 =", balanceOf(address))