pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract Seeds is BEP20('SEEDS', 'SEEDS') {
    address public feeDistributor;

    constructor(address _feeDistributor) public {
        feeDistributor = _feeDistributor;
    }

    function changeDistributor() public {
        require(msg.sender == feeDistributor, "SEEDS: Only the fee distributor can call this function.");
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterBush).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}