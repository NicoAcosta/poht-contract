// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract APIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    event Callback(bytes32 requestId, uint256 volume);
    event OK(address indexed verified);

    uint256 public volume;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => uint256) public requests;
    mapping(bytes32 => address) public requestCaller;

    mapping(address => bool) public verified;

    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10**18; // (Varies by network and job)
    }

    function makeRequest(string memory _tweetId)
        external
        returns (bytes32 requestId)
    {
        requestId = requestVolumeData(_tweetId);
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData(string memory _tweetId)
        public
        returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        request.add(
            "get",
            "https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-address-hash"
        );

        string memory _params = string(abi.encodePacked("tweetId=", _tweetId));
        request.add("queryParams", _params);

        request.add("path", "data");

        // Multiply the result by 1000000000000000000 to remove decimals
        // int256 timesAmount = 10**18;
        // request.addInt("times", timesAmount);

        // Sends the request
        requestId = sendChainlinkRequestTo(oracle, request, fee);

        requestCaller[requestId] = msg.sender;
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _hash)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit Callback(_requestId, _hash);
        requests[_requestId] = _hash;
        address _caller = requestCaller[_requestId];
        require(
            _hash == uint256(keccak256(abi.encodePacked(_caller))),
            "Not same address, caller and tweet"
        );
        emit OK(_caller);
        verified[_caller] = true;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}
