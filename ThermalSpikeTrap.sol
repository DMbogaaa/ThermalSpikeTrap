// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

/// @title ThermalSpikeTrap — triggers on basefee OR gaslimit changes >1%
contract ThermalSpikeTrap is ITrap {
    uint256 private constant CHANGE_THRESHOLD_PERCENT = 1; // сниженный порог

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.basefee, block.gaslimit);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, abi.encode("Not enough data"));
        }

        (uint256 currentBasefee, uint256 currentGaslimit) = abi.decode(data[0], (uint256, uint256));
        (uint256 previousBasefee, uint256 previousGaslimit) = abi.decode(data[1], (uint256, uint256));

        if (previousBasefee == 0 || previousGaslimit == 0) {
            return (false, abi.encode("Invalid baseline data"));
        }

        uint256 basefeeChange = _percentChange(currentBasefee, previousBasefee);
        uint256 gaslimitChange = _percentChange(currentGaslimit, previousGaslimit);

        // ИЛИ вместо И — срабатывает если хотя бы один параметр изменился более чем на 1%
        if (basefeeChange > CHANGE_THRESHOLD_PERCENT || gaslimitChange > CHANGE_THRESHOLD_PERCENT) {
            return (true, abi.encode("Thermal spike detected"));
        }

        return (false, abi.encode("No spike detected"));
    }

    function _percentChange(uint256 current, uint256 previous) private pure returns (uint256) {
        if (current > previous) {
            return ((current - previous) * 100) / previous;
        } else {
            return ((previous - current) * 100) / previous;
        }
    }
}
