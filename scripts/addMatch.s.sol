// //SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.23;

// import "forge-std/Script.sol";
// import "../contracts/BetNBA.sol";

// contract AddMatchesScript is Script {
//     using stdJson for string;

//     function run() public {
//         uint256 privKey = vm.envUint("PRIVATE_KEY_1");

//         string memory configVar = vm.envString("CONFIG_PATH");
//         string memory root = vm.projectRoot();
//         string memory configPath = string.concat(root, "/", configVar);
//         string memory configJson = vm.readFile(configPath);
//         address payable betContractAddress =
//             payable(vm.parseJsonAddress(configJson, ".sendUniversalPacket.optimism.portAddr"));
//         // address betContractAddress = vm.parseJsonAddress(configJson, ".sendUniversalPacket.optimism.portAddr");
//         address owner = vm.rememberKey(privKey);
//         vm.startBroadcast(owner);

//         BetNBA betNBA = BetNBA(betContractAddress);

//         uint256[] memory matchIds = new uint256[](8);
//         uint8[] memory homeTeamIds = new uint8[](8);
//         uint8[] memory visitorTeamIds = new uint8[](8);

//         matchIds[0] = 1038575;
//         homeTeamIds[0] = 12;
//         visitorTeamIds[0] = 6;

//         matchIds[1] = 1038576;
//         homeTeamIds[1] = 2;
//         visitorTeamIds[1] = 9;

//         matchIds[2] = 1038577;
//         homeTeamIds[2] = 23;
//         visitorTeamIds[2] = 16;

//         matchIds[3] = 1038578;
//         homeTeamIds[3] = 5;
//         visitorTeamIds[3] = 25;

//         matchIds[4] = 1038579;
//         homeTeamIds[4] = 29;
//         visitorTeamIds[4] = 18;

//         matchIds[5] = 1038580;
//         homeTeamIds[5] = 10;
//         visitorTeamIds[5] = 20;

//         matchIds[6] = 1038581;
//         homeTeamIds[6] = 26;
//         visitorTeamIds[6] = 15;

//         matchIds[7] = 1038582;
//         homeTeamIds[7] = 14;
//         visitorTeamIds[7] = 1;

//         betNBA.addMatch(matchIds, homeTeamIds, visitorTeamIds);

//         vm.stopBroadcast();
//     }
// }
