const { ethers } = require("hardhat");
const { getConfigPath } = require("./private/_helpers");
const axios = require("axios");

async function main() {
  const [admin, user] = await ethers.getSigners();
  const config = require(getConfigPath());
  const betNBAAddress = config.sendUniversalPacket.optimism.portAddr;

  const BetNBA = await ethers.getContractFactory("BetNBA");
  const betNBA = BetNBA.attach(betNBAAddress);

  const date = "2024-03-16";

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
  const homeTeamIds = games.map((game) => game.home_team.id);
  const visitorTeamIds = games.map((game) => game.visitor_team.id);

  if (games[0].home_team_score == 0) {
    try {
      const resetTx = await betNBA.connect(admin).resetDailyMatchResults();
      await resetTx.wait();
      console.log(`Reset daily match participants`);

      const addMatchTx = await betNBA
        .connect(admin)
        .addMatch(matchIds, homeTeamIds, visitorTeamIds);
      await addMatchTx.wait();
      console.log(`Added ${date} ${matchIds.length} matches`);
    } catch (error) {
      console.error(`Transaction failed: ${error.message}`);
    }
  } else {
    throw new Error("game already started");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
