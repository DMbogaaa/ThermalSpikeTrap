# ThermalSpikeTrap

## Purpose & Objective

Create a Drosera-compatible smart contract trap that continuously monitors key Ethereum block parameters — block.basefee and block.gaslimit. The trap activates when both parameters simultaneously fluctuate beyond a 1% threshold between consecutive blocks, signaling a thermal-like spike in network conditions and triggering an on-chain alert via an event dispatcher contract.

## Background & Rationale
Rapid and concurrent changes in base fee and gas limit often indicate:

- Sudden network congestion or easing,
- Possible validator reordering or manipulations,
- Emergent anomalies or attack vectors,
- Network states that may impact DeFi protocol stability.

Timely detection is critical to ensure robust network health monitoring and early warning for users and applications.

## Core Mechanics

The ThermalSpikeTrap collects encoded values of the current block’s basefee and gaslimit, then compares them to the previous block’s recorded data. It calculates the percentage change for each parameter independently. When both exceed the 1% change threshold simultaneously, the trap signals a thermal spike event.

## Trap Logic

**Contract: ThermalSpikeTrap.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

/// @title ThermalSpikeTrap — triggers on basefee AND gaslimit changes > 1%
contract ThermalSpikeTrap is ITrap {
    uint256 private constant CHANGE_THRESHOLD_PERCENT = 1;

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

        bool triggered = basefeeChange > CHANGE_THRESHOLD_PERCENT && gaslimitChange > CHANGE_THRESHOLD_PERCENT;

        bytes memory metadata = abi.encode(
            "basefeeChange", basefeeChange,
            "gaslimitChange", gaslimitChange,
            "currentBasefee", currentBasefee,
            "previousBasefee", previousBasefee,
            "currentGaslimit", currentGaslimit,
            "previousGaslimit", previousGaslimit
        );

        return (
            triggered,
            triggered
                ? abi.encode("Thermal spike detected", metadata)
                : abi.encode("No spike detected", metadata)
        );
    }

    function _percentChange(uint256 current, uint256 previous) private pure returns (uint256) {
        if (previous == 0) return 0;
        uint256 diff = current > previous ? current - previous : previous - current;
        return (diff * 100) / previous;
    }
}
```

## Response Contract

**Contract: HeatSignalDispatcher.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HeatSignalDispatcher {
    event HeatSpike(bytes data);

    function dispatchHeat(bytes calldata data) external {
        emit HeatSpike(data);
    }
}
```


## Deployment Instructions

Deploy both contracts (ThermalSpikeTrap and HeatSignalDispatcher) on your target network (e.g., Ethereum Hoodi) using Foundry or another Solidity deployment tool. Then configure Drosera with the deployed addresses and response function to start monitoring.


## Trigger Frequency

With the chosen dual-parameter threshold, the trap typically triggers approximately once every 4 blocks, providing a balanced sensitivity that reduces noise while catching meaningful network fluctuations.


## Response & Integration

Upon triggering, the trap invokes the dispatchHeat function of the linked response contract, forwarding encoded event data. 
The response contract emits a HeatSpike event, enabling off-chain services or dashboards to process and act on the alert.

## Implementation Highlights

- Uses abi.encode for all data and string encodings to ensure compatibility with Drosera’s infrastructure.
- Pure functions ensure gas efficiency and deterministic outcomes.
- Easily extendable to incorporate more block parameters or configurable thresholds.

## Info
- Created: August 7, 2025
- X.com: @DMbogaaa
- Discord: dmbogaaa
- Mail: bogatovdmitrij8@gmail.com
