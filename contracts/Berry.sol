pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract BerryToken is BEP20('BERRY Token', 'BERRY') {
    // Epoch Manager with the power to remotely burn BERRY.
    address public epochManager;

    modifier managerOnly() {
        require(msg.sender == epochManager, "BERRY: Only the epoch manager can call this function!");
        _;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterBush).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Allows the epoch manager to burn `_amount` tokens from `_burnedFrom`.
    function burnTokens(address _burnedFrom, uint256 _amount) public managerOnly {
        _burn(_burnedFrom, _amount);
    }

}