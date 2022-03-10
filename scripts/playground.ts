import { ethers } from "ethers";
import CompiledCore from "../artifacts/contracts/Core.sol/Core.json";
import CompiledCupa from "../artifacts/contracts/CUPA.sol/CUPA.json";

const addresses = {
  core: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
  cupa: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  guard: "0x92fC907fF4BCc88920651a863035906D0F73402c",
  owner: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  ownerPrivateKey:
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
  account1: {
    address: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    privateKey: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
  }
};

const provider = new ethers.providers.JsonRpcProvider();
const signer = new ethers.Wallet(addresses.account1.privateKey).connect(provider)
// console.log(signer)
async function main() {
  const CoreInstance = new ethers.Contract(
    addresses.core,
    CompiledCore.abi,
    signer
  );

  const CupaInstance = new ethers.Contract(
    addresses.cupa,
    CompiledCupa.abi,
    signer
  );

  const testEstimateGas = await CoreInstance.estimateGas.guardAddress();
  console.log(testEstimateGas.toString());

  const newBalance = await CupaInstance.getTestToken();
  console.log(newBalance);

  const balance = await CupaInstance.balanceOf(addresses.owner);
  console.log("Balance is", balance.toString());

  const executionBlock = (await provider.getBlockNumber()) + 20;
  const tokenAddress = addresses.cupa;
  const from = addresses.owner;
  const to = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8";
  const value = ethers.utils.parseEther("0.1");
}
main();
