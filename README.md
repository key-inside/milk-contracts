# MiL.k Smart Contracts

This repository contains the core smart contracts for the MiL.k service.

- [MiL.k Alliance](https://milkalliance.io/)
- [MiL.k Service](https://milkplay.com/?lang=en)

## Contracts

### Token

- [**Token**](./src/Token.sol) : A burnable and permitable ERC20 Token with 8 decimals.

### Account Abstraction ([EIP-4337](https://eips.ethereum.org/EIPS/eip-4337))

- [**Account**](./src/Account.sol): A multi-sig account.
- [**AccountFactory**](./src/AccountFactory.sol)
- [**EntryPoint**](./src/EntryPoint.sol)

## Usage

### Requirements

- [Foundry](https://github.com/foundry-rs/foundry)

### Install Dependency

```shell
$ forge soldeer install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## License

All smart contracts are released under GPL-3.0