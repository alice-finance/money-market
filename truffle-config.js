require("dotenv").config();
const LoomTruffleProvider = require("loom-truffle-provider");

module.exports = {
  networks: {
    coverage: {
      host: "localhost",
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01,
      network_id: "*"
    },
    // development: {
    //   host: "127.0.0.1",
    //   port: 8545,
    //   network_id: "*"
    // },
    extdev: {
      provider: () => {
        const provider = new LoomTruffleProvider(
          "extdev-plasma-us1",
          "http://extdev-plasma-us1.dappchains.com:80/rpc",
          "http://extdev-plasma-us1.dappchains.com:80/query",
          process.env.ADMIN_PRIVATE_KEY
        );
        const engine = provider.getProviderEngine();
        engine.addCustomMethod("web3_clientVersion", () => "");
        return provider;
      },
      network_id: "*"
    },
    plasma: {
      provider: () => {
        const provider = new LoomTruffleProvider(
          "default",
          "http://plasma.dappchains.com:80/rpc",
          "http://plasma.dappchains.com:80/query",
          process.env.ADMIN_PRIVATE_KEY
        );
        const engine = provider.getProviderEngine();
        engine.addCustomMethod("web3_clientVersion", () => "");
        return provider;
      },
      network_id: "*"
    }
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 20
    }
  },
  compilers: {
    solc: {
      version: "0.5.11",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      },
      evmVersion: "byzantium" // Need to set 'byzantium' due to PlasmaChain EVM version
    }
  },
  plugins: ["truffle-security"]
};
