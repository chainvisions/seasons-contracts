pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISEED.sol";

/// @title Seasons Epoch Manager
/// @author Chainvisions
/// @notice this contract manages epochs on Seasons and determines the state of the epoch.
/// @dev Despite being in production, this code does not guarantee any form of safety, I have
/// taken steps to ensure this contract is bug-free but cannot guarantee anything.

contract EpochManager is Ownable {
    using SafeMath for uint256;

    struct Epoch {
        uint256 epochNo;
        uint256 burnPeriodTime;
        uint256 emissionPeriodStartTime;
        uint256 emissionPeriodEndTime;
    }

    // Token addresses
    address public berry;
    address public seeds;

    // Variable for initializing an epoch.
    bool public managerInitialied;
    // SEED supply threshold for the epoch to advance.
    uint256 public supplyThreshold;
    // Duration of burn period.
    uint256 public burnPeriodDuration;
    // Duration of emission period.
    uin256 public emissionPeriodDuration;
    // Epoch variable
    Epoch public epochs;

    // Events for monitoring epoch advancements, BERRY burns and SEED burns.
    event SeedsBurned(uint256 indexed burned, address indexed burner);
    event BerryBurned(uint256 indexed burned, address indexed burner);
    event EpochAdvanced(uint256 indexed previousEpoch, uint256 indexed newEpoch, address indexed caller);

    // @notice Initializes the Epoch Manager.
    function initializeEpoch(address _berry, address _seeds) public onlyOwner {
        require(managerInitialied != true, "Epoch Manager: Epoch already initialized.");
        // Initialize tokens.
        berry = _berry;
        seeds = _seeds;

        // Create new epoch
        Epoch storage epoch = epochs;
        epoch.epochNo = 1;
        uint256 burnTime = now.add(burnPeriodDuration);
        epoch.burnPeriodTime = burnTime;
        uint256 startTime = burnTime.add(86400);
        epoch.emissionPeriodStartTime = startTime;
        uint256 endTime = startTime.add(emissionPeriodDuration);
        epoch.emissionPeriodEndTime = endTime;
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

        // Set burn period time
        uint256 burnTime = now.add(burnPeriodDuration);
        epoch.burnPeriodTime = burnTime;

        // Set the emission start time
        uint256 startTime = burnTime.add(86400); // 1 day after the burn period ends.
        epoch.emissionPeriodStartTime = startTime;

        // Set the emission end time
        uint256 endTime = startTime.add(emissionPeriodDuration);
        epoch.emissionPeriodEndTime = endTime;
        
        emit EpochAdvanced(prevEpoch, newEpoch, msg.sender);
    }

    /// @notice Burns BERRY for SEEDS
    function burnForSeeds(uint256 _amount) public {
        Epoch storage epoch = epochs;
        require(now <= epoch.burnPeriodTime, "Epoch Manager: BERRY burn period over.");
        ISEEDS(berry).burnTokens(msg.sender, _amount);
        emit BerryBurned(_amount, msg.sender);
    }

    /// @notice Burns SEEDS for BERRY
    function burnForBerry(uint256 _amount) public {
        Epoch storage epoch = epochs;
        require(now >= epoch.emissionPeriodEndTime, "Epoch Manager: SEEDS emission is still on-going.");
        ISEEDS(seeds).burnTokens(msg.sender, _amount);
        emit SeedsBurned(_amount, msg.sender);
    }

    /// @notice Function to view the start time for emission
    /// @dev This function is used in the SEEDS SeedPlanter contract.
    function emissionEndTime() public view returns(uint256) {
        Epoch storage epoch = epochs;
        return epoch.emissionPeriodStartTime;
    }
    /// @notice Function to view the end time for emission
    /// @dev This function is used in the SEEDS SeedPlanter contract.
    function emissionEndTime() public view returns(uint256) {
        Epoch storage epoch = epochs;
        return epoch.emissionPeriodEndTime;
    }

    function adjustSupplyThreshold(uint256 _threshold) public onlyOwner {
        supplyThreshold = _threshold;
    }

    function adjustBurnPeriod(uint256 _burnPeriodDuration) public onlyOwner {
        burnPeriodDuration = _burnPeriodDuration;
    }

    function adjustEmissionPeriod(uint256 _emissionPeriodDuration) public onlyOwner {
        emissionPeriodDuration = _emissionPeriodDuration;
    }

}