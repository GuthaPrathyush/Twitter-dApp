// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract Twitter {
    uint16 public maxTweetLength;
    address public networkOwner;

    struct Tweet {
        address author;
        uint256 _id;
        string content;
        uint256 timestamp;
        uint256 likes;
    }
    struct User {
        address user;
        string userName;
        string nickName;
        uint256 following;
        uint256 followers;
    }

    constructor() {
        owners[msg.sender] = true;
        maxTweetLength = 280;
    }

    mapping(address=>mapping(uint256=>mapping(address=>bool))) public likeSet;
    mapping(address=>mapping(address=>bool)) public followSet;
    mapping(address=>User[]) public followArray;
    mapping(address=>Tweet[]) public tweets;
    mapping(address=>User) public users;
    mapping(address=>bool) public owners;

    modifier ownerOnly() {
        require(owners[msg.sender], "You are not an OWNER!");
        _;
    }

    modifier userOnly() {
        require(users[msg.sender].user != address(0), "You are not an existing user!");
        _;
    }

    //add an owner
    function addOwner(address newOwner) public ownerOnly {
        require(owners[msg.sender], "You are not an OWNER!");
        owners[newOwner] = true;
    }

    //changing the tweet length(by only the owner)
    function changeTweetLength(uint16 newLength) public ownerOnly {
        maxTweetLength = newLength;
    }

    //creating a tweet
    function createTweet(string memory _tweet) public userOnly{
        require(bytes(_tweet).length <= maxTweetLength, "Tweet length should not exceed the limit!");
        Tweet memory newTweet = Tweet({
            author: msg.sender,
            _id: tweets[msg.sender].length,
            content: _tweet,
            likes: 0,
            timestamp: block.timestamp
        });
        tweets[msg.sender].push(newTweet);
    }

    //getting a particular tweet of a user
    function getTweet(address _author, uint64 index) public view returns (Tweet memory) {
        require(tweets[_author].length > index && index >= 0, "Invalid Tweet reference");
        return tweets[_author][index];
    }

    //getting all the tweets of a particular user
    function getAllTweets(address _author) public view userOnly returns (Tweet[] memory) {
        return tweets[_author];
    }

    //liking the tweet
    function likeTweet(address _author, uint256 index) public userOnly {
        require(tweets[_author].length > index && index >= 0, "Invalid Tweet reference");
        if(!likeSet[_author][index][msg.sender]) {
            likeSet[_author][index][msg.sender] = true;
            tweets[_author][index].likes++;
        }
    }

    //unliking the tweet
    function unlikeTweet(address _author, uint256 index) public userOnly {
        require(tweets[_author].length > index && index >= 0, "Invalid Tweet reference");
        if(likeSet[_author][index][msg.sender]) {
            likeSet[_author][index][msg.sender] = false;
            tweets[_author][index].likes--;
        }
    }

    //registering user
    function registerUser(string memory userName, string memory nickName) public {
        users[msg.sender].user = msg.sender;
        users[msg.sender].userName = userName;
        users[msg.sender].nickName = nickName;
    }

    //getting the user details
    function getUserDetails() public userOnly view returns (User memory) {
        return users[msg.sender];
    }

    //getting particular user details
    function getParticularUserDetails(address _author) public view userOnly returns (User memory) {
        return users[_author];
    }

    //getting followingList of a user 
    function getFollowArray() public view userOnly returns (User[] memory) {
        return followArray[msg.sender];
    }

    //initial load to a website
    function initialLoad(uint256 start, uint256 limit, uint256 loadCount) public view userOnly returns (Tweet[] memory) {
        uint256 followingOfUser = users[msg.sender].following;
        uint256 size = (start + limit > followingOfUser) ? followingOfUser - start : limit;
        Tweet[] memory allFollowingTweets = new Tweet[](size);
        for(uint256 i=0; i<size; i++) {
            address currU = followArray[msg.sender][start + i].user;
            if (tweets[currU].length-loadCount > 0) {
                allFollowingTweets[i] = tweets[currU][tweets[currU].length - loadCount - 1];
            }
        }
        return allFollowingTweets;
    }


    //follow a user
    function followUser(address userToFollow) public userOnly {
        require(!followSet[msg.sender][userToFollow], "You already follow the User!");
        require(userToFollow != msg.sender, "Cannot follow yourself");
        require(users[userToFollow].user != address(0), "User does not exist");
        followArray[msg.sender].push(users[userToFollow]);
        users[msg.sender].following++;
        users[userToFollow].followers++;
        followSet[msg.sender][userToFollow] = true;
    }

    //unfollow a user
    function unfollowUser(address userToUnfollow) public userOnly {
        require(followSet[msg.sender][userToUnfollow], "You are not following the User!");
        uint256 index = followArray[msg.sender].length;
        for(uint256 i=0; i<index; i++) {
            if(followArray[msg.sender][i].user == userToUnfollow) {
                index = i;
                break;
            }
        }
        followArray[msg.sender][index].user = followArray[msg.sender][followArray[msg.sender].length-1].user;
        followArray[msg.sender].pop();
        users[msg.sender].following--;
        users[userToUnfollow].followers--;
        followSet[msg.sender][userToUnfollow] = false;
    }
}