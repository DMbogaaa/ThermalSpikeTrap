// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HeatSignalDispatcher {
    event HeatSpike(bytes data);

    function dispatchHeat(bytes calldata data) external {
        emit HeatSpike(data);
    }
}
