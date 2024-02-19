// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Community.sol";
import "./Utils.sol";

contract Nest {
    struct User {
        uint48 Kpub;
        string name;
        string imageUrl;
        uint256 createdAt;
        address[] communities;
        bool flag;
    }

    Utils public utils;

    mapping(address => User) public users;

    uint48 public DHprime = 168167339945089;
    uint48 public DHprimitive = 17;

    modifier onlyAuthorised() {
        require(users[msg.sender].flag, "User does not have an account");
        _;
    }
    modifier onlyUnauthorised() {
        require(!users[msg.sender].flag, "User has an account");
        _;
    }

    constructor() {
        utils = new Utils();
    }

    function createAccount(
        uint48 Kpub,
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
        returns (address[] memory)
    {
        return users[msg.sender].communities;
    }

    function doesSenderHaveAnAccount() public view returns (bool) {
        return users[msg.sender].flag;
    }

    function registerCommunityForUser(
        address community,
        address userAddress
    ) public returns (bool) {
        require(
            tx.origin == userAddress,
            "Can't register communities for other users"
        );
        users[userAddress].communities.push(community);
        return true;
    }

    function getUserByAddress(
        address userAddress
    ) public view returns (User memory) {
        return users[userAddress];
    }
}
