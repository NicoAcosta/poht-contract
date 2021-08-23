// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./APIConsumer.sol";

// import "solidity-util/lib/Integers.sol";

interface IProofOfHumanity {
    function isRegistered(address _address) external view returns (bool);
}

/// @title PoHVerifier
/// @author Nicolás Acosta
/// @notice Verifies some address' web2 profiles in different platforms.
/// @dev Explain to a developer any extra details
contract PoHVerifierV1 is APIConsumer {
    // using Integers for uint256;

    event Verification(
        uint256 platformId,
        address indexed caller,
        uint256 indexed userId
    );

    address public poHAddress;

    // address => twitter account id
    mapping(uint256 => mapping(address => uint256)) public verifiedAddress;
    mapping(uint256 => mapping(uint256 => address)) public verifiedUserId;

    /// @notice Checks if the caller was verified in ProofOfHumanity
    modifier PoHRegistered() {
        require(
            IProofOfHumanity(poHAddress).isRegistered(_msgSender()),
            "Not registered in PoH"
        );
        _;
    }

    constructor() APIConsumer() {
        poHAddress = 0x6a6b6121168c4Ed068204661cbCA3349b61e3e98;
    }

    /// @notice Checks if some caller's platform profile was verified.
    /// @dev Explain to a developer any extra details
    /// @param _platformId The platform to check.
    /// @return If verified, returns its user id for that platform.
    function verified(uint256 _platformId) external view returns (uint256) {
        return verifiedAddress[_platformId][_msgSender()];
    }

    function verify(uint256 _platformId, string memory _queryParameter)
        external
        PoHRegistered
    {
        platforms[_platformId].twoStepVerification
            ? _twoStepVerification(_platformId, _queryParameter)
            : _oneStepVerification(_platformId, _queryParameter);
    }

    function _twoStepVerification(
        uint256 _platformId,
        string memory _queryParameter
    ) private {
        _requestTwoStepAddressHash(_platformId, _queryParameter);
    }

    function _oneStepVerification(uint256 _platformId, string memory _userId)
        private
    {
        _requestOneStepAddressHash(_platformId, _userId);
    }

    function fulfillTwoStepAddressHashRequest(bytes32 _requestId, uint256 _hash)
        public
        override
        recordChainlinkFulfillment(_requestId)
    {
        RequestData memory request = requests[_requestId];
        require(
            verifyAddressHash(request.caller, _hash),
            "Not same address, caller and tweet"
        );
        _requestTwoStepUserId(request);
    }

    function fulfillTwoStepUserIdRequest(bytes32 _requestId, uint256 _userId)
        public
        override
        recordChainlinkFulfillment(_requestId)
    {
        require(_userId != 0, "API Error");
        RequestData memory _request = requests[_requestId];
        _saveVerification(_request.platformId, _request.caller, _userId);
    }

    function fulfillOneStepAddressHashRequest(bytes32 _requestId, uint256 _hash)
        public
        override
        recordChainlinkFulfillment(_requestId)
    {
        RequestData memory request = requests[_requestId];
        require(
            verifyAddressHash(request.caller, _hash),
            "Not same address, caller and tweet"
        );
        uint256 _userId = uint256(
            keccak256(abi.encodePacked(request.parameter))
        );
        _saveVerification(request.platformId, request.caller, _userId);
    }

    function _saveVerification(
        uint256 _platformId,
        address _owner,
        uint256 _userId
    ) private {
        verifiedAddress[_platformId][_owner] = _userId;
        verifiedUserId[_platformId][_userId] = _owner;

        emit Verification(_platformId, _owner, _userId);
    }

    function verifyAddressHash(address _address, uint256 _hash)
        public
        pure
        returns (bool)
    {
        return _hash == addressHash(_address);
    }

    function addressHash(address _address) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_address)));
    }
}
