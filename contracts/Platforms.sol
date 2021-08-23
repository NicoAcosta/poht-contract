// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

// Struct for each Platform
struct Platform {
    // Platform name (lowcase)
    string name;
    // If it requires two step (true) or one step (false) verification
    bool twoStepVerification;
    string apiAddressURL;
    string apiUserIdURL;
}

/// @title Platforms
/// @author Nicolás Acosta
/// @notice Handles platforms information.
/// @dev Explain to a developer any extra details
contract Platforms is Ownable {
    /// @notice Emitted when a platform is added.
    /// @param platformId The platform position in the `platforms` public array.
    /// @param name The platform name.
    event NewPlatform(uint256 platformId, string name);

    /// @notice Platforms information
    /// @dev Struct Platform that contains its name and the kind of verification
    Platform[] public platforms;

    constructor() {
        _addPlatform(
            "Twitter",
            true,
            "https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-address-hash",
            "https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-author"
        );
    }

    /// @notice Adds a new platform to the platforms list.
    /// @dev Appends the new Platform instance to the `platforms` array. Its id is the array position. Emits `NewPlatform` event.
    /// @param _name The new platform's name.
    /// @param _twoStepVerification The new platform's kind of verification: two step (true) or one step (false).
    function _addPlatform(
        string memory _name,
        bool _twoStepVerification,
        string memory _apiAddressURL,
        string memory _apiUserIdURL
    ) private {
        // Create new Platform with its information.
        Platform memory _platform = Platform(
            _name,
            _twoStepVerification,
            _apiAddressURL,
            _apiUserIdURL
        );

        // Add it to the `platforms` list.
        platforms.push(_platform);

        // Set its id as its position in the `platforms` list.
        uint256 _platformId = platforms.length - 1;

        // Emits `NewPlatform` event containind its id and its name.
        emit NewPlatform(_platformId, _platform.name);
    }

    // Same as the above, but can be called by contract's owner.
    function addPlatform(
        string memory _name,
        string memory _apiAddressURL,
        string memory _apiUserIdURL,
        bool _twoStepVerification
    ) external onlyOwner {
        _addPlatform(
            _name,
            _twoStepVerification,
            _apiAddressURL,
            _apiUserIdURL
        );
    }
}
