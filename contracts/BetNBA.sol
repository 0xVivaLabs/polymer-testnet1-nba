//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./base/CustomChanIbcApp.sol";

contract BetNBA is Ownable, CustomChanIbcApp {
    struct Match {
        uint256 id;
        uint8 homeTeam; // 0-29
        uint8 visitorTeam;
        uint8 homeScore;
        uint8 visitorScore;
    }

    mapping(uint256 => Match) public matchMap;
    mapping(address => mapping(uint256 => bool)) public userBets;
    mapping(uint256 => address) public betIdRecords;

    // daily joined users and bet id list
    uint256[] public betIdList;
    address[] public joinedUsers;

    event AckBetConfirmed(address indexed bettor, uint256[] matches, bool[] homeWin);

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    // ibc functions
    function sendPacket(
        bytes32 _channelId,
        uint64 _timeoutSeconds,
        address _bettor,
        uint256[] calldata _matches,
        bool[] calldata _homeWin
    ) external {
        bytes memory payload = abi.encode(_bettor, _matches, _homeWin);
        uint64 timeoutTimestamp = uint64((block.timestamp + _timeoutSeconds) * 1000000000);

        // logic
        _bet(_bettor, _matches, _homeWin);

        dispatcher.sendPacket(_channelId, payload, timeoutTimestamp);
    }

    function onAcknowledgementPacket(IbcPacket calldata packet, AckPacket calldata ack)
        external
        override
        onlyIbcDispatcher
    {
        ackPackets.push(ack);

        (address bettor, uint256[] memory matches, bool[] memory homeWin) =
            abi.decode(packet.data, (address, uint256[], bool[]));

        emit AckBetConfirmed(bettor, matches, homeWin);
    }

    // user can bet on matches
    function _bet(address _bettor, uint256[] memory _matchId, bool[] memory _homeWin) private {
        require(_matchId.length == _homeWin.length, "Invalid input");
        for (uint256 i = 0; i < _matchId.length; i++) {
            require(matchMap[_matchId[i]].id != 0, "Match not found");
            require(!userBets[_bettor][_matchId[i]], "User already bet on this match");
            userBets[_bettor][_matchId[i]] = _homeWin[i];

            // randomly generate a bet id
            uint256 betId = uint256(keccak256(abi.encodePacked(block.timestamp, _bettor, _matchId[i])));
            betIdRecords[betId] = _bettor;
            betIdList.push(betId);
        }
        joinedUsers.push(_bettor);
    }

    function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {
        timeoutPackets.push(packet);
        // TODO reset bet timeout
    }

    // admin functions
    // TODO rename function
    function resetDailyMatchResults() external onlyOwner {
        delete betIdList;
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
}
