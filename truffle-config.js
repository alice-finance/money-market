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
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    extdev: {
      provider: () => {
        const provider = new LoomTruffleProvider(
          process.env.CHAIN_ID,
          process.env.WRITE_URL,
          process.env.READ_URL,
          process.env.ADMIN_PRIVATE_KEY
        );
        const engine = provider.getProviderEngine();
        engine.addCustomMethod("web3_clientVersion", () => "");
        return provider;
      },
      network_id: "*"
    }
  },
  // mocha: {
  //   reporter: 'eth-gas-reporter',
  //   reporterOptions : {
  //     currency: 'USD',
  //     gasPrice: 20
  //   }
  // },
  compilers: {
    solc: {
      version: "0.5.8",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200
        }
      },
      evmVersion: "byzantium" // Need to set 'byzantium' due to PlasmaChain EVM version
    }
  },
  plugins: ["truffle-security"]
};
