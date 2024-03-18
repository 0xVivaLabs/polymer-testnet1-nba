//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./base/CustomChanIbcApp.sol";

// import "forge-std/console2.sol";

contract Reward is ERC721, Ownable, CustomChanIbcApp {
    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;
    string baseURI = "";

    struct Match {
        uint256 id;
        uint8 homeTeam; // 0-29
        uint8 visitorTeam;
        uint8 homeScore;
        uint8 visitorScore;
    }

    mapping(uint256 => Match) public matchMap;
    mapping(address => mapping(uint256 => bool)) public userBets;
    // mapping(uint256 => address) public betIdRecords;
    // uint256[] public betIdList;
    address[] public joinedUsers;

    // modifier onlyForTest() {
    //     require(msg.sender == address(0x1) || msg.sender == address(0x2), "Only for test");
    //     _;
    // }

    constructor(IbcDispatcher _dispatcher) ERC721("NBAReward", "NBA") CustomChanIbcApp(_dispatcher) {}

    event BetPlaced(address indexed user, uint256[] matchId, bool[] homeWin);

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function _mint(address _to) private returns (uint256) {
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        _safeMint(_to, tokenId);
        return tokenId;
    }

    // ibc functions
    function onRecvPacket(IbcPacket memory packet)
        external
        override
        onlyIbcDispatcher
        returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(packet);

        (address _bettor, uint256[] memory _matchId, bool[] memory _homeWin) =
            abi.decode(packet.data, (address, uint256[], bool[]));

        emit BetPlaced(_bettor, _matchId, _homeWin);

        // Record the bet for compute winners
        for (uint256 i = 0; i < _matchId.length; i++) {
            require(matchMap[_matchId[i]].id != 0, "Match not found");
            require(!userBets[_bettor][_matchId[i]], "User already bet on this match");
            userBets[_bettor][_matchId[i]] = _homeWin[i];

            // randomly generate a bet id
            // uint256 betId = uint256(keccak256(abi.encodePacked(block.timestamp, _bettor, _matchId[i])));
            // betIdRecords[betId] = _bettor;
            // betIdList.push(betId);
        }
        joinedUsers.push(_bettor);

        return AckPacket(true, abi.encode(_bettor, _matchId, _homeWin));
    }

    function onAcknowledgementPacket(IbcPacket calldata, AckPacket calldata ack)
        external
        view
        override
        onlyIbcDispatcher
    {
        require(false, "This function should not be called");
    }

    function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {
        timeoutPackets.push(packet);
    }

    // function getBetIdListLength() public view returns (uint256) {
    //     return betIdList.length;
    // }

    function getJoinUsersLength() public view returns (uint256) {
        return joinedUsers.length;
    }

    function getMatchById(uint256 _matchId) public view returns (uint256, uint8, uint8, uint8, uint8) {
        Match memory theMatch = matchMap[_matchId];
        return (theMatch.id, theMatch.homeTeam, theMatch.visitorTeam, theMatch.homeScore, theMatch.visitorScore);
    }

    /**
     * @dev Should invoke by opchain, for test
     */
    // function bet(address _bettor, uint256[] calldata _matchId, bool[] calldata _homeWin) external onlyForTest {
    //     require(_matchId.length == _homeWin.length, "Invalid input");
    //     require(msg.sender == _bettor, "Invalid sender");
    //     for (uint256 i = 0; i < _matchId.length; i++) {
    //         require(matchMap[_matchId[i]].id != 0, "Match not found");
    //         require(!userBets[_bettor][_matchId[i]], "User already bet on this match");
    //         userBets[_bettor][_matchId[i]] = _homeWin[i];

    //         // randomly generate a bet id
    //         uint256 betId = uint256(keccak256(abi.encodePacked(block.timestamp, _bettor, _matchId[i])));
    //         betIdRecords[betId] = _bettor;
    //         betIdList.push(betId);
    //     }
    //     joinedUsers.push(_bettor);
    //     emit BetPlaced(_bettor, _matchId, _homeWin);
    // }

    /* admin functions
    /* read userBets to determine winners, top 10 users get rewards, if result is a tie, fcfs
    */
    function distributeRewards(Match[] calldata _matchResults, uint256 winners) external onlyOwner {
        require(_matchResults.length > 0, "No match results provided");

        uint256 numUsers = joinedUsers.length;
        uint256[] memory scores = new uint256[](numUsers);
        address[] memory userAddresses = new address[](numUsers);

        for (uint256 i = 0; i < numUsers; i++) {
            address user = joinedUsers[i];
            uint256 score = 0;

            for (uint256 j = 0; j < _matchResults.length; j++) {
                Match memory matchResult = _matchResults[j];
                if (userBets[user][matchResult.id] && matchResult.homeScore > matchResult.visitorScore) {
                    score++;
                } else if (!userBets[user][matchResult.id] && matchResult.homeScore < matchResult.visitorScore) {
                    score++;
                }
            }
            scores[i] = score;
            userAddresses[i] = user;
        }

        for (uint256 i = 0; i < numUsers; i++) {
            for (uint256 j = i + 1; j < numUsers; j++) {
                if (scores[j] > scores[i]) {
                    (scores[i], scores[j]) = (scores[j], scores[i]);
                    (userAddresses[i], userAddresses[j]) = (userAddresses[j], userAddresses[i]);
                }
            }
        }

        uint256 numRewards = numUsers > winners ? winners : numUsers;
        for (uint256 i = 0; i < numRewards; i++) {
            _mint(userAddresses[i]);
        }

        // reset Daily MatchResults
        delete joinedUsers;
    }

    function addMatch(uint256[] calldata _matchId, uint8[] calldata _homeTeam, uint8[] calldata _visitorTeam)
        external
        onlyOwner
    {
        require(_matchId.length == _homeTeam.length && _matchId.length == _visitorTeam.length, "Invalid input");
        for (uint256 i = 0; i < _matchId.length; i++) {
            matchMap[_matchId[i]] = Match(_matchId[i], _homeTeam[i], _visitorTeam[i], 0, 0);
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
}
