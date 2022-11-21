const hre = require("hardhat");

async function main() {
  var MiPrimerToken = await hre.ethers.getContractFactory("MiPrimerToken");
  var name = "Mi Primer Token";
  var symbol = "MPRTKN";
  var miPrimerToken = await MiPrimerToken.deploy(name, symbol);
  var tx = await miPrimerToken.deployed();
  await tx.deployTransaction.wait(5);
  console.log(
    "Mi primer token esta publicado en el address",
    miPrimerToken.address
  );

  console.log("Empezo la verificaion");
  // script para verificacion del contrato
  await hre.run("verify:verify", {
    address: miPrimerToken.address,
    constructorArguments: [name, symbol],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
