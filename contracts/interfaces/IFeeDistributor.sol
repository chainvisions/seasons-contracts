pragma solidity 0.6.12;

interface IFeeDistributor {
    function notifyRewardAmount(uint256 _amount) external;
}