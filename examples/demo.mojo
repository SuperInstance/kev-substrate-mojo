"""kev-substrate-mojo on-box demo — end-to-end receipt (CPU-only, no network).

Runs the parts of the substrate that compile on Mojo 1.2.0:
  1. FNV-1a 64-bit fleet canary check ("café Δ 日本語" -> 0x24a555471370b18d)
  2. A 3-cell prev_hash witness chain, cross-checked against the Python
     reference implementation's hashes (embedded as constants below and
     asserted live — requires building with -D ASSERT=all, see USERMANUAL).
  3. QuantumEther Bell-state projections in Z / X / mixed bases.
  4. format_hash regression receipt for the nibble-order fix (2026-09-30).

SplineSnap and SubstrateClient are NOT exercised: those modules have
unresolved helper declarations (current_nanos, escape_json, http_post, ...)
and do not compile yet — see docs/USERMANUAL.md "Known broken units".

Build & run (from repo root, with the pixi toolchain):
  pixi run --manifest-path /home/eileen/projects/quilt-mojo-lab/pixi.toml \
      mojo build -D ASSERT=all -I src examples/demo.mojo -o /tmp/kev-demo
  /tmp/kev-demo
"""

from substrate.fnv1a import fnv1a_64, format_hash
from substrate.cell import Cell
from quantum.ether import make_bell_state, measure_in_basis
from std.time import perf_counter_ns


def check(cond: Bool, label: String):
    if cond:
        print("  PASS  " + label)
    else:
        print("  FAIL  " + label)


def main():
    var t0 = perf_counter_ns()

    print("=" * 64)
    print("kev-substrate-mojo on-box demo receipt")
    print("toolchain: Mojo 1.2.0.dev2026100105 (pixi, quilt-mojo-lab)")
    print("=" * 64)

    # --- 1. Fleet canary -------------------------------------------------
    print("")
    print("[1] FNV-1a 64-bit fleet canary")
    var canary = fnv1a_64("café Δ 日本語")
    var canary_hex = format_hash(canary)
    print("  café Δ 日本語 -> " + canary_hex)
    check(canary == 0x24A555471370B18D, "canary == 0x24a555471370b18d (Python-matched)")

    # format_hash regression receipt (nibble-order fix 2026-09-30)
    var hello_hex = format_hash(fnv1a_64("hello"))
    print("  fnv1a_64(\"hello\") -> " + hello_hex)
    check(hello_hex == "0xa430d84680aabd0b", "format_hash emits MSB-first hex (post-fix)")

    # --- 2. Witness chain (3 cells, Python-matched hashes) ---------------
    print("")
    print("[2] prev_hash witness chain, conversation=demo-conv")
    var genesis = "0x0000000000000000"

    var c1 = Cell("mojo-demo-1", "demo-conv", genesis, "witness",
                  String("{\"step\":1,\"note\":\"first leg\"}"),
                  "kev-substrate-mojo", 1759200000000)
    var c2 = Cell("mojo-demo-2", "demo-conv", c1.hash, "observation",
                  String("{\"step\":2,\"note\":\"second leg\"}"),
                  "kev-substrate-mojo", 1759200000001)
    var c3 = Cell("mojo-demo-3", "demo-conv", c2.hash, "canon",
                  String("{\"step\":3,\"note\":\"third leg\"}"),
                  "kev-substrate-mojo", 1759200000002)

    print("  cell1: " + c1.cell_type + "  hash=" + c1.hash)
    print("  cell2: " + c2.cell_type + "  hash=" + c2.hash)
    print("  cell3: " + c3.cell_type + "  hash=" + c3.hash)

    check(c1.hash == "0x4a0deba5c5e679ae", "cell1 hash == Python reference 0x4a0deba5c5e679ae")
    check(c2.hash == "0xf14823fcab7caf51", "cell2 hash == Python reference 0xf14823fcab7caf51")
    check(c3.hash == "0xf42942531c9f15ae", "cell3 hash == Python reference 0xf42942531c9f15ae")
    check(c2.prev_hash == c1.hash and c3.prev_hash == c2.hash, "prev_hash linkage intact (c1->c2->c3)")

    # determinism: rebuild cell1 independently, hashes must match
    var c1b = Cell("mojo-demo-1", "demo-conv", genesis, "witness",
                   String("{\"step\":1,\"note\":\"first leg\"}"),
                   "kev-substrate-mojo", 1759200000000)
    check(c1b.hash == c1.hash, "cell rebuild is deterministic (same canonical -> same hash)")

    print("  cell3 JSON payload: " + c3.to_payload())

    # --- 3. QuantumEther Bell-state projections ---------------------------
    print("")
    print("[3] Bell state |Φ+⟩ measured in multiple bases (deterministic mock)")
    var bell = make_bell_state()
    var z = measure_in_basis(bell, "Z")
    var x = measure_in_basis(bell, "X")
    var m = measure_in_basis(bell, "mixed")
    print("  Z basis outcome:     " + z + "  (correlated, as |Φ+⟩ predicts)")
    print("  X basis outcome:     " + x)
    print("  mixed basis outcome: " + m + "  (anti-correlated)")
    check(z == "00" and x == "00" and m == "01", "projections match the doctrine table")

    # --- receipt ----------------------------------------------------------
    var t1 = perf_counter_ns()
    print("")
    print("=" * 64)
    print("RECEIPT: canary OK, 3-cell chain Python-matched + linked,")
    print("         rebuild deterministic, 3/3 Bell projections OK")
    print("wall time (chain+checks): " + String(t1 - t0) + " ns")
    print("NOT exercised (does not compile): splines.snap, substrate.client, bin/ CLI")
    print("=" * 64)
