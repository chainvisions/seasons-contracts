pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IFeeDistributor.sol";

contract Seeds is ERC20('SEEDS', 'SEEDS'), AccessControl {
    // Role identifier for minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Contract that distributes transfer fees
    address public feeDistributor;
    // Epoch Manager with the power to remotely burn SEEDS.
    address public epochManager;

    event SystemUpgrade(address indexed prevManager, address indexed newManager);

    modifier managerOnly() {
        require(msg.sender == epochManager, "SEEDS: Only the epoch manager can call this function!");
        _;
    }

    modifier adminOnly() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SEEDS: Only the admin can call this function.");
        _;
    }

    constructor(address _feeDistributor) public {
        feeDistributor = _feeDistributor;
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 burnRate = 1;
        uint256 burnAmount = amount.mul(burnRate).div(100);
        uint256 stakerRewards = burnAmount;
        uint256 amountSent = amount.sub(burnAmount.add(stakerRewards));
        require(amount == amountSent + burnAmount + stakerRewards, "SEEDS: Burn value invalid.");
        super._burn(sender, burnAmount);
        super._transfer(sender, feeDistributor, stakerRewards);
        super._transfer(sender, recipient, amountSent);
        IFeeDistributor(feeDistributor).notifyRewardAmount(stakerRewards);
        amount = amountSent;
    }

    /// @notice Function to change transfer fee distribution.
    function changeDistributor(address _feeDistributor) public adminOnly {
        feeDistributor = _feeDistributor;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by an account with the minter role.
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(hasRole(MINTER_ROLE, msg.sender), "SEEDS: Caller is not a minter");
        _mint(_to, _amount);
    }

    /// @notice Allows the epoch manager to burn `_amount` tokens from `_burnedFrom`.
    function burnTokens(address _burnedFrom, uint256 _amount) public managerOnly {
        _burn(_burnedFrom, _amount);
    }

}