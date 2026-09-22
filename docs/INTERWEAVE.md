# Interweave: Mojo Substrate ↔ Python kev.serve

## The interweave pattern

Same substrate, two languages. The Mojo client and the Python server share:
- The HTTP API surface (`/v1/systemone`, `/api/cell`, `/api/jev/search`)
- The FNV-1a canary hash
- The substrate canon (Cloudflare Vectorize)
- The prev_hash chain discipline

Different layers:
- **Python kev.serve.py**: inference (PyTorch + transformers)
- **Mojo SubstrateClient**: client + cell chain (CUDA-native soon)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Substrate Worker                        │
│                  (quilt-distributed CF Worker)                  │
│                                                                 │
│   POST /api/cell        ← receives Cell records                 │
│   POST /api/jev/search  ← receives JEV queries                  │
│   GET  /api/cell/:id    ← fetches canonical cells               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ▲        ▲
                              │        │
                              │ HTTPS  │ HTTPS
                              │        │
        ┌─────────────────────┘        └────────────────────────┐
        │                                                     │
┌───────────────────────┐                       ┌──────────────────────────┐
│   Python kev.serve    │                       │   Mojo SubstrateClient   │
│                       │                       │                          │
│  POST /v1/systemone   │  ←─────────────────   │  client.systemone(...)   │
│  Returns              │     HTTP              │  records Cell            │
│  {answers, ...}       │ ──────────────────→   │  posts to substrate      │
│                       │                       │                          │
│  PyTorch + Qwen3.5    │                       │  CUDA-native soon        │
│                       │                       │                          │
└───────────────────────┘                       └──────────────────────────┘
```

Today the Mojo client calls the Python server. Tomorrow we can replace the Python server with a Mojo server, and the client doesn't change.

## The canary contract

Both languages must produce the same FNV-1a 64-bit hash for `café Δ 日本語`:

```
0x024a555471370b18d
```

If the hashes ever differ, the chain breaks. The substrate worker validates this on every Cell record.

Test in Python:
```python
from kev.substrate import fnv1a_64
assert fnv1a_64("café Δ 日本語") == 0x024a555471370b18d
```

Test in Mojo:
```mojo
from substrate.fnv1a import fnv1a_64
assert fnv1a_64("café Δ 日本語") == 0x024a555471370b18d
```

## Chain continuation

When the Mojo client makes a call, it:
1. Reads its local `last_hash` (initialized to genesis `0x0000000000000000`)
2. Sends the request to kev
3. Builds a `Cell` with the response + `prev_hash = last_hash`
4. POSTs to substrate
5. Updates `last_hash` to the new cell's hash

Same algorithm as the Python client. Same chain semantics.

If you alternate Python and Mojo calls in the same conversation, the chain works:
- Python call #1 → hash A
- Mojo call #2 → hash B (prev=A)
- Python call #3 → hash C (prev=B)

All three languages share the same `last_hash` discipline.

## When to use Mojo vs Python

**Use Mojo when**:
- You're building a CLI / TUI / Webnative surface and want GPU-native client logic
- You're running on Apple Silicon / AMD GPU / Intel Arc (no PyTorch+CUDA)
- You want compile-time guarantees about the substrate interface
- You're porting to a new GPU vendor (Mojo handles the backend)

**Use Python when**:
- You're running inference (Python's PyTorch ecosystem is more mature)
- You're doing research/training (Python is faster to iterate)
- You need libraries that don't exist in Mojo yet

The two are complementary, not competitive. CUDACLAW doesn't pick a leg — all legs work.

## Roadmap

1. ✅ Mojo substrate client (HTTP + chain)
2. ✅ Mojo FNV-1a canary
3. ✅ Mojo Cell + SplineSnap
4. 🔄 Wire to Python kev.serve.py over HTTP (works today)
5. ⏳ Mojo inference core (replace PyTorch in kev.model)
6. ⏳ PTX hand-tuning (sm_89, sm_90)
7. ⏳ Vendor benchmarks (RTX 4090, M2 Max, MI300X)
8. ⏳ Mojo Webnative surface (Rust/WASM bridge)

## The horizontal-abilities vision

When the Mojo port is complete, you can:
- Run kev-substrate on NVIDIA, AMD, Apple, Intel from the same source
- Spawn many Mojo clients in parallel, each one a leg of the claw
- Each leg reads/writes substrate without a coordinator
- The substrate worker becomes the only sync point (and it's idempotent)

That's CUDACLAW: many legs, peer-to-peer, the shore holds them all.
