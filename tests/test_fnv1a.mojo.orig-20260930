"""FNV-1a 64-bit canary tests.

The fleet pin: "café Δ 日本語" → 0x024a555471370b18d
Must match exactly across Python, Mojo, Rust, Go, and the substrate worker.
"""
from substrate.fnv1a import fnv1a_64


fn test_canary():
    """The canonical canary test."""
    let h = fnv1a_64("café Δ 日本語")
    let expected: UInt64 = 0x024a555471370b18d
    assert h == expected, "FNV-1a canary mismatch: " + String(h) + " != " + String(expected)
    print("✓ canary: café Δ 日本語 → " + String(h))


fn test_empty_string():
    """FNV-1a of empty string should be the offset basis."""
    let h = fnv1a_64("")
    let expected: UInt64 = 0xcbf29ce484222325  # FNV offset basis for 64-bit
    assert h == expected, "Empty string should be offset basis"
    print("✓ empty string → " + String(h))


fn test_hello():
    """Sanity check: 'hello' should give a known value."""
    let h = fnv1a_64("hello")
    # The expected hash for "hello" in FNV-1a 64-bit
    let expected: UInt64 = 0x23f2f947b38ee5d9
    assert h == expected, "hello hash mismatch"
    print("✓ hello → " + String(h))


fn main():
    test_canary()
    test_empty_string()
    test_hello()
    print("All FNV-1a tests passed.")
