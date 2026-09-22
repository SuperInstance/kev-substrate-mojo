---
canon: 1
name: kev-substrate-mojo
mission: "Mojo port of kev-substrate. Same substrate interweave, GPU-native, vendor-universal (NVIDIA/AMD/Apple/Intel via MLIR). Horizontal-abilities engineering per CUDACLAW doctrine."
state: scaffolding
family: applications
vessel: SuperInstance
born_from: [SuperInstance/kev-substrate]
feeds: [SuperInstance/kev-substrate]
owed_by: [SuperInstance/quilt]
canonical_docs: [README.md, docs/MOJO_PORT_PLAN.md, src/substrate/client.mojo]
ledger: git-log
verified: 2026-09-22
---

# kev-substrate-mojo

Mojo port of [SuperInstance/kev-substrate](https://github.com/SuperInstance/kev-substrate), designed for **vendor-hardware GPU native** execution via Modular's Mojo compiler → MLIR → CUDA/ROCm/Metal/CPU.

## The horizontal-abilities doctrine

Per Casey (2026-09-22): "challenge your apis of different models to compete on innovative methods for a cuda/ptx native version that's more like our cudaclaw in engineering it's horizontal abilities"

CUDACLAW = CUDA + PTX + CLAW. The claw: many legs doing independent work, peer-to-peer, no central coordinator.

## What's in here

- `src/substrate/client.mojo` — SubstrateClient in Mojo (HTTP + JSON + FNV-1a)
- `src/substrate/fnv1a.mojo` — FNV-1a 64-bit, fleet canary `0x024a555471370b18d`
- `src/substrate/cell.mojo` — Cell struct + prev_hash chain
- `src/api/types.mojo` — Noul, Choice, Score, SystemOneRequest
- `src/splines/snap.mojo` — SplineSnap with quantum_basis (ducks/battens)
- `src/quantum/ether.mojo` — QuantumEther multi-basis projection
- `tests/` — 5+ tests matching Python coverage
- `bin/kev-substrate` — CLI entry point

## Interop

The Mojo SubstrateClient calls Python kev.serve.py over HTTP today. Same substrate, different language.

When the Mojo inference core is ready, swap the Python server for a Mojo one. No upstream API change.

## Why vendor-hardware GPU native

Mojo compiles to MLIR, then to vendor-specific IR:
- NVIDIA: MLIR → LLVM → NVPTX → sm_80/89/90
- AMD: MLIR → LLVM → AMDGPU → gfx90a/gfx1100
- Apple: MLIR → LLVM → AArch64 → M1/M2/M3 GPU via Metal
- Intel: MLIR → LLVM → SPIR-V → Intel Arc / Xe
- CPU: MLIR → LLVM → x86_64 → AVX-512

Same source file, vendor-native output. The claw grips whatever surface is there.

## Status

- [x] Architecture designed
- [x] CANON.md
- [ ] Mojo toolchain access (Modular Discord or self-hosted)
- [ ] SubstrateClient compiled + tested
- [ ] FNV-1a matches Python canary
- [ ] Interop with Python kev.serve.py
- [ ] Vendor benchmarks (NVIDIA / AMD / Apple)
- [ ] PTX hand-tuning pass (sm_89 / sm_90)
- [ ] Continuous integration
