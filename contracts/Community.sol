// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Nest.sol";
import "./Utils.sol";

contract Community {
    struct KeyAgreement {
        uint256 createdAt;
        address publisher;
        uint256 keyCount;
        mapping(address => string) E_keys;
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

    address owner;
    Nest public nest;
    Utils utils;

    string name;
    string description;
    string imageUrl;
    ColorTheme theme;
    Reaction[] reactions;

    mapping(address => uint8) public participationStage;
    address[] public members;

    mapping(string => Network) public networks;
    string[] public networkNames;

    KeyAgreement[] public keys;

    event KeysCycled();

    modifier networkExists(string calldata network) {
        require(
            networks[network].flag,
            "Network does not exist in the community"
        );
        _;
    }
    modifier onlyAdmin() {
        require(
            participationStage[msg.sender] == 3,
            "This action is restricted to admins of this community"
        );
        _;
    }
    modifier onlyMember() {
        require(
            participationStage[msg.sender] >= 2,
            "This action is restricted to members of this community"
        );
        _;
    }
    modifier onlyAuthorised() {
        require(
            nest.getUserByAddress(msg.sender).flag,
            "User does not have a Nest account"
        );
        _;
    }

    constructor(
        address _nestAddress,
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _theme,
        string memory _emotes
    ) {
        owner = msg.sender;
        nest = Nest(_nestAddress);
        utils = nest.utils();

        require(
            nest.getUserByAddress(msg.sender).flag,
            "You must have a Nest account to start creating communities"
        );
        nest.registerCommunityForUser(address(this), msg.sender);

        name = _name;
        description = _description;
        imageUrl = _imageUrl;

        theme.primary = utils.substring(_theme, 0, 11);
        theme.secondary = utils.substring(_theme, 12, 23);
        theme.background = utils.substring(_theme, 24, 35);
        theme.foreground = utils.substring(_theme, 36, 47);
        theme.front = utils.substring(_theme, 48, 59);
        theme.back = utils.substring(_theme, 60, 71);

        Network storage defaultNetwork = networks["General"];
        defaultNetwork.flag = true;
        defaultNetwork.description = "Default network";
        defaultNetwork.image = "";

        bool emotesEnd = false;
        uint8 i = 0;
        while (!emotesEnd && i + 16 < 100) {
            if (utils.strcmp("nil", utils.substring(_emotes, i, i + 3))) {
                emotesEnd = true;
            } else {
                Reaction storage nEmote = reactions.push();
                nEmote.icon = utils.substring(_emotes, i, i + 3);
                nEmote.color = utils.substring(_emotes, i + 4, i + 16);
                i += 16;
            }
        }

        members.push(msg.sender);
        participationStage[msg.sender] = 3;
    }

    function invite(address userToInvite) external onlyAdmin {
        require(
            participationStage[userToInvite] == 0,
            "This user is already invited or already a member"
        );
        participationStage[userToInvite] = 1;
    }

    function join(
        string[] calldata _keys,
        address[] calldata _correspondingUsers
    ) external onlyAuthorised {
        uint8 participation = participationStage[msg.sender];
        require(
            participation == 1,
            participation == 0
                ? "You are not invited to join this community, please contact an admin"
                : "You are already a part of this community"
        );

        KeyAgreement storage nAgreement = keys.push();
        nAgreement.createdAt = block.timestamp;
        nAgreement.publisher = msg.sender;

        for (uint256 i = 0; i < keys.length; i++) {
            nAgreement.E_keys[_correspondingUsers[i]] = _keys[i];
        }

        members.push(msg.sender);
        participationStage[msg.sender] = 2;
        
        emit KeysCycled();

        nest.registerCommunityForUser(address(this), msg.sender);
    }

    function getMemberCount() public view returns (uint256) {
        return members.length;
    }

    function getKeyCount() public view returns (uint256) {
        return keys.length;
    }

    function getKeyFromAgreement(uint256 agreementId)
        public
        view
        returns (string memory)
    {
        return keys[agreementId].E_keys[msg.sender];
    }

    function makePost(string calldata networkName, string calldata data)
        external
        onlyAuthorised
        onlyMember
        networkExists(networkName)
    {
        Network storage network = networks[networkName];
        network.postsCount += 1;
        Post storage nPost = network.posts[network.postsCount];
        nPost.createdAt = block.timestamp;
        nPost.data = data;
    }

    function getPostsCountByNetwork(string calldata network)
        external
        view
        onlyMember
        networkExists(network)
        returns (uint256)
    {
        return networks[network].postsCount;
    }

    function getPostData(string calldata network, uint256 post)
        external
        view
        returns (Post memory)
    {
        return networks[network].posts[post];
    }
}
