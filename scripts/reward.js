const { ethers } = require('hardhat')
const { getConfigPath } = require('./private/_helpers')
const axios = require('axios')

async function main() {
  const [admin] = await ethers.getSigners()
  const config = require(getConfigPath())
  const rewardAddress = config.sendPacket.base.portAddr

  const Reward = await ethers.getContractFactory('Reward')
  const reward = Reward.attach(rewardAddress)

  const date = '2024-03-18'

  const res = await axios.get(`http://api.balldontlie.io/v1/games?dates[]=${date}`, {
    headers: {
      Authorization: process.env.BDL_API_KEY,
    },
  })

  if (res.status != 200) {
    throw new Error(`API call failed: ${res.status}`) // Handle non-200 responses
  }

  const games = res.data.data
  const matchIds = games.map((game) => game.id)

  const allGamesEnded = games.every((game) => game.status === 'Final')

  if (allGamesEnded) {
    try {
      console.log('All games have ended')
      const matchResults = games.map((game) => ({
        id: game.id,
        homeTeam: game.home_team.id,
        visitorTeam: game.visitor_team.id,
        homeScore: game.home_team_score,
        visitorScore: game.visitor_team_score,
      }))
      const amount = 10

      console.log(matchResults)
      //   function distributeRewards(Match[] calldata _matchResults, uint256 winners) external onlyOwner
      const rewardTx = await reward.connect(admin).distributeRewards(matchResults, amount)
      await rewardTx.wait()
    } catch (error) {
      console.error(`Transaction failed: ${error.message}`)
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
