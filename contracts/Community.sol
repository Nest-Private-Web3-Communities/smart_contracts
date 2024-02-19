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

    struct Comment {
        address sender;
        uint256 createdAt;
        string content;
    }

    struct Post {
        uint256 createdAt;
        address publisher;
        string data;
        string networkName;
        Comment[] comments;
        mapping(address => uint8) reactions;
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
    string public theme;
    string public reactions;
    Post[] public posts;
    mapping(address => uint256[]) userPosts;

    mapping(address => uint8) public participationStage;
    address[] public members;

    mapping(string => Network) public networks;
    string[] public networkNames;

    mapping(address => uint256) joined;

    KeyAgreement[] public keys;

    event KeysCycled();

    modifier networkExists(string calldata _network) {
        require(
            networks[_network].flag,
            "Network does not exist in the community"
        );
        _;
    }
    modifier networkNotExists(string calldata _network) {
        require(!networks[_network].flag, "Network exists in community");
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
        string memory _emotes,
        string memory _Kmaster
    ) {
        owner = msg.sender;
        nest = Nest(_nestAddress);
        require(
            nest.getUserByAddress(msg.sender).flag,
            "You must have a Nest account to start creating communities"
        );
        utils = nest.utils();

        nest.registerCommunityForUser(address(this), msg.sender);

        name = _name;
        description = _description;
        imageUrl = _imageUrl;

        theme = _theme;

        networkNames.push("General");
        Network storage defaultNetwork = networks[networkNames[0]];
        defaultNetwork.flag = true;
        defaultNetwork.description = "Default network";
        defaultNetwork.image = "";

        KeyAgreement storage nAgreement = keys.push();
        nAgreement.createdAt = block.timestamp;
        nAgreement.publisher = msg.sender;
        nAgreement.E_keys[msg.sender] = _Kmaster;

        reactions = _emotes;

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
        joined[msg.sender] = block.timestamp;

        emit KeysCycled();

        nest.registerCommunityForUser(address(this), msg.sender);
    }

    function makeAdmin(address _user) public onlyAuthorised onlyAdmin {
        require(participationStage[_user] == 2, "User not in community");
        participationStage[_user] = 3;
    }

    function getMemberCount() public view returns (uint256) {
        return members.length;
    }

    function getNetworkCount() public view returns (uint256) {
        return networkNames.length;
    }

    function getKeyCount() public view returns (uint256) {
        return keys.length;
    }

    function getKeyFromAgreement(
        uint256 _agreementId
    ) public view returns (string memory) {
        return keys[_agreementId].E_keys[msg.sender];
    }

    function getMemberAddresses() public view returns (address[] memory) {
        return members;
    }

    function getNetworkNames() public view returns (string[] memory) {
        return networkNames;
    }

    function createNetwork(
        string calldata _networkName,
        string calldata _description,
        string calldata _imageUrl
    ) external onlyAuthorised onlyAdmin networkNotExists(_networkName) {
        Network storage nNetwork = networks[_networkName];
        nNetwork.flag = true;
        nNetwork.image = _imageUrl;
        nNetwork.description = _description;
        networkNames.push(_networkName);
    }

    function getPostsByNetwork(
        string calldata _networkName
    )
        external
        view
        onlyAuthorised
        onlyMember
        networkExists(_networkName)
        returns (uint256[] memory)
    {
        return networks[_networkName].posts;
    }

    function getPostsByUser(
        address _user
    ) external view onlyAuthorised onlyMember returns (uint256[] memory) {
        return userPosts[_user];
    }

    function makePost(
        string calldata _networkName,
        string calldata _data
    ) external onlyAuthorised onlyMember networkExists(_networkName) {
        networks[_networkName].posts.push(posts.length);
        userPosts[msg.sender].push(posts.length);
        Post storage nPost = posts.push();
        nPost.createdAt = block.timestamp;
        nPost.data = _data;
        nPost.publisher = msg.sender;
        nPost.networkName = _networkName;
    }

    function commentOnPost(
        uint256 _postId,
        string calldata _content
    ) external onlyAuthorised onlyMember {
        Post storage post = posts[_postId];
        Comment storage nComment = post.comments.push();
        nComment.sender = msg.sender;
        nComment.createdAt = block.timestamp;
        nComment.content = _content;
    }

    function getCommentCountOnPost(
        uint256 _postId
    ) external view onlyAuthorised onlyMember returns (uint256) {
        return posts[_postId].comments.length;
    }

    function getCommentOnPostById(
        uint256 _postId,
        uint256 _commentId
    ) external view onlyAuthorised onlyMember returns (Comment memory) {
        return posts[_postId].comments[_commentId];
    }

    function reactToPost(
        uint256 _postId,
        uint8 _reactionId
    ) external onlyAuthorised onlyMember {
        Post storage post = posts[_postId];
        if (post.reactions[msg.sender] == 0) post.reactors.push(msg.sender);

        post.reactions[msg.sender] = _reactionId + 1;
    }

    function getReactorsOnPost(
        uint256 _postId
    ) external view onlyAuthorised onlyMember returns (address[] memory) {
        return posts[_postId].reactors;
    }

    function getReactionOnPostByUser(
        uint256 _postId,
        address _user
    ) external view returns (uint8) {
        return posts[_postId].reactions[_user];
    }
}
