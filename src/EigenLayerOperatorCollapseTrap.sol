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

    struct OperatorState {
        uint256 currentStake;
        uint256 baselineStake;
        bool isSlashed;
        uint256 pendingUndelegations;
        uint256 undelegationThreshold;
    }

    function collect() external view override returns (bytes memory) {
        IMockEigenLayer eigen = IMockEigenLayer(MOCK_EIGENLAYER);

        uint256 currentStake = eigen.getOperatorStake(MONITORED_OPERATOR);
        uint256 baselineStake = eigen.getBaselineStake(MONITORED_OPERATOR);
        bool slashed = eigen.isSlashed(MONITORED_OPERATOR);
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

        (
            uint256 currentStake,
            uint256 baselineStake,
            bool isSlashed,
            uint256 pendingUndelegations,
            uint256 undelegationThreshold
        ) = abi.decode(data[0], (uint256, uint256, bool, uint256, uint256));

        uint8 triggeredVectors = 0;
        bool stakeDrain = false;
        bool slashingSignal = false;
        bool withdrawalQueueSpike = false;

        // Vector 1: Stake drain > 30%
        if (baselineStake > 0) {
            uint256 drainThreshold = (baselineStake * 70) / 100;
            if (currentStake < drainThreshold) {
                stakeDrain = true;
                triggeredVectors++;
            }
        }

        // Vector 2: Slashing signal
        if (isSlashed) {
            slashingSignal = true;
            triggeredVectors++;
        }

        // Vector 3: Withdrawal queue spike
        if (undelegationThreshold > 0 && pendingUndelegations > undelegationThreshold) {
            withdrawalQueueSpike = true;
            triggeredVectors++;
        }

        // Fire if 2 or more vectors triggered
        if (triggeredVectors >= 2) {
            return (true, abi.encode(
                currentStake,
                baselineStake,
                isSlashed,
                pendingUndelegations,
                triggeredVectors
            ));
        }

        return (false, bytes(""));
    }
}
