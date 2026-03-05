# 🛡️ EigenLayer Operator Collapse Detector

> A production-grade Drosera Network trap deployed on Hoodi Testnet that provides real-time, multi-vector monitoring of EigenLayer operator health — detecting coordinated collapse scenarios before they cause irreversible damage.

---

## 🔍 Overview

EigenLayer operators secure billions in restaked ETH. A sudden operator collapse — whether from coordinated withdrawals, slashing events, or mass undelegation — can cascade into protocol-wide insolvency within minutes.

This trap monitors three independent risk vectors simultaneously. It fires a response only when **two or more vectors trigger in the same block**, eliminating false positives while ensuring no coordinated attack goes undetected.

---

## ⚡ Attack Vectors Monitored

| Vector | Condition | Threshold | Attack Pattern |
|--------|-----------|-----------|----------------|
| 1 — Stake Drain | Delegated stake drops below baseline | > 30% loss in one block | Coordinated withdrawal / rug |
| 2 — Slashing Signal | Operator slashing flag activated | Any slashing event | Protocol-level penalization |
| 3 — Withdrawal Queue Spike | Pending undelegations exceed safe limit | > threshold in one block | Mass exit / bank run |

**Response logic:** Fires if **≥ 2 vectors** trigger simultaneously.

---

## 🏗️ Architecture
```
eigenlayer-operator-collapse/
├── src/
│   ├── EigenLayerOperatorCollapseTrap.sol      # Stateless monitor (collect + shouldRespond)
│   └── EigenLayerOperatorCollapseResponse.sol  # Authorized response emitter
├── script/
│   └── Deploy.sol                              # Deploys MockEigenLayer + Response
├── drosera.toml                                # Drosera trap configuration
└── README.md
```

### How It Works

1. **Every block**, Drosera calls `collect()` on the Trap contract
2. `collect()` reads 5 storage slots from MockEigenLayer (stake, baseline, slashing flag, undelegations, threshold)
3. Drosera passes the encoded data to `shouldRespond()`
4. `shouldRespond()` evaluates all 3 vectors independently
5. If ≥ 2 vectors breach their thresholds → response fires
6. `EigenLayerOperatorCollapseResponse` emits a full-context `OperatorCollapseDetected` event on-chain

---

## 📋 Contract Addresses (Hoodi Testnet)

| Contract | Address |
|----------|---------|
| 🪤 Trap | [`0x383EfD31D1383E8cf7aBeD267139d0829F64208c`](https://hoodi.etherscan.io/address/0x383EfD31D1383E8cf7aBeD267139d0829F64208c) |
| ⚡ Response | [`0xBB43C0E7790417f539581C95479FBf5E3A12312F`](https://hoodi.etherscan.io/address/0xBB43C0E7790417f539581C95479FBf5E3A12312F) |
| 🎭 MockEigenLayer | [`0xdfDE8aaACc1dCE720301aECA253A28A88B46719a`](https://hoodi.etherscan.io/address/0xdfDE8aaACc1dCE720301aECA253A28A88B46719a) |

---

## 🔧 Drosera Configuration

| Parameter | Value |
|-----------|-------|
| Network | Hoodi Testnet |
| Chain ID | 560048 |
| Block Sample Size | 1 |
| Cooldown Period | 33 blocks |
| Min Operators | 1 |
| Max Operators | 3 |
| Private Trap | true |

---

## 🧪 Testing the Trap

The `MockEigenLayer` contract exposes helper functions to simulate attack conditions:
```bash
# Simulate a stake drain (triggers Vector 1)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateStakeDrain()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Simulate a slashing event (triggers Vector 2)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateSlashing()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Simulate a withdrawal queue spike (triggers Vector 3)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateWithdrawalSpike()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Reset all conditions to healthy state
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "resetState()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY
```

To trigger the response, run **any two** simulate commands in the same block.

---

## 🔐 Security Design

- **Stateless Trap:** No storage variables — safe against Drosera's shadow-fork redeployment model
- **Data Length Guard:** `shouldRespond()` validates data before decoding — prevents revert on empty blobs
- **onlyOperator Authorization:** Response contract uses operator-based access control — aligned with Drosera's executor model
- **Math Safety:** All division and subtraction operations are guarded against zero and underflow

---

## 🛠️ Local Development
```bash
# Clone the repository
git clone https://github.com/JustSam-20/eigenlayer-operator-collapse.git
cd eigenlayer-operator-collapse

# Install dependencies
forge install

# Compile
forge build

# Run Drosera dryrun
drosera dryrun
```

---

## 📡 Built With

- [Drosera Network](https://drosera.io) — Blockchain monitoring infrastructure
- [Foundry](https://book.getfoundry.sh) — Smart contract development toolchain
- [Hoodi Testnet](https://hoodi.ethpandaops.io) — Ethereum testnet

---

*Built as part of the Drosera Network operator program.*
