pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BerryToken is BEP20('BERRY Token', 'BERRY'), AccessControl {
    // Role identifier for minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Epoch Manager with the power to remotely burn BERRY.
    address public epochManager;

    modifier managerOnly() {
        require(msg.sender == epochManager, "BERRY: Only the epoch manager can call this function!");
        _;
    }

    constructor() public {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by an account with the minter role.
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(_to, _amount);
    }

    /// @notice Allows the epoch manager to burn `_amount` tokens from `_burnedFrom`.
    function burnTokens(address _burnedFrom, uint256 _amount) public managerOnly {
        _burn(_burnedFrom, _amount);
    }

}