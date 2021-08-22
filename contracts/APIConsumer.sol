// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./PoHVerifier.sol";

struct RequestData {
    address caller;
    uint8 platformId;
    string parameter;
}

interface IProofOfHumanity {
    function isRegistered(address _address) external view returns (bool);
}

struct Platform {
    string name;
    string apiAddressURL;
    string apiUserIdURL;
    VerificationInput verificationInput;
}

// Platform("Twitter", "url", "url", postId)

enum VerificationInput {
    userId,
    username,
    POST_ID
}

abstract contract APIConsumer is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    address public link;
    address public oracle;
    bytes32 public getUInt256JobId;
    uint256 public oracleFee;
    string public apiAddressURL;
    string public apiAuthorURL;

    mapping(bytes32 => RequestData) internal requests;
    Platform[] public platforms;

    constructor() {
        link = 0xa36085F69e2889c224210F603D836748e7dC0088;
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        getUInt256JobId = "d5270d1c311941d0b08bead21fea7747";
        oracleFee = 0.1 * 10**18;
        apiAddressURL = "https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-address-hash";
        apiAuthorURL = "https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-author";

        if (link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(link);
        }
    }

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract
     */
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function _makeRequest(
        uint8 _platformId,
        string memory _queryParameter,
        string memory _apiURL,
        bytes4 _callbackFunction,
        address _caller
    ) internal {
        Chainlink.Request memory request = buildChainlinkRequest(
            getUInt256JobId,
            address(this),
            _callbackFunction
        );

        string memory _params = string(
            abi.encodePacked("param=", _queryParameter)
        );

        request.add("get", _apiURL);
        request.add("queryParams", _params);
        // request.add("path", "data");

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, oracleFee);

        requests[requestId] = RequestData(
            _caller,
            _platformId,
            _queryParameter
        );
    }

    function _requestAddressHash(uint8 _platformId, string memory _param)
        internal
    {
        _makeRequest(
            _platformId,
            _param,
            platforms[_platformId].apiAddressURL,
            this.fulfillAddressHashRequest.selector,
            _msgSender()
        );
    }

    function _requestUserId(RequestData memory _previousRequest) internal {
        _makeRequest(
            _previousRequest.platformId,
            _previousRequest.parameter,
            platforms[_previousRequest.platformId].apiUserIdURL,
            this.fulfillUserIdRequest.selector,
            _previousRequest.caller
        );
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillAddressHashRequest(bytes32 _requestId, uint256 _hash)
        public
        virtual;

    /**
     * Receive the response in the form of uint256
     */
    function fulfillUserIdRequest(bytes32 _requestId, uint256 _userId)
        public
        virtual;

    // function _setFee(uint256 _linkAmount) internal {
    //     oracleFee = _linkAmount * 10**18;
    // }

    // function _setChainlinkAddress(address _address) internal {
    //     chainlinkAddress = _address;
    // }

    // function setChainlinkAddress(address _address) external onlyOwner {
    //     _setChainlinkAddress(_address);
    // }

    // function _setChainlinkJobId(string memory _jobId) internal {
    //     chainlinkJobId = _jobId;
    // }

    // function setChainlinkJobId(string memory _jobId) external onlyOwner {
    //     _setChainlinkJobId(_jobId);
    // }
}
