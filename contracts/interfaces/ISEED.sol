pragma solidity ^0.6.12;

interface ISEEDS {
    function burnTokens(address _burnedFrom, uint256 _amount) external;
}