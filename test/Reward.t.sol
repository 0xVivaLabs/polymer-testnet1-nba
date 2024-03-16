//SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.23;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import {Reward} from "../contracts/Reward.sol";

// contract RewardTest is Test {
//     Reward public reward;
//     address public owner;
//     address public user1;
//     address public user2;

//     uint256[] public matchIds = new uint256[](6);

//     function setUp() public {
//         vm.prank(owner);
//         reward = new Reward();
//         user1 = address(0x1);
//         user2 = address(0x2);

//         matchIds[0] = 1038553;
//         matchIds[1] = 1038554;
//         matchIds[2] = 1038555;
//         matchIds[3] = 1038556;
//         matchIds[4] = 1038557;
//         matchIds[5] = 1038558;
//     }

//     function _addMatchesNotStart() internal {
//         uint8[] memory homeTeams = new uint8[](6);
//         uint8[] memory visitorTeams = new uint8[](6);
//         homeTeams[0] = 4;
//         visitorTeams[0] = 24;
//         homeTeams[1] = 9;
//         visitorTeams[1] = 16;
//         homeTeams[2] = 28;
//         visitorTeams[2] = 22;
//         homeTeams[3] = 19;
//         visitorTeams[3] = 13;
//         homeTeams[4] = 27;
//         visitorTeams[4] = 8;
//         homeTeams[5] = 29;
//         visitorTeams[5] = 1;
//         reward.addMatch(matchIds, homeTeams, visitorTeams);
//     }

//     function testUserBet() public {
//         bool[] memory homeWin = new bool[](6);
//         homeWin[0] = true;
//         homeWin[1] = true;
//         homeWin[2] = true;
//         homeWin[3] = true;
//         homeWin[4] = true;
//         homeWin[5] = true;
//         vm.prank(user1);
//         vm.expectRevert("Match not found");
//         reward.bet(user1, matchIds, homeWin);

//         vm.prank(owner);
//         _addMatchesNotStart();

//         vm.prank(user1);
//         reward.bet(user1, matchIds, homeWin);

//         homeWin[5] = false; // user2 bet on match 1038558 home lose
//         vm.prank(user2);
//         reward.bet(user2, matchIds, homeWin);

//         assertEq(reward.getBetIdListLength(), 12);
//         assertEq(reward.getJoinUsersLength(), 2);
//     }

//     function testSelectWinners() public {
//         vm.prank(owner);
//         _addMatchesNotStart();

//         // users bet
//         bool[] memory homeWin = new bool[](6);
//         homeWin[0] = true;
//         homeWin[1] = true;
//         homeWin[2] = true;
//         homeWin[3] = true;
//         homeWin[4] = true;
//         homeWin[5] = true;
//         bool[] memory homeWin2 = new bool[](6);
//         homeWin2[0] = true;
//         homeWin2[1] = true;
//         homeWin2[2] = true;
//         homeWin2[3] = true;
//         homeWin2[4] = true;
//         homeWin2[5] = false; // user2 bet on match 1038558 home lose
//         for (uint256 i = 0; i < 6; i++) {
//             console.log("user1 bet", homeWin[i]);
//         }
//         vm.prank(user1);
//         reward.bet(matchIds, homeWin);

//         for (uint256 i = 0; i < 6; i++) {
//             console.log("user2 bet", homeWin2[i]);
//         }
//         vm.prank(user2);
//         reward.bet(matchIds, homeWin2);

//         Reward.Match[] memory matchResults = new Reward.Match[](6);
//         matchResults[0] = Reward.Match(1038553, 4, 24, 96, 107); // false
//         matchResults[1] = Reward.Match(1038554, 9, 16, 95, 108); // false
//         matchResults[2] = Reward.Match(1038555, 28, 22, 103, 113); // false
//         matchResults[3] = Reward.Match(1038556, 19, 13, 112, 104); // true
//         matchResults[4] = Reward.Match(1038557, 27, 8, 106, 117); // false
//         matchResults[5] = Reward.Match(1038558, 29, 1, 124, 122); // true
//         vm.prank(owner);
//         reward.distributeRewards(matchResults, 1);

//         assertEq(reward.balanceOf(user1), 1);
//         assertEq(reward.balanceOf(user2), 0);
//     }
// }
