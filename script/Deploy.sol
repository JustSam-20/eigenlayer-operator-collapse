// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EigenLayerOperatorCollapseResponse.sol";

contract MockEigenLayer {
    address public constant MONITORED_OPERATOR = 0x0000000000000000000000000000000000000002;

    uint256 private _operatorStake = 1000 ether;
    uint256 private _baselineStake = 1000 ether;
    bool private _isSlashed = false;
    uint256 private _pendingUndelegations = 0;
    uint256 private _undelegationThreshold = 100 ether;

    function getOperatorStake(address) external view returns (uint256) {
        return _operatorStake;
    }

    function getBaselineStake(address) external view returns (uint256) {
        return _baselineStake;
    }

    function isSlashed(address) external view returns (bool) {
        return _isSlashed;
    }

    function getPendingUndelegations(address) external view returns (uint256) {
        return _pendingUndelegations;
    }

    function getUndelegationThreshold() external view returns (uint256) {
        return _undelegationThreshold;
    }

    // Test helpers to simulate attack conditions
    function simulateStakeDrain() external {
        _operatorStake = 500 ether; // 50% drain, triggers Vector 1
    }

    function simulateSlashing() external {
        _isSlashed = true; // triggers Vector 2
    }

    function simulateWithdrawalSpike() external {
        _pendingUndelegations = 200 ether; // exceeds threshold, triggers Vector 3
    }

    function resetState() external {
        _operatorStake = 1000 ether;
        _isSlashed = false;
        _pendingUndelegations = 0;
    }
}

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MockEigenLayer mock = new MockEigenLayer();
        EigenLayerOperatorCollapseResponse response = new EigenLayerOperatorCollapseResponse();

        console.log("MockEigenLayer deployed at:", address(mock));
        console.log("Response deployed at:", address(response));

        vm.stopBroadcast();
    }
}
