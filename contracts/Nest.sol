// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Nest {
    struct KeyAgreement {
        uint256 createdAt;
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
        string data;
        uint256 createdAt;
        Comment[] comments;
        mapping(address => uint8) reactions;
    }

    struct Reaction {
        string icon;
        string color;
    }

    struct Network {
        string image;
        string description;
        bool flag;
        uint256 postsCount;
        Post[] posts;
    }

    string name;
    string description;
    string imageUrl;
    Reaction[] reactions;
    ColorTheme theme;
    address[] users;
    mapping(address => uint8) participationStage;
    KeyAgreement[] keys;
    string[] networkNames;
    mapping(string => Network) networks;
    bool flag;

    struct User {
        string Kpub;
        string name;
        string imageUrl;
        uint256 createdAt;
        string[] communities;
        bool flag;
    }

    mapping(string => Community) public communities;
    mapping(address => User) public users;

    uint256 public DHprime =
        66460405813236099615862811338380441677144783113775042729908710534400192091569;
    uint256 public DHprimitive = 7;

    modifier onlyAuthorised() {
        require(users[msg.sender].flag, "User does not have an account");
        _;
    }
    modifier onlyUnauthorised() {
        require(!users[msg.sender].flag, "User has an account");
        _;
    }
    modifier communityExists(string calldata uuid) {
        require(communities[uuid].flag, "Community does not exist");
        _;
    }

    function newCommunity(
        string calldata name,
        string calldata description,
        string calldata imageUrl,
        string calldata theme,
        string calldata emotes
    ) external onlyAuthorised {
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

        Network storage defaultNetwork = nCommunity.networks["General"];
        defaultNetwork.flag = true;
        defaultNetwork.description = "Default network";
        defaultNetwork.image = "";

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
        nCommunity.participationStage[msg.sender] = 3;
        nCommunity.flag = true;

        User storage thisUser = users[msg.sender];
        thisUser.communities.push(uuid);

        communitiesCount += 1;
    }

    function createAccount(
        string calldata Kpub,
        string calldata name,
        string calldata imageUrl
    ) external onlyUnauthorised {
        User storage nUser = users[msg.sender];
        nUser.Kpub = Kpub;
        nUser.name = name;
        nUser.imageUrl = imageUrl;
        nUser.createdAt = block.timestamp;
        nUser.flag = true;
    }

    function getCommunitiesOfSender()
        public
        view
        onlyAuthorised
        returns (string[] memory)
    {
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

    function doesSenderHaveAnAccount() public view returns (bool) {
        return users[msg.sender].flag;
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

    modifier networkExistsInCommunity(
        string calldata network,
        string calldata uuid
    ) {
        require(
            communities[uuid].networks[network].flag,
            "Network does not exist for specified community UUID"
        );
        _;
    }
    modifier onlyAdmin(string calldata uuid) {
        require(
            communities[uuid].participationStage[msg.sender] == 3,
            "This action is restricted to admins of this community"
        );
        _;
    }
    modifier onlyMember(string calldata uuid) {
        require(
            communities[uuid].participationStage[msg.sender] >= 2,
            "This action is restricted to members of this community"
        );
        _;
    }

    function inviteToCommunity(
        string calldata communityUUID,
        address userToInvite
    ) external onlyAdmin(communityUUID) {
        require(
            communities[communityUUID].participationStage[msg.sender] == 0,
            "This user is already invited or already a member"
        );
        communities[communityUUID].participationStage[userToInvite] = 1;
    }

    function checkParticipationStage(string calldata communityUUID)
        external
        view
        onlyAuthorised
        communityExists(communityUUID)
        returns (uint8)
    {
        return communities[communityUUID].participationStage[msg.sender];
    }

    function getCommunityReactionSet(string calldata communityUUID)
        external
        view
        communityExists(communityUUID)
        returns (Reaction[] memory)
    {
        return communities[communityUUID].reactions;
    }

    function makePost(
        string calldata communityUUID,
        string calldata networkName,
        string calldata data
    )
        external
        communityExists(communityUUID)
        onlyMember(communityUUID)
        networkExistsInCommunity(networkName, communityUUID)
    {
        Network storage network = communities[communityUUID].networks[
            networkName
        ];
        network.postsCount += 1;
        Post storage nPost = network.posts[network.postsCount];
        nPost.createdAt = block.timestamp;
        nPost.data = data;
    }

    function getPostsCountByNetwork(
        string calldata communityUUID,
        string calldata network
    )
        external
        view
        communityExists(communityUUID)
        onlyMember(communityUUID)
        networkExistsInCommunity(network, communityUUID)
        returns (uint256)
    {
        return communities[communityUUID].networks[network].postsCount;
    }

    function getPostData(
        string calldata communityUUID,
        string calldata network,
        uint256 post
    ) external view returns (Post memory) {
        return communities[communityUUID].networks[network].posts[post];
    }

    function joinCommunity(
        string calldata communityUUID,
        string[] calldata keys,
        address[] calldata correspondingUsers
    ) external onlyAuthorised communityExists(communityUUID) {
        uint8 participation = communities[communityUUID].participationStage[
            msg.sender
        ];

        require(
            participation == 1,
            participation == 0
                ? "You are not invited to join this community, please contact an admin"
                : "You are already a part of this community"
        );

        KeyAgreement storage nAgreement = communities[communityUUID]
            .keys
            .push();
        nAgreement.createdAt = block.timestamp;
        nAgreement.publisher = msg.sender;

        for (uint256 i = 0; i < keys.length; i++) {
            nAgreement.E_Keys[correspondingUsers[i]] = keys[i];
        }

        communities[communityUUID].users.push(msg.sender);
        communities[communityUUID].participationStage[msg.sender] = 2;

        User storage thisUser = users[msg.sender];
        thisUser.communities.push(communityUUID);
    }
}
