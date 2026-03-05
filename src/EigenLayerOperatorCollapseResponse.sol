// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EigenLayerOperatorCollapseResponse {

    mapping(address => bool) public authorizedOperators;
    address public owner;

    event OperatorCollapseDetected(
        uint256 currentStake,
        uint256 baselineStake,
        bool isSlashed,
        uint256 pendingUndelegations,
        uint8 triggeredVectors,
        uint256 timestamp
    );

    event OperatorAuthorized(address operator);
    event OperatorRevoked(address operator);

    modifier onlyOperator() {
        require(authorizedOperators[msg.sender], "not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedOperators[msg.sender] = true;
    }

    function authorizeOperator(address operator) external onlyOwner {
        authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    function revokeOperator(address operator) external onlyOwner {
        authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    function respond(
        uint256 currentStake,
        uint256 baselineStake,
        bool isSlashed,
        uint256 pendingUndelegations,
        uint8 triggeredVectors
    ) external onlyOperator {
        emit OperatorCollapseDetected(
            currentStake,
            baselineStake,
            isSlashed,
            pendingUndelegations,
            triggeredVectors,
            block.timestamp
        );
    }
}
