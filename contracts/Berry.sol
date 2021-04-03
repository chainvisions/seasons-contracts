pragma solidity 0.6.12;

import "@openzeppelin/contracts//token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BerryToken is ERC20('BERRY Token', 'BERRY'), AccessControl {
    // Role identifier for minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Epoch Manager with the power to remotely burn BERRY.
    address public epochManager;

    event SystemUpgrade(address indexed prevManager, address indexed newManager);

    modifier managerOnly() {
        require(msg.sender == epochManager, "BERRY: Only the epoch manager can call this function!");
        _;
    }

    constructor() public {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles and upgrade the protocol.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to upgrade the epoch system
    /// @dev This allows for security upgrades and more, allowing
    /// the protocol to evolve.
    function systemUpgrade(address _epochManager) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SEEDS: Only an admin can perform a system upgrade.");
        address prevManager = epochManager;
        epochManager = _epochManager;
        emit SystemUpgrade(prevManager, epochManager);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by an account with the minter role.
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "BERRY: Caller is not a minter");
        _mint(_to, _amount);
    }

    /// @notice Allows the epoch manager to burn `_amount` tokens from `_burnedFrom`.
    function burnTokens(address _burnedFrom, uint256 _amount) public managerOnly {
        _burn(_burnedFrom, _amount);
    }

}