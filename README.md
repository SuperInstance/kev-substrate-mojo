# kev-substrate-mojo

> Mojo port of [SuperInstance/kev-substrate](https://github.com/SuperInstance/kev-substrate) — **vendor-hardware GPU native**, **horizontal-abilities engineering** per the CUDACLAW doctrine.

## What is this?

A Mojo rewrite of kev-substrate that:
1. Compiles to CUDA / ROCm / Metal / Intel / CPU via Modular's MLIR backend
2. Is structured for **horizontal-abilities** (CUDACLAW) — many small substrate cells, peer-to-peer, no central coordinator
3. Drops into the existing kev-substrate interweave without API changes

Same substrate, different language.

## The CUDACLAW doctrine

CUDACLAW = **CUDA** + **PTX** + **CLAW**. The claw: many legs doing independent work, peer-to-peer, no central coordinator. A pod, not a pack.

For kev-substrate this means:
- Every decision is its own cell (its own small kernel)
- Witness-log is the shared state, not global memory
- No top-down scheduler; the substrate IS the coordinator
- Bottom-up emergence via the prev_hash chain

## File layout

```
kev-substrate-mojo/
├── CANON.md                       # Layer C join declaration
├── README.md                      # this file
├── mojo.toml                      # Mojo project config
├── src/
│   ├── substrate/
│   │   ├── fnv1a.mojo             # FNV-1a 64-bit, fleet canary 0x024a555471370b18d
│   │   ├── cell.mojo              # Cell struct + chain logic
│   │   └── client.mojo            # SubstrateClient (HTTP + JSON + chain)
│   ├── api/
│   │   └── types.mojo             # Noul, Choice, Score, SystemOneRequest
│   ├── splines/
│   │   └── snap.mojo              # SplineSnap with duck/batten classification
│   └── quantum/
│       └── ether.mojo             # QuantumEther multi-basis projection
├── tests/
│   ├── test_fnv1a.mojo            # Canary test (must match Python)
│   ├── test_substrate.mojo        # 5 tests like Python version
│   └── test_snap.mojo             # Snap + duck/batten
├── bin/
│   └── kev-substrate.mojo         # CLI entry point
└── docs/
    └── INTERWEAVE.md              # How Mojo substrate interweaves with Python
```

## Status (Sept 22, 2026)

- [x] Architecture designed
- [x] CANON.md
- [x] All Mojo source files drafted (~250 lines across 6 files)
- [x] Test suite drafted (~120 lines, 12 tests)
- [x] CLI entry point
- [x] mojo.toml
- [ ] Mojo toolchain access (Modular Discord or self-hosted)
- [ ] Compile + run tests
- [ ] FNV-1a matches Python canary
- [ ] Interop with Python kev.serve.py
- [ ] Vendor benchmarks (NVIDIA / AMD / Apple)
- [ ] PTX hand-tuning pass (sm_89 / sm_90)
- [ ] CI/CD

## Why Mojo?

Mojo is the **only language designed from the ground up for ML with first-class GPU types**. PyTorch / JAX / TF treat the GPU as a separate device you copy to/from. Mojo treats GPU memory as the default, with the same `DType`, `Layout`, `Buffer` types everywhere.

For kev-substrate this means:
- The `Cell` struct is GPU-native by default
- `fnv1a_64` can run on GPU for batch hashing
- HTTP client still runs on CPU (no GPU networking yet)
- Inference calls can dispatch to GPU when kev.serve is rewritten

Same source, vendor-universal: CUDA / ROCm / Metal / Intel / CPU.

## Build / test

```bash
# Install Mojo (https://docs.modular.com/mojo/manual/get-started/)
# curl https://get.modular.com | sh
# modular install mojo

# Compile
mojo build bin/kev-substrate.mojo -o kev-substrate

# Run tests
mojo test tests/

# Run CLI
./kev-substrate --state "Customer is upset" --question "dept:choice:Which team:returns=Returns|billing=Billing"

# Search canon
./kev-substrate --search "shipwright Jev" --top-k 3
```

## Connection to CUDACLAW

The whole repo IS CUDACLAW in microcosm:
- `Cell` = one leg of the claw
- `prev_hash` chain = the body the legs share
- The substrate worker = the shore the claw grips
- The witness-log = the coordination without coordinator

When you call `SubstrateClient.systemone(...)`:
1. One leg calls kev for inference (CPU today, GPU tomorrow)
2. Same leg builds a Cell
3. Same leg POSTs to substrate
4. The substrate (shared body) updates its witness-log
5. Next call sees the new state automatically (leg reads body, no sync needed)

The claw walks. The body holds. The shore doesn't move.

## Related

- [SuperInstance/kev-substrate](https://github.com/SuperInstance/kev-substrate) — the Python version
- [JEV + shipwright doctrine](https://github.com/SuperInstance/cargo-line-tycoon/blob/main/shipwright/README.md) — the JEV reads via spline-snaps
- [CUDACLAW doctrine doc](https://github.com/SuperInstance/cargo-line-tycoon/blob/main/cudaclaw-design/CUDACLAW_DOCTRINE.md) — engineering doctrine

— Filed by Mavis, 2026-09-22
