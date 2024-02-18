// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Nest.sol";
import "./Utils.sol";

contract Community {
    struct KeyAgreement {
        uint256 createdAt;
        address publisher;
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
        mapping(address => uint256) reactions;
        address[] reactors;
    }

    struct Reaction {
        string name;
        string color;
    }

    struct Network {
        string image;
        string description;
        bool flag;
        uint256[] posts;
    }

    address public owner;
    Nest public nest;
    Utils utils;

    string public name;
    string public description;
    string public imageUrl;
    ColorTheme public theme;
    Reaction[] public reactions;
    Post[] public posts;

    mapping(address => uint8) public participationStage;
    address[] public members;

    mapping(string => Network) public networks;
    string[] public networkNames;

    KeyAgreement[] public keys;

    event KeysCycled();

    modifier networkExists(string calldata _network) {
        require(
            networks[_network].flag,
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
                nEmote.name = utils.substring(_emotes, i, i + 3);
                nEmote.color = utils.substring(_emotes, i + 4, i + 16);
                i += 16;
            }
        }

        members.push(msg.sender);
        participationStage[msg.sender] = 3;
    }

    function invite(address _userToInvite) external onlyAdmin {
        require(
            participationStage[_userToInvite] == 0,
            "This user is already invited or already a member"
        );
        participationStage[_userToInvite] = 1;
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

        for (uint256 i = 0; i < _keys.length; i++) {
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

    function getKeyFromAgreement(uint256 _agreementId)
        public
        view
        returns (string memory)
    {
        return keys[_agreementId].E_keys[msg.sender];
    }

    function getReactions() public view returns (Reaction[] memory) {
        return reactions;
    }

    function getMemberAddresses() public view returns (address[] memory) {
        return members;
    }

    function getNetworkNames() public view returns (string[] memory) {
        return networkNames;
    }

    function makePost(string calldata _networkName, string calldata _data)
        external
        onlyAuthorised
        onlyMember
        networkExists(_networkName)
    {
        networks[_networkName].posts.push(posts.length);
        Post storage nPost = posts.push();
        nPost.createdAt = block.timestamp;
        nPost.data = _data;
    }

    function commentOnPost(uint256 _postId, string calldata _content)
        external
        onlyAuthorised
        onlyMember
    {
        Post storage post = posts[_postId];
        Comment storage nComment = post.comments.push();
        nComment.sender = msg.sender;
        nComment.createdAt = block.timestamp;
        nComment.content = _content;
    }

    function reactToPost(uint256 _postId, uint8 _reactionId)
        external
        onlyAuthorised
        onlyMember
    {
        Post storage post = posts[_postId];
        post.reactors.push(msg.sender);
        post.reactions[msg.sender] = _reactionId;
    }
}
