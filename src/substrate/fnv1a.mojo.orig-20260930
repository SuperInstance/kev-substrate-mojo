"""FNV-1a 64-bit hash. Matches the fleet canary 0x024a555471370b18d for "café Δ 日本語".

The FNV-1a algorithm:
1. Start with FNV offset basis (for 64-bit: 0xcbf29ce484222325)
2. For each byte: XOR into hash, then multiply by FNV prime (for 64-bit: 0x100000001b3)
3. Done.

This must produce identical output to Python's reference implementation.
"""

@always_inline
fn fnv1a_64(data: String) -> UInt64:
    """Compute FNV-1a 64-bit hash of a string."""
    var h: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x100000001b3
    
    for byte in data.as_bytes():
        h = h ^ UInt64(byte)
        h = h * prime
    
    return h


@always_inline
fn fnv1a_64_bytes(data: List[UInt8]) -> UInt64:
    """Compute FNV-1a 64-bit hash of a byte list (UTF-8 encoded)."""
    var h: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x100000001b3
    
    for byte in data:
        h = h ^ UInt64(byte)
        h = h * prime
    
    return h


fn format_hash(h: UInt64) -> String:
    """Format a 64-bit hash as '0x' + 16 hex digits (matches fleet canary style)."""
    let hex_chars = "0123456789abcdef"
    var result = String("0x")
    var v = h
    for _ in range(16):
        let digit = Int(v & 0xf)
        result += hex_chars[digit]
        v = v >> 4
    return result
