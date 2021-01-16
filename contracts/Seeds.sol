pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Seeds is BEP20('SEEDS', 'SEEDS'), AccessControl {
    // Role identifier for minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Contract that distributes transfer fees
    address public feeDistributor;
    // Epoch Manager with the power to remotely burn SEEDS.
    address public epochManager;

    modifier managerOnly() {
        require(msg.sender == epochManager, "SEEDS: Only the epoch manager can call this function!");
        _;
    }

    constructor(address _feeDistributor) public {
        feeDistributor = _feeDistributor;
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 burnRate = 1;
        uint256 burnAmount = amount.mul(burnRate).div(100);
        uint256 stakerRewards = burnAmount;
        uint256 amountSent = amount.sub(burnAmount.add(stakerRewards));
        require(amount == amountSent + burnAmount + stakerRewards, "Burn value invalid");
        super._burn(sender, burnAmount);
        super._transfer(sender, feeDistributor, stakerRewards);
        super._transfer(sender, recipient, amountSent);
        amount = amountSent;
    }

    function changeDistributor() public {
        require(msg.sender == feeDistributor, "SEEDS: Only the fee distributor can call this function.");
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by an account with the minter role.
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(_to, _amount);
    }

    /// @notice Allows the epoch manager to burn `_amount` tokens from `_burnedFrom`.
    function burnTokens(address _burnedFrom, uint256 _amount) public managerOnly {
        _burn(_burnedFrom, _amount);
    }

}