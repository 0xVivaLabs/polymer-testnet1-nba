# NBA Bet

This is an example xdapp powered by [Polymer](https://polymerlabs.org/), which allows users to bet on NBA matches on Optimistic chain, it records bets on base chain and rewards those who predict the outcomes correctly.

> The frontend code can be found at https://github.com/0xVivaLabs/Bet-NBA

## Installation

1. Follow the installation instructions from [ibc-app-solidity-template](https://github.com/open-ibc/ibc-app-solidity-template)
2. Add your `BDL_API_KEY` to the `.env` file. You can obtain the key by registering at https://www.balldontlie.io/
3. Update the NBA match date in `scripts/addMatches.js` and `scripts/bet.js`.
4. Deploy the contract by running `just do-it` in your terminal.
