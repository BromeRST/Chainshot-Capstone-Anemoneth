// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./anemonethV1.sol";

contract SocialFeatures is AnemonethV1 {
    event NewPost(
        address indexed from,
        uint256 postId,
        uint256 timestamp,
        string msg,
        string img
    );

    struct Post {
        address from;
        string message;
        string image;
        uint256 timestamp;
        uint16 likeRecived;
        uint16 dislikeRecived;
        Comments[] comments;
    }

    struct Comments {
        address from;
        uint256 commentDate;
        string commentMessage;
        string commentImageURI;
    }

    Post[] public posts;

    mapping(address => uint256) public lastPostedAt;
    mapping(address => uint256) public addressTotalPost;

    function post(string calldata _message, string calldata _imageURI)
        external
        OnlyUsers
    {
        require(
            lastPostedAt[msg.sender] + 1 minutes < block.timestamp,
            "Wait 1m"
        );

        lastPostedAt[msg.sender] = block.timestamp;

        posts.push(
            Post(
                msg.sender,
                _message,
                _imageURI,
                block.timestamp,
                0,
                0,
                new Comments[](0)
            )
        );

        uint256 postId = posts.length - 1;

        addressTotalPost[msg.sender]++;

        emit NewPost(msg.sender, postId, block.timestamp, _message, _imageURI);
    }

    function getAllPosts() external view returns (Post[] memory) {
        return posts;
    }

    function getPostsByOwner(address _owner)
        external
        view
        OnlyUsers
        returns (Post[] memory)
    {
        Post[] memory result = new Post[](addressTotalPost[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].from == _owner) {
                result[counter] = posts[i];
                counter++;
            }
        }
        return result;
    }

    function setUserImageURI(string memory _userImgURI) external OnlyUsers {
        addressToUser[msg.sender].userImageURI = _userImgURI;
    }
}
