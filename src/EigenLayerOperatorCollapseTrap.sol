// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "drosera-contracts/ITrap.sol";

interface IMockEigenLayer {
    function getOperatorStake(address operator) external view returns (uint256);
    function getBaselineStake(address operator) external view returns (uint256);
    function isSlashed(address operator) external view returns (bool);
    function getPendingUndelegations(address operator) external view returns (uint256);
    function getUndelegationThreshold() external view returns (uint256);
}

contract EigenLayerOperatorCollapseTrap is ITrap {

    address public constant MOCK_EIGENLAYER = 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a;
    address public constant MONITORED_OPERATOR = 0x0000000000000000000000000000000000000002;

    function collect() external view override returns (bytes memory) {
        IMockEigenLayer eigen = IMockEigenLayer(MOCK_EIGENLAYER);

        uint256 currentStake        = eigen.getOperatorStake(MONITORED_OPERATOR);
        uint256 baselineStake       = eigen.getBaselineStake(MONITORED_OPERATOR);
        bool slashed                = eigen.isSlashed(MONITORED_OPERATOR);
        uint256 pendingUndelegations = eigen.getPendingUndelegations(MONITORED_OPERATOR);
        uint256 undelegationThreshold = eigen.getUndelegationThreshold();

        return abi.encode(
            currentStake,
            baselineStake,
            slashed,
            pendingUndelegations,
            undelegationThreshold
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // Data length guard
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        // Decode current block (data[0]) and oldest block (data[data.length - 1])
        (
            uint256 currentStake,
            ,
            bool isSlashed,
            uint256 currentUndelegations,
        ) = abi.decode(data[0], (uint256, uint256, bool, uint256, uint256));

        // Decode oldest sample for delta comparison
        (
            uint256 oldStake,
            ,
            ,
            uint256 oldUndelegations,
            uint256 undelegationThreshold
        ) = abi.decode(data[data.length - 1], (uint256, uint256, bool, uint256, uint256));

        uint8 triggeredVectors = 0;
        bool stakeDrain        = false;
        bool slashingSignal    = false;
        bool undelegationSpike = false;

        // Vector 1 — Stake Collapse Delta
        // Detects: stake dropped > 20% compared to oldest sample in window
        if (oldStake > 0) {
            uint256 dropThreshold = (oldStake * 80) / 100; // 20% drop
            if (currentStake < dropThreshold) {
                stakeDrain = true;
                triggeredVectors++;
            }
        }

        // Vector 2 — Slashing Signal (absolute — binary flag)
        if (isSlashed) {
            slashingSignal = true;
            triggeredVectors++;
        }

        // Vector 3 — Undelegation Spike Delta
        // Detects: undelegations grew > 50% compared to oldest sample in window
        if (oldUndelegations > 0) {
            uint256 spikeThreshold = (oldUndelegations * 150) / 100; // 50% growth
            if (currentUndelegations > spikeThreshold) {
                undelegationSpike = true;
                triggeredVectors++;
            }
        } else if (currentUndelegations > undelegationThreshold) {
            // Fallback: if no prior undelegations, use absolute threshold
            undelegationSpike = true;
            triggeredVectors++;
        }

        // Fire if 2 or more vectors triggered
        if (triggeredVectors >= 2) {
            return (true, abi.encode(
                currentStake,
                oldStake,
                isSlashed,
                currentUndelegations,
                triggeredVectors
            ));
        }

        return (false, bytes(""));
    }
}
