// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract GroupKeyExchange {
    struct User {
        string Kpub;
        string name;
        string[] communities;
        bool flag;
    }

    struct KeyAgreement {
        uint256 createdAt;
        uint256 expiryEpoch;
        address publisher;
        mapping(address => string) E_Keys;
    }

    struct ColorTheme {
        string primary;
        string secondary;
        string background;
        string foreground;
        string front;
        string back;
    }

    struct Comment {
        address sender;
        uint256 createdAt;
        string content;
    }

    struct Post {
        string title;
        string content;
        Comment[] comments;
        mapping(address => uint8) reactions;
    }

    struct Reaction {
        string icon;
        string color;
    }

    struct Community {
        string name;
        string description;
        string imageUrl;
        Reaction[] reactions;
        ColorTheme theme;
        address[] users;
        address[] admins;
        Post[] posts;
        bool flag;
        KeyAgreement[] keys;
        // uint256 keyExpiryEpoch;
    }

    mapping(string => Community) public communities;
    uint256 communitiesCount = 0;

    mapping(address => User) public users;

    uint256 public DHprime =
        114442205032854638555706524671328947153059801427278377469756293561027497533359;
    uint256 public DHprimitive = 2;

    function newCommunity(
        string calldata name,
        string calldata description,
        string calldata imageUrl,
        string calldata theme,
        string calldata emotes
    ) external {
        require(users[msg.sender].flag, "User does not have an account");
        string memory uuid = hashNumber(communitiesCount);
        Community storage nCommunity = communities[uuid];

        nCommunity.name = name;
        nCommunity.description = description;
        nCommunity.imageUrl = imageUrl;

        ColorTheme storage nCommunityTheme = nCommunity.theme;

        nCommunityTheme.primary = theme[0:11];
        nCommunityTheme.secondary = theme[12:23];
        nCommunityTheme.background = theme[24:35];
        nCommunityTheme.foreground = theme[36:47];
        nCommunityTheme.front = theme[48:59];
        nCommunityTheme.back = theme[60:71];
        // nCommunity.keyExpiryEpoch = keyExpiryEpoch;

        bool emotesEnd = false;
        uint8 i = 0;

        while (!emotesEnd && i + 16 < 100) {
            if (strcmp("nil", emotes[i:i + 3])) {
                emotesEnd = true;
            } else {
                Reaction storage nEmote1 = nCommunity.reactions.push();
                nEmote1.icon = emotes[i:i + 3];
                nEmote1.color = emotes[i + 4:i + 16];
                i += 16;
            }
        }

        nCommunity.users.push(msg.sender);
        nCommunity.admins.push(msg.sender);
        nCommunity.flag = true;

        User storage thisUser = users[msg.sender];
        thisUser.communities.push(uuid);

        communitiesCount += 1;
    }

    function getCommunityReactionSet(string calldata groupUUID) external view returns (Reaction[] memory) {
        require(communities[groupUUID].flag, "Group does not exist");

        return communities[groupUUID].reactions;
    }

    function makeAccount(string calldata Kpub, string calldata name) external {
        require(!users[msg.sender].flag, "User already has an account");
        User storage nUser = users[msg.sender];
        nUser.Kpub = Kpub;
        nUser.name = name;
        nUser.flag = true;
    }

    function join(
        string calldata groupUUID,
        string[] calldata keys,
        address[] calldata correspondingUsers
    ) external {
        require(users[msg.sender].flag, "User does not have an account");
        require(communities[groupUUID].flag, "Group does not exist");

        KeyAgreement storage nAgreement = communities[groupUUID].keys.push();
        nAgreement.createdAt = block.timestamp;
        nAgreement.publisher = msg.sender;

        for (uint256 i = 0; i < keys.length; i++) {
            nAgreement.E_Keys[correspondingUsers[i]] = keys[i];
        }

        communities[groupUUID].users.push(msg.sender);

        User storage thisUser = users[msg.sender];
        thisUser.communities.push(groupUUID);
    }

    function getCommunitiesOfSender() public view returns (string[] memory) {
        require(users[msg.sender].flag, "User does not have an account");

        return users[msg.sender].communities;
    }

    function hashNumber(uint256 _number) internal pure returns (string memory) {
        bytes32 hashValue = sha256(abi.encodePacked(_number));
        return bytes32ToHexString(hashValue);
    }

    function bytes32ToHexString(bytes32 _value)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 char1 = uint8(_value[i] >> 4);
            uint8 char2 = uint8(_value[i] & 0x0f);
            buffer[i * 2] = toHexChar(char1);
            buffer[i * 2 + 1] = toHexChar(char2);
        }
        return string(buffer);
    }

    function toHexChar(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(uint8(bytes1("0")) + _value);
        } else {
            return bytes1(uint8(bytes1("a")) + _value - 10);
        }
    }

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }
}
