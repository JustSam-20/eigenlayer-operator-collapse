# 🛡️ EigenLayer Operator Collapse Detector

> A production-grade Drosera Network trap deployed on Hoodi Testnet that detects EigenLayer operator collapse through **temporal delta analysis** across 5 blocks — catching coordinated failures as they develop, not just after they happen.

---

## 🔍 Overview

EigenLayer operators secure billions in restaked ETH. A sudden operator collapse — whether from coordinated withdrawals, slashing events, or mass undelegation — can cascade into protocol-wide insolvency within minutes.

This trap uses **Drosera's historical sample model** (`block_sample_size = 5`) to compare current block data against a 5-block historical window. It detects **change over time**, not just absolute thresholds — making it a genuine collapse detector, not a simple alarm.

The trap fires only when **two or more vectors trigger simultaneously**, eliminating false positives while ensuring no coordinated attack goes undetected.

---

## ⚡ Attack Vectors Monitored

| Vector | Method | Condition | Threshold |
|--------|--------|-----------|-----------|
| 1 — Stake Collapse | **Delta** (data[0] vs data[4]) | Stake dropped vs 5 blocks ago | > 20% drop across window |
| 2 — Slashing Signal | **Absolute** (binary flag) | Slashing flag activated on-chain | Any slashing event |
| 3 — Undelegation Spike | **Delta** (data[0] vs data[4]) | Undelegations grew vs 5 blocks ago | > 50% growth across window |

**Why deltas matter:**
- A stake of 700 ETH means nothing alone — but 1000 ETH → 700 ETH across 5 blocks is a collapse signal
- Undelegations of 200 ETH means nothing alone — but 50 ETH → 200 ETH across 5 blocks is a bank run signal
- Deltas catch coordinated attacks as they develop, not after they complete

**Response logic:** Fires if **≥ 2 vectors** trigger simultaneously.

---

## 🏗️ Architecture
```
eigenlayer-operator-collapse/
├── src/
│   ├── EigenLayerOperatorCollapseTrap.sol      # Temporal delta monitor
│   └── EigenLayerOperatorCollapseResponse.sol  # Authorized response emitter
├── script/
│   └── Deploy.sol                              # Deploys MockEigenLayer + Response
├── drosera.toml                                # Drosera trap configuration
└── README.md
```

### How It Works

1. **Every block**, Drosera calls `collect()` — reads 5 storage slots from MockEigenLayer
2. Drosera accumulates 5 blocks of snapshots: `data[0]` (current) → `data[4]` (oldest)
3. `shouldRespond()` computes **deltas** between `data[0]` and `data[data.length - 1]`
4. Vector 1: Is current stake < 80% of stake 5 blocks ago?
5. Vector 2: Is slashing flag active? (absolute — binary)
6. Vector 3: Are current undelegations > 150% of undelegations 5 blocks ago?
7. If ≥ 2 vectors breach → response fires with full context

---

## 📋 Contract Addresses (Hoodi Testnet)

| Contract | Address |
|----------|---------|
| 🪤 Trap | [`0x383EfD31D1383E8cf7aBeD267139d0829F64208c`](https://hoodi.etherscan.io/address/0x383EfD31D1383E8cf7aBeD267139d0829F64208c) |
| ⚡ Response | [`0xBB43C0E7790417f539581C95479FBf5E3A12312F`](https://hoodi.etherscan.io/address/0xBB43C0E7790417f539581C95479FBf5E3A12312F) |
| 🎭 MockEigenLayer | [`0xdfDE8aaACc1dCE720301aECA253A28A88B46719a`](https://hoodi.etherscan.io/address/0xdfDE8aaACc1dCE720301aECA253A28A88B46719a) |

---

## 🔧 Drosera Configuration

| Parameter | Value | Reason |
|-----------|-------|--------|
| Network | Hoodi Testnet | — |
| Chain ID | 560048 | — |
| Block Sample Size | **5** | Enables 5-block delta analysis |
| Cooldown Period | 33 blocks | Prevents response spam |
| Min Operators | 1 | — |
| Max Operators | 3 | — |
| Private Trap | false | Open to all Hoodi operators |

---

## 🧪 Testing the Trap

The `MockEigenLayer` contract exposes helper functions to simulate attack conditions:
```bash
# Simulate a stake collapse (triggers Vector 1)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateStakeDrain()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Simulate a slashing event (triggers Vector 2)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateSlashing()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Simulate an undelegation spike (triggers Vector 3)
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "simulateWithdrawalSpike()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY

# Reset all conditions to healthy state
cast send 0xdfDE8aaACc1dCE720301aECA253A28A88B46719a "resetState()" \
  --rpc-url https://rpc.hoodi.ethpandaops.io/ --private-key $PRIVATE_KEY
```

To trigger the response, run **any two** simulate commands then wait 5 blocks for the delta to register.

---

## 🔐 Security Design

- **Stateless Trap:** No storage variables — safe against Drosera's shadow-fork redeployment model
- **Temporal Delta Analysis:** Compares `data[0]` vs `data[4]` — detects change over time, not just state
- **Data Length Guard:** `shouldRespond()` validates input before decoding — prevents revert on empty blobs
- **onlyOperator Authorization:** Response contract uses operator-based access control — aligned with Drosera's executor model
- **Math Safety:** All division and subtraction operations are guarded against zero and underflow
- **Fallback Threshold:** If no prior undelegation history exists, falls back to absolute threshold check

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
