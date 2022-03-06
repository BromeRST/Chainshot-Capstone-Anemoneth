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
        address[] likeRecivedFrom; // <== we want to show who liked the post but keep anonymous who disliked it?
        Comments[] comments;
    }

    struct Comments {
        address from;
        uint256 commentDate;
        uint256 likeRecived;
        uint256 dislikeRecived;
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
                new address[](0),
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

    function addLikeToPost(uint256 _postId, address _postOwner)
        external
        payable
    {
        transferFrom(msg.sender, _postOwner, 10 ether); // added price to like and dislike to discourage bots or malicious users that want to use other's self owned
        posts[_postId].likeRecived++; // profile to add likes on their posts      ++ a premium for the best post/owner
    }

    function addDislikeToPost(uint256 _postId) external payable {
        _burn(msg.sender, 10 ether); // added burning
        posts[_postId].dislikeRecived++;
    }

    function addComment(
        uint256 _postId,
        address _postOwner,
        string memory _commentText,
        string memory _commentImgURI
    ) external payable {
        transferFrom(msg.sender, _postOwner, 10);
        posts[_postId].comments.push(
            Comments(
                msg.sender,
                block.timestamp,
                0,
                0,
                _commentText,
                _commentImgURI
            )
        );
    }

    function addLikeToPostComment(
        uint256 _postId,
        uint256 _commentId,
        address _commentOwner
    ) external payable {
        transferFrom(msg.sender, _commentOwner, 5 ether);
        posts[_postId].comments[_commentId].likeRecived++;
    }

    function addDislikeToPostComment(uint256 _postId, uint256 _commentId)
        external
        payable
    {
        _burn(msg.sender, 5 ether);
        posts[_postId].comments[_commentId].dislikeRecived++;
    }

    // in Posts like/dislike and in comments like/dislike feature we should add probably a feature to remove the dislike/like if it was added previously.
    // but at the same time we should think about that the user already payed a fee to add this dislike/like
}
