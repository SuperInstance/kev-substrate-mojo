# USERMANUAL — kev-substrate-mojo

On-box verification: 2026-09-30, host `eileen` (WSL2, x86_64, RTX 4050 present but unused — see [Portability](#portability)).
Toolchain: **Mojo 1.2.0.dev2026100105 (f262223d)** via pixi (quilt-mojo-lab env).
Verdict in one line: **core substrate (FNV-1a, Cell chain, QuantumEther) compiles and matches the Python reference bit-for-bit; SplineSnap, SubstrateClient and the CLI do not compile yet (scaffolding gaps); the test suite has 2 real passes, 1 real failure, and 2 units that cannot build.**

---

## 1. What this is

`kev-substrate-mojo` is the Mojo port of [SuperInstance/kev-substrate](https://github.com/SuperInstance/kev-substrate): a substrate client that hashes decisions into `Cell` records, links them into a `prev_hash` witness chain (FNV-1a 64-bit, fleet canary `0x24a555471370b18d` for `"café Δ 日本語"`), and is structured so the same source can one day compile to CUDA / ROCm / Metal / Intel / CPU through Mojo's MLIR backends (CUDACLAW horizontal-abilities doctrine — many small cells, peer-to-peer, the chain is the coordinator).

Today, on this box, the port is **partially real**: the hash + chain + ether core is verified against Python; the HTTP client layer is still scaffold-only prose.

## 2. Fresh-clone quickstart

The `mojo.toml` in this repo **is aspirational** — no current tool consumes its `[project]`/`[[target]]` format, and there is no pixi project here. The proven toolchain lives one directory over:

```bash
# every command below uses this prefix; adjust paths for your box
cd /home/eileen/projects/kev-substrate-mojo
P="/home/eileen/.pixi/bin/pixi run --manifest-path /home/eileen/projects/quilt-mojo-lab/pixi.toml mojo"

# build + run the end-to-end demo (the receipt)
$P build -D ASSERT=all -I src examples/demo.mojo -o /tmp/kev-demo
/tmp/kev-demo
```

**`-D ASSERT=all` is not optional for tests.** Mojo 1.2.0 compiles `assert(...)` to a **no-op by default** (assertion mode is the `ASSERT` compile-time define; the default "safe" mode does not cover user asserts, and neither `-O 0` nor `-D MOJO_ENABLE_ASSERTIONS` turns them on). Verified empirically on this box:

```mojo
def main():
    assert False, "boom"   # exit code 0, prints past it, under plain `mojo build`
```

With `-D ASSERT=all` the same program aborts with a stack trace. Any test result from this repo built without the define is **vacuous**.

There is **no `mojo test` command** in Mojo 1.2.0 (CLI has: run, build, repl, debug, precompile, format, doc, demangle). Tests here are plain executables:

```bash
$P build -D ASSERT=all -I src tests/test_fnv1a.mojo -o /tmp/t_fnv1a && /tmp/t_fnv1a
```

`-I src` puts the source tree on the import path so `from substrate.cell import ...` resolves without packaging. (`mojo package src/substrate` cannot be used while `client.mojo` doesn't compile — packaging compiles every module in the directory.)

## 3. Architecture map — what's where, and what actually works

| Unit | File | Compiles? | Notes |
|---|---|---|---|
| FNV-1a 64-bit + format_hash | `src/substrate/fnv1a.mojo` | ✅ | Canary matches Python exactly. `format_hash` had a nibble-order bug — **fixed 2026-09-30** (see §6) |
| Cell + prev_hash chain | `src/substrate/cell.mojo` | ✅ | Cell hashes match Python byte-for-byte; `to_payload()` emits valid JSON |
| QuantumEther Bell mock | `src/quantum/ether.mojo` | ✅ | Deterministic Z/X/mixed projections; `Tuple[Int, Int]` return |
| SplineSnap | `src/splines/snap.mojo` | ❌ | Struct + classification logic is fine; `make_snap()` calls helpers that were never written |
| SubstrateClient | `src/substrate/client.mojo` | ❌ | Needs `http_post` etc.; Mojo's stdlib has **no HTTP client**, so this needs a design decision (see §5) |
| API types | `src/api/types.mojo` | ❌ missing | Listed in CANON.md / README / mojo.toml but **the file was never created** |
| CLI | `bin/kev-substrate.mojo` | ❌ | Imports client (broken) + uses never-written `get_args`/`get_arg_value`/`parse_question` |
| Tests | `tests/` | 1 of 3 builds | See §4 |
| Demo | `examples/demo.mojo` | ✅ | End-to-end receipt, CPU only, no network |

Dependency order: `fnv1a` → `cell`; `ether` standalone; `snap` and `client` are leaves that never got their helpers.

## 4. Test suite — verbatim results (2026-09-30)

### tests/test_fnv1a.mojo — builds, runs: 2 pass / 1 real failure

```text
✓ canary: café Δ 日本語 → 2640610520279855501        (= 0x24a555471370b18d, matches Python)
✓ empty string → 14695981039346656037               (= 0xcbf29ce484222325, offset basis)
At: tests/test_fnv1a.mojo:30:14: Assert Error: hello hash mismatch
Illegal instruction (exit 132)
```

The `hello` failure is **a wrong constant in the test, not a hash bug**: the repo expects `0x23f2f947b38ee5d9`, but FNV-1a-64("hello") is `0xa430d84680aabd0b` (Python cross-checked; matches no FNV variant — the constant appears fabricated). Left as-is deliberately: this was a never-run test and the failure is the receipt. If you fix it, use `0xa430d84680aabd0b`.

### tests/test_snap.mojo — does not compile

```text
src/splines/snap.mojo:75:44: error: use of unknown declaration 'current_nanos'
src/splines/snap.mojo:76:21: error: use of unknown declaration 'current_nanos'
src/splines/snap.mojo:63:33: error: use of unknown declaration 'escape_json'
src/splines/snap.mojo:65:37: error: use of unknown declaration 'escape_json'
```

### tests/test_substrate.mojo — does not compile

```text
src/substrate/client.mojo:123:30: error: use of unknown declaration 'escape_json'
src/substrate/client.mojo:126:24: error: use of unknown declaration 'http_post'
```

(More will surface once those resolve: `now_ms`, `extract_answers`, `extract_embedding_id`, plus `get_args`/`get_arg_value`/`parse_question` in `bin/`.) Note `test_substrate`'s `test_jev_search_returns_string` does **live HTTPS** against the quilt worker — even once the client compiles, that test should be mocked or gated before it belongs in CI.

### examples/demo.mojo — builds, runs: 8/8 checks PASS

```text
================================================================
kev-substrate-mojo on-box demo receipt
toolchain: Mojo 1.2.0.dev2026100105 (pixi, quilt-mojo-lab)
================================================================

[1] FNV-1a 64-bit fleet canary
  café Δ 日本語 -> 0x24a555471370b18d
  PASS  canary == 0x24a555471370b18d (Python-matched)
  fnv1a_64("hello") -> 0xa430d84680aabd0b
  PASS  format_hash emits MSB-first hex (post-fix)

[2] prev_hash witness chain, conversation=demo-conv
  cell1: witness  hash=0x4a0deba5c5e679ae
  cell2: observation  hash=0xf14823fcab7caf51
  cell3: canon  hash=0xf42942531c9f15ae
  PASS  cell1 hash == Python reference 0x4a0deba5c5e679ae
  PASS  cell2 hash == Python reference 0xf14823fcab7caf51
  PASS  cell3 hash == Python reference 0xf42942531c9f15ae
  PASS  prev_hash linkage intact (c1->c2->c3)
  PASS  cell rebuild is deterministic (same canonical -> same hash)
  cell3 JSON payload: {"id":"mojo-demo-3","type":"canon","state":{"step":3,"note":"third leg"},"source":"kev-substrate-mojo","conversation_id":"demo-conv","prev_hash":"0xf14823fcab7caf51","hash":"0xf42942531c9f15ae"}

[3] Bell state |Φ+⟩ measured in multiple bases (deterministic mock)
  Z basis outcome:     00  (correlated, as |Φ+⟩ predicts)
  X basis outcome:     00
  mixed basis outcome: 01  (anti-correlated)
  PASS  projections match the doctrine table

================================================================
RECEIPT: canary OK, 3-cell chain Python-matched + linked,
         rebuild deterministic, 3/3 Bell projections OK
wall time (chain+checks): 93617 ns
NOT exercised (does not compile): splines.snap, substrate.client, bin/ CLI
================================================================
```

The three cell hashes embedded in the demo were computed independently in Python and are asserted live at runtime — that is the cross-language contract of the interweave (see `docs/INTERWEAVE.md`), now actually proven instead of promised.

## 5. What's needed to finish the broken units

1. **`escape_json`** (used by snap + client): trivial — escape `\`, `"`, control chars. Pure string work, ~20 lines.
2. **`now_ms` / `current_nanos`**: `from std.time import perf_counter_ns` is wall-clock-ish enough, or use `monotonic()`. Note the import is `std.time`, not `time` (top-level `import time` fails on this toolchain).
3. **`http_post`** (+ `extract_answers` / `extract_embedding_id`): **the real gap.** Mojo's stdlib has no HTTP client. Options, in order of honesty: (a) shell out to `curl` via `subprocess`-equivalent, (b) Python interop (`from python import Python` → `urllib`), (c) implement a minimal HTTP/1.1 client over sockets if exposed. This is a design decision, not a mechanical fix, which is why it was left unbuilt here.
4. **`get_args` / `get_arg_value` / `parse_question`** for the CLI; note Mojo 1.2.0 has no `sys.argv` module import as used (`import sys` fails to resolve) — check `std.sys` / `std.os.arg` for the current API. The CLI also uses Python-style ternary (`x if c else y`) which is not Mojo syntax; rewrite as `if/else` blocks.
5. **`src/api/types.mojo`**: file simply doesn't exist despite three docs referencing it. Either write it (Noul / Choice / Score / SystemOneRequest) or scrub the references.

## 6. Mojo 1.2.0 drift fixes applied (mechanical), and the two content bugs found

Mechanical drift (the scaffolding was written pre-1.0 and never compiled; originals preserved as `*.orig-20260930`):

- `fn` → `def` everywhere (`fn` removed in 1.2.0)
- `let` → `var` (`let` removed)
- `__init__(inout self, ...)` → `__init__(out self, ...)`; mutators → `mut self`
- tuple type `(Int, Int)` → `Tuple[Int, Int]`; element access `result.0` → `result[0]`
- `String` positional indexing `s[i]` → `s[byte=i]`
- `len(string)` → `string.byte_length()`
- missing import: `cell.mojo` used `format_hash` without importing it
- definite-init: `Cell.__init__` must initialize `self.hash` before calling `self._compute_hash()`

Content bugs found by on-box verification (these are **not** language drift):

1. **`format_hash` emitted nibbles reversed** (least-significant first). Proof: FNV-1a-64("hello") printed `0xb0dbaa08648d034a` instead of `0xa430d84680aabd0b`; the cell hash `0xd62b2a1806ed56d4` printed as `0x4d65de6081a2b26d` (exact nibble reversal). The canary test hid this because it compared UInt64 integers and printed decimal. **Fixed** in `fnv1a.mojo` (MSB-first loop), verified against Python.
2. **`test_hello`'s expected constant is wrong** (`0x23f2f947b38ee5d9` — matches no FNV variant). Left failing on purpose; correct value is `0xa430d84680aabd0b`.
3. Cosmetic: the fleet canary is written with a decorative leading zero (`0x024a555471370b18d`, 17 hex digits). Numerically identical to the true 16-digit value — Python doesn't mind; keep it in mind for strict parsers in other fleet languages.

## 7. Portability

**GPU / vendor-universal verdict: nothing here touches a GPU.** Honest specifics:

- No file in `src/` imports Mojo's `gpu` package, `layout`, `tensor`, `Target`/`compiler` kernel machinery, or anything vendor-specific. The "GPU-native, vendor-universal" claim in CANON.md/README is an **architectural aspiration encoded in prose**, not code. There are zero kernels to run on the RTX 4050, so no GPU verification was possible or needed — the entire substrate currently runs on CPU in micro- or milliseconds (demo: <0.1 ms of work).
- The `gpu = []` feature flag in `mojo.toml` guards a feature that doesn't exist yet.
- **Metal/Apple:** nothing Metal-specific exists here; also untestable on this WSL2 box. The ether.mojo docstring's "compiles to CUDA/ROCm/Metal/CPU" describes what Mojo's MLIR pipeline *can* do with GPU code, not what this repo contains.
- **When GPU code arrives**, the on-box path would be: `mojo build` with NVIDIA target from the same pixi env (CUDA runtime via conda), short (<2 min) smoke kernels on the RTX 4050, `mojo debug`/profiler for receipts. None of that is exercised by this manual because there is nothing to exercise.
- The Python↔Mojo interweave contract (same HTTP API, same FNV-1a canary, same chain discipline) **is** real and verified for the hash/chain layer — that part is portable to any box with the pixi env.

## 8. Troubleshooting — things this verification actually hit

| Symptom | Cause / fix |
|---|---|
| `'fn' has been removed; use 'def' instead` | 1.2.0 removed `fn`. Mechanical replace. |
| `use of unknown declaration 'let'` | `let` removed; use `var` or plain assignment. |
| `expected ')' in argument list` pointing at `inout self` | `inout` removed: `out self` in `__init__`, `mut self` for mutators. |
| `expected a type, found a tuple value` | `(Int, Int)` isn't a type; write `Tuple[Int, Int]`. |
| `String does not support direct positional indexing like s[i]` | Use `s[byte=i]` / `s[codepoint=i]` / `s[grapheme=i]` — UTF-8 ambiguity is a compile error now. |
| ``len(String/StringSlice)` is not supported` | Use `s.byte_length()` (or `len(s.codepoints())` / `len(s.graphemes())`). |
| `unable to locate module 'time'` | It's `from std.time import perf_counter_ns` — stdlib modules live under `std.`. |
| Test passes but shouldn't | You forgot `-D ASSERT=all`; default builds compile `assert` to a no-op. |
| `use of uninitialized value 'self.hash'` | Definite-init: set every field (even to `String("")`) before calling methods on `self` in `__init__`. |
| `import sys` fails | No such module in 1.2.0; look under `std.sys` / `std.os`. |
| Hashes look "scrambled" vs Python | Check for the format_hash nibble-order bug (§6.1) before doubting the hash itself. |

## 9. Repo hygiene notes

- Pre-fix originals of every touched file are preserved as `*.orig-20260930` (archive-by-rename policy; nothing was deleted).
- `mojo.toml` is aspirational (unconsumed by any toolchain); the real build is the pixi invocation in §2. Either evolve `mojo.toml` into a real pixi `[workspace]` project or say so in CANON.md.
- CANON.md status checkboxes ("Mojo toolchain access", "Compile + run tests", "FNV-1a matches Python canary") are now genuinely checkable — this manual is the receipt.
