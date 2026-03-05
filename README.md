# EigenLayer Operator Collapse Detector

A Drosera Network trap deployed on Hoodi Testnet that monitors simulated EigenLayer operator health across three independent attack vectors.

## What It Monitors

**Vector 1 — Stake Drain:** Detects when an operator's delegated stake drops more than 30% below baseline in a single block, signaling a coordinated withdrawal or slashing attack.

**Vector 2 — Slashing Signal:** Detects when the operator's slashing flag is triggered, indicating protocol-level penalization.

**Vector 3 — Withdrawal Queue Spike:** Detects when pending undelegations exceed the safe threshold, signaling a mass exit event.

The trap fires a response when **any 2 or more vectors trigger simultaneously**, filtering noise while catching coordinated collapse scenarios.

## Contracts

| Contract | Address |
|----------|---------|
| Trap | `0x383EfD31D1383E8cf7aBeD267139d0829F64208c` |
| Response | `0xBB43C0E7790417f539581C95479FBf5E3A12312F` |
| MockEigenLayer | `0xdfDE8aaACc1dCE720301aECA253A28A88B46719a` |

## Network
- **Network:** Hoodi Testnet (Chain ID: 560048)
- **Drosera RPC:** https://relay.hoodi.drosera.io

## Architecture
- `src/EigenLayerOperatorCollapseTrap.sol` — Trap contract (stateless monitor)
- `src/EigenLayerOperatorCollapseResponse.sol` — Response contract (onlyOperator authorized)
- `script/Deploy.sol` — Deployment script for MockEigenLayer + Response

## Testing
To simulate an attack condition on the MockEigenLayer contract, call:
- `simulateStakeDrain()` — triggers Vector 1
- `simulateSlashing()` — triggers Vector 2
- `simulateWithdrawalSpike()` — triggers Vector 3
- `resetState()` — resets all conditions to healthy state
