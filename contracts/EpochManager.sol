pragma solidity ^0.6.12;

/// @title Seasons Epoch Manager
/// @author Chainvisions
/// @notice this contract manages epochs on Seasons and determines the state of the epoch.
/// @dev Despite being in production, this code does not guarantee any form of safety, I have
/// taken steps to ensure this contract is bug-free but cannot guarantee anything.

contract EpochManager {
    using SafeMath for uint256;

    struct Epoch {
        uint256 epochNo;
        uint256 burnPeriodStartTime;
        bool seedBurnEnabled;
    }

    // Variable for initializing an epoch.
    bool public managerInitialied;
    // SEED supply threshold for the epoch to advance.
    uint256 public supplyThreshold;
    // Duration of BERRY burn period.
    uin256 public berryBurnDuration;
    // Epoch variable
    Epoch public epochs;

    struct Epoch {
        uint256 epochNo;
        uint256 burnPeriodStartTime;
        bool seedBurnEnabled;
    }

    // @notice Initializes the Epoch Manager
    function initializeEpoch() public {

    }

    /// @notice Advance to the next epoch.
    /// @dev This triggers a new epoch cycle.
    function advanceEpoch() public {
        // Increment the counter
        Epoch storage epoch = epochs;
        uint256 prevEpoch = epoch.epochNo;
        uint256 newEpoch = prevEpoch.add(1);
        epoch.epochNo = newEpoch;

        // Set the emission time
        
    }

    /// @notice Burns BERRY for SEEDS
    function burnForSeeds() public {

    }

}