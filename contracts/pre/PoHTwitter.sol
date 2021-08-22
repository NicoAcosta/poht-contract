// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TwitterAPIConsumer.sol";

interface IProofOfHumanity {
    function isRegistered(address _address) external view returns (bool);
}

contract PoHTwitterV5 is TwitterAPIConsumer {
    event Verification(address indexed caller, uint256 indexed twitterUserID);

    address public poHAddress;

    // address => twitter account id
    mapping(address => uint256) public verifiedAddress;
    mapping(uint256 => address) public verifiedUserId;

    constructor() TwitterAPIConsumer() {
        _setPoHAddress(0x6a6b6121168c4Ed068204661cbCA3349b61e3e98);
    }

    function _setPoHAddress(address _address) internal {
        poHAddress = _address;
    }

    function setPoHAddress(address _address) external onlyOwner {
        _setPoHAddress(_address);
    }

    function _isRegistered() internal view returns (bool) {
        return IProofOfHumanity(poHAddress).isRegistered(_msgSender());
    }

    function verify(string memory _tweetId)
        external
        returns (bytes32 requestId)
    {
        require(_isRegistered());
        requestId = _requestTweetAddressHash(_tweetId);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillTweetAddressHashRequest(bytes32 _requestId, uint256 _hash)
        public
        override
        recordChainlinkFulfillment(_requestId)
    {
        RequestData memory request = requests[_requestId];
        require(
            _hash == uint256(keccak256(abi.encodePacked(request.caller))),
            "Not same address, caller and tweet"
        );
        _requestTweetAuthor(request);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillTweetAuthorRequest(bytes32 _requestId, uint256 _userId)
        public
        override
        recordChainlinkFulfillment(_requestId)
    {
        require(_userId != 0, "API Error");
        address _caller = requests[_requestId].caller;
        verifiedAddress[_caller] = _userId;
        verifiedUserId[_userId] = _caller;
        emit Verification(_caller, _userId);
    }

    function verified() external view returns (uint256) {
        return verifiedAddress[_msgSender()];
    }
}
