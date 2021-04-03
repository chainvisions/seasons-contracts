pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Berry.sol";

contract Jam is ERC20('JAM', 'JAM') {
    BerryToken public berry;

    constructor(
        BerryToken _berry
    ) public {
        berry = _berry;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterBush).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from ,uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    // Safe berry transfer function, just in case if rounding error causes pool to not have enough BERRY.
    function safeBerryTransfer(address _to, uint256 _amount) public onlyOwner {
        uint256 berryBal = berry.balanceOf(address(this));
        if (_amount > berryBal) {
            berry.transfer(_to, berryBal);
        } else {
            berry.transfer(_to, _amount);
        }
    }
}