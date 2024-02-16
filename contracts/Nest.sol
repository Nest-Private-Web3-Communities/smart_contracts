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

    function newGroup(
        string calldata name,
        string calldata description,
        string calldata imageUrl,
        string calldata theme
    ) external {
        require(users[msg.sender].flag, "User does not have an account");
        string memory uuid = hashNumber(communitiesCount);
        Community storage nGroup = communities[uuid];

        nGroup.name = name;
        nGroup.description = description;
        nGroup.imageUrl = imageUrl;

        ColorTheme storage nGroupTheme = nGroup.theme;

        nGroupTheme.primary = theme[0:12];
        nGroupTheme.secondary = theme[13:25];
        nGroupTheme.background = theme[26:38];
        nGroupTheme.foreground = theme[39:51];
        nGroupTheme.front = theme[52:64];
        nGroupTheme.back = theme[65:77];
        // nGroup.keyExpiryEpoch = keyExpiryEpoch;

        nGroup.users.push(msg.sender);
        nGroup.admins.push(msg.sender);
        nGroup.flag = true;

        User storage thisUser = users[msg.sender];
        thisUser.communities.push(uuid);

        communitiesCount += 1;
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

    function bytes32ToHexString(
        bytes32 _value
    ) internal pure returns (string memory) {
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
}
