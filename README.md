# Money Market

> Decentralized Platform for Savings and Loan.

Alice Finance is Decentralized Money Market for everyone, allowing users to save their assets or borrow assets from it.

This repository contains Solidity contracts for Alice Finance.



## Deployed Addresses

All contracts are deployed on Loom Network's [PlasmaChain](https://loomx.io/developers/en/intro-to-loom.html#what-is-plasmachain).

| Contract                      | Address                                                      |
| ----------------------------- | ------------------------------------------------------------ |
| MoneyMarket                   | [`0x1Fe7A4F1F8b8528c4cf55990f78cB38d203ADE73`](https://loom-blockexplorer.dappchains.com/address/0x1fe7a4f1f8b8528c4cf55990f78cb38d203ade73/transactions) |
| SavingsInterestCalculatorV1   | [`0xBfe5fc58c3F12A5dd750a5D686DC1Ae8095c279B`](https://loom-blockexplorer.dappchains.com/address/0xbfe5fc58c3f12a5dd750a5d686dc1ae8095c279b/transactions) |
| InvitationOnlySavings         | [`0x3D21c813B601245cA5CF4E443bAd75627f3e45c3`](https://loom-blockexplorer.dappchains.com/address/0x3d21c813b601245ca5cf4e443bad75627f3e45c3/transactions) |
| ZeroSavingsInterestCalculator | [`0x60609A86Adfd790DA384c420C97f8d798e99ca4b`](https://loom-blockexplorer.dappchains.com/address/0x60609a86adfd790da384c420c97f8d798e99ca4b/transactions) |

And these are addresses of the assets we are using in Money Market

| Asset          | Network     | Address                                                      |
| -------------- | ----------- | ------------------------------------------------------------ |
| DAI Stablecoin | Ethereum    | [`0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359`](https://etherscan.io/address/0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359) |
|                | PlasmaChain | [`0xc377ce132f561364390974af13d4715f8b744319`](https://loom-blockexplorer.dappchains.com/address/0xc377ce132f561364390974af13d4715f8b744319/transactions) |

## Development

First, install Node.js and yarn. Then grep the source code.

### Get the source

Fork this repo and clone it to your local machine:

```shell
$ git clone git@github.com:your-username/money-market.git
```

Once git clone is done, use yarn to install dependencies:

```shell
$ yarn install
```

### Deploy

To deploy, we use truffle. 

```shell
$ npx truffle deploy 
```

If you want to deploy contracts to testnet, you need `.env` file. Use `.env.sample` to make your own `.env` file.

### Test

To run tests, run command below:

```bash
$ yarn test
```

To get coverage report, run command below:

```shell
$ yarn test:coverage
```

## Contributing

We always appreciate your contributions. Please create an issue in this repository to report bugs or suggestions.

If you have security concerns or discovered problems related to security, please contact us on Telegram - [Alice Developers](https://t.me/alicefinancedevs).



## License

Money Market is licensed under the [MIT License](/LICENSE).
