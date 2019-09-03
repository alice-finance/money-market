const fs = require("fs");
const { execSync } = require("child_process");

const ABI_PATH = "abis";
const NETWORKS_PATH = "networks";

if (!fs.existsSync(ABI_PATH)) {
  fs.mkdirSync(ABI_PATH);
}
fs.readdirSync(ABI_PATH).forEach(file => fs.unlinkSync(ABI_PATH + "/" + file));

if (!fs.existsSync(NETWORKS_PATH)) {
  fs.mkdirSync(NETWORKS_PATH);
}
fs.readdirSync(NETWORKS_PATH).forEach(file => fs.unlinkSync(NETWORKS_PATH + "/" + file));

fs.readdirSync("build/contracts").forEach(file => {
  const { abi, networks } = JSON.parse(fs.readFileSync("build/contracts/" + file, "utf-8"));
  for (id of Object.keys(networks)) {
    if (["5777"].includes(id)) {
      delete networks[id];
    }
  }
  if (networks && Object.keys(networks).length > 0) {
    if (abi && abi.length > 0) {
      const path = ABI_PATH + "/" + file;
      console.log("Building " + path + "...");
      fs.writeFileSync(path, JSON.stringify(abi, null, 2), "utf-8");
      execSync("git add " + path);
    }
    const path = NETWORKS_PATH + "/" + file;
    console.log("Building " + path + "...");
    fs.writeFileSync(path, JSON.stringify(networks, null, 2), "utf-8");
    execSync("git add " + path);
  }
});
