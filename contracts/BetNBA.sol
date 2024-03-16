//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BetNBA is Ownable, UniversalChanIbcApp {
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
    uint256[] public betIdList;
    address[] public joinedUsers;

    event SendBetEvent(address indexed destPortAddr, address indexed bettor, uint256[] matches, bool[] homeWin);

    event AckBetConfirmed(address indexed bettor, uint256[] matches, bool[] homeWin);

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

    // ibc functions
    function sendUniversalPacket(
        address _destPortAddr,
        bytes32 _channelId,
        uint64 _timeoutSeconds,
        address _bettor,
        uint256[] calldata _matches,
        bool[] calldata _homeWin
    ) external {
        bytes memory payload = abi.encode(_bettor, _matches, _homeWin);
        uint64 timeoutTimestamp = uint64((block.timestamp + _timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            _channelId, IbcUtils.toBytes32(_destPortAddr), payload, timeoutTimestamp
        );
        emit SendBetEvent(_destPortAddr, _bettor, _matches, _homeWin);
    }

    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
    {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        (address bettor, uint256[] memory matches, bool[] memory homeWin) =
            abi.decode(packet.appData, (address, uint256[], bool[]));

        _bet(bettor, matches, homeWin);

        emit AckBetConfirmed(IbcUtils.toAddress(packet.destPortAddr), matches, homeWin);
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

    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // Timeouts not currently supported
    }

    // admin functions
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
