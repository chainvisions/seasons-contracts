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
    // Duration of emission period.
    uin256 public emissionPeriodDuration;
    // Epoch variable
    Epoch public epochs;

    struct Epoch {
        uint256 epochNo;
        uint256 emissionPeriodEndTime;
        bool seedBurnEnabled;
    }

    // Events for monitoring epoch advancements, BERRY burns and SEED burns.
    event SeedsBurned(uint256 indexed burned, address indexed burner);
    event BerryBurned(uint256 indexed burned, address indexed burner);
    event EpochAdvanced(uint256 indexed previousEpoch, uint256 indexed newEpoch, address indexed caller);

    // @notice Initializes the Epoch Manager
    function initializeEpoch() public {

    }

    /// @notice Advance to the next epoch.
    /// @dev This triggers a new epoch cycle.
    function advanceEpoch() public {
        require(SEEDS.totalSupply() <= supplyThreshold, "Epoch Manager: Supply threshold must be met to advance the epoch");

        // Increment the counter
        Epoch storage epoch = epochs;
        uint256 prevEpoch = epoch.epochNo;
        uint256 newEpoch = prevEpoch.add(1);
        epoch.epochNo = newEpoch;

        // Set the emission time
        uint256 endTime = now.add(emissionPeriodDuration);
        epoch.emissionPeriodEndTime = endTime;
        
        emit EpochAdvanced(prevEpoch, newEpoch, msg.sender);
    }

    /// @notice Burns BERRY for SEEDS
    function burnForSeeds(uint256 _amount) public {
        emit BerryBurned(_amount, msg.sender);
    }

    /// @notice Burns SEEDS for BERRY
    function burnForBerry(uint256 _amount) public {
        emit SeedsBurned(_amount, msg.sender);
    }

    function adjustSupplyThreshold(_threshold) public {
        supplyThreshold = _threshold;
    }

}