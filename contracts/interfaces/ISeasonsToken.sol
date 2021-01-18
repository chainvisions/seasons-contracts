pragma solidity ^0.6.12;

/// @title Seasons Token Interface
/// @dev Basic interface for the Epoch Manager to interact with
/// seasons tokens.

interface ISeasonsToken {
    function burnTokens(address _burnedFrom, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}