// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./Platforms.sol";

/// @notice Each request information.
/// @dev Emitted when a request is made. Its used in callback functions for request's context information.
struct RequestData {
    // The address which called the function that made the request.
    address caller;
    // The platform to be verified
    uint256 platformId;
    // The API query parameter. Can be userId, postId, userName.
    uint256 userId;
}

/// @title APIConsumer
/// @author Nicolás Acosta
/// @notice Used to request all the information needed to verify accounts. Talks to each platform's database.
/// @dev Uses a Chainlink oracle to make API calls, to verify that the ownership of a Platform user.
abstract contract APIConsumer is ChainlinkClient, Platforms {
    using Chainlink for Chainlink.Request;

    /// @notice $LINK (Chainlink's token) address.
    /// @dev Explain to a developer any extra details.
    address public link;

    /// @notice Chainlink's oracle address.
    /// @dev The address of the contract that will make the Platforms' information requests.
    address public oracle;

    /// @notice A chainlink's [HttpGet > JsonParse > Multiply > Uint256 > Eth tx] job Id.
    /// @dev The id of the program that needs to be ejecuted to get the Platforms' information.
    bytes32 public getUInt256JobId;

    /// @notice The Chainlink's job fee.
    /// @dev The fee that has to be paid for every request.
    uint256 public oracleFee;

    /// @notice Each request infomartion is saved here.
    /// @dev Chainlink's requestId => RequestData information. Its used in callback functions for request's context information.
    mapping(bytes32 => RequestData) internal requests;

    string public apiBaseURL;

    constructor() {
        link = 0xa36085F69e2889c224210F603D836748e7dC0088;
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        getUInt256JobId = "d5270d1c311941d0b08bead21fea7747";
        oracleFee = 0.1 * 10**18;
        apiBaseURL = "https://pohtwitter.web.app/api/";

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

    /// @notice Requests a Platform's information.
    /// @dev Creates a Chainlink request to the API.
    /// @param _platformId The platform to verify
    /// @param _queryParameter The information to verify. A user's id, username, address.
    /// @param _callbackFunction The function that will be ejecuted once the information was fetched.
    /// @param _caller The address that started the verifiaction process.
    function _makeRequest(
        uint256 _platformId,
        uint256 _userId // bool secondStep, bytes4 _callbackFunction, address _caller
    ) internal {
        Platform memory _platform = platforms[_platformId];

        // Set the request's information
        Chainlink.Request memory request = buildChainlinkRequest(
            getUInt256JobId,
            address(this),
            this.fulfillOneStepAddressHashRequest.selector
        );

        // Concat the query string => "param=someUserId"
        string memory _params = string(
            bytes.concat(bytes("param="), bytes(uint2str(_userId)))
        );

        // api/platform/1 or api/platform/2
        string memory _url = string(
            bytes.concat(
                bytes(apiBaseURL),
                bytes(_platform.name)
                // ,bytes((secondStep ? "/2" : "/1"))
            )
        );

        // Set the URL of the API call.
        request.add("get", _url);

        // Set the query parameters.
        request.add("queryParams", _params);

        // Send Chainlink request and get its id.
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, oracleFee);

        // Save request information for its callback.
        requests[requestId] = RequestData(_msgSender(), _platformId, _userId);
    }

    // /// @notice Request the address mentioned in the platform.
    // function _requestTwoStepAddressHash(
    //     uint256 _platformId,
    //     string memory _param
    // ) internal {
    //     _makeRequest(
    //         _platformId,
    //         _param,
    //         false,
    //         this.fulfillTwoStepAddressHashRequest.selector,
    //         _msgSender()
    //     );
    // }

    // function _requestTwoStepUserId(RequestData memory _previousRequest)
    //     internal
    // {
    //     _makeRequest(
    //         _previousRequest.platformId,
    //         _previousRequest.parameter,
    //         true,
    //         this.fulfillTwoStepUserIdRequest.selector,
    //         _previousRequest.caller
    //     );
    // }

    function _requestOneStepAddressHash(uint256 _platformId, uint256 _userId)
        internal
    {
        _makeRequest(
            _platformId,
            _userId
            // false,
            // this.fulfillOneStepAddressHashRequest.selector,
            // _msgSender()
        );
    }

    // function fulfillTwoStepAddressHashRequest(bytes32 _requestId, uint256 _hash)
    //     public
    //     virtual;

    // function fulfillTwoStepUserIdRequest(bytes32 _requestId, uint256 _userId)
    //     public
    //     virtual;

    function fulfillOneStepAddressHashRequest(bytes32 _requestId, uint256 _hash)
        public
        virtual;

    function uint2str(uint256 _i) public pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
