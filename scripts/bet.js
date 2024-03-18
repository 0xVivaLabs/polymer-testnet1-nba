const { ethers } = require("hardhat");
const { getConfigPath } = require("./private/_helpers");
const axios = require("axios");

async function main() {
  const [, user, user2] = await ethers.getSigners();
  const config = require(getConfigPath());
  const betNBAAddress = config.sendPacket.optimism.portAddr;
  const betChannelId = config.sendPacket.optimism.channelId;
  const betTimeout = config.sendPacket.optimism.timeout;

  const BetNBA = await ethers.getContractFactory("BetNBA");
  const betNBA = BetNBA.attach(betNBAAddress);

  const date = "2024-03-18";

  const res = await axios.get(
    `http://api.balldontlie.io/v1/games?dates[]=${date}`,
    {
      headers: {
        Authorization: process.env.BDL_API_KEY,
      },
    }
  );

  if (res.status != 200) {
    throw new Error(`API call failed: ${res.status}`); // Handle non-200 responses
  }

  const games = res.data.data;
  const matchIds = games.map((game) => game.id);
  console.log("matches:", matchIds);
  const homeWins = games.map((game) => false); // all home wins
  console.log("bet:", homeWins);
  const userAlreadyBet = await betNBA.userBets(user, matchIds[0]);

  if (!userAlreadyBet) {
    try {
      const userBalance = await ethers.provider.getBalance(user.address);
      if (userBalance < 10000000000000n) {
        throw new Error("Insufficient funds to place the bet");
      }

      const channelIdBytes = hre.ethers.encodeBytes32String(betChannelId);

      const txResponse = await betNBA
        .connect(user)
        .sendPacket(
          channelIdBytes,
          betTimeout,
          user.address,
          matchIds,
          homeWins
        );
      await txResponse.wait();
    } catch (error) {
      throw new Error(`Transaction failed: ${error.message}`);
    }
  } else {
    throw new Error("user already bet on this match");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
