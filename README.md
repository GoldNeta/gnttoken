# Goldneta Token

## Summary

info | data
-|-
Name | Goldneta Token
Symbol | GNT
Decimal Places | 18
Max Supply | 1,000,000,000
Chain | Polygon Mainnet
Address | `0x8E3F56E2414AA427a211C69A3a20124E351baec1`

## Distribution

Distribution symbol | Name | Details | Max Supply
-|-|-|-
`p2e` | play to earn | players will earn GNT token as a reward for playing on the platform **(NOT YET LIVE)** | 400,000,000
`ecosystem` | ecosystem | GNT tokens used to operate the platform and its ecosystem | 200,000,000
`staking` | staking | GNT tokens used for the staking pool **(NOT YET LIVE)** | 200,000,000
`team` | developer team and advisors | Share of the development team and advisors | 100,000,000
`investors` | early investors pool | Share for early investors of the platform | 100,000,000

## Technical Details

The base contract for GNT is an extension of `ERC20.sol` from [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol) called `CappedDistributionToken.sol` which enforces a max total supply. When minting tokens it requires the mint to be accounted for which distribution.

`GNT.sol` is simply an initialization of the constructor of `CappedDistributionToken.sol`

`GNTP2E.sol` extends the contract to add logic surrounding the minting of the Play to Earn reward system. It integrates with the platform through a contract called `TreasuryPool.sol`

More details of the play to earn reward system coming soon!