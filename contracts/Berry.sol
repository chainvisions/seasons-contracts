pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract BerryToken is BEP20('BERRY Token', 'BERRY') {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterBush).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}