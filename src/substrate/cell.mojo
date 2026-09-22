"""Cell — one substrate cell with prev_hash chain.

A Cell is the irreducible unit of the substrate. It carries:
- An ID (canonical)
- A prev_hash (chain link)
- A hash (this cell's content hash)
- A type ('canon', 'witness', 'observation', etc.)
- A state (JSON payload)
- A timestamp

The chain forms a witness-log: every cell knows what came before it.
"""
from .fnv1a import fnv1a_64


struct Cell:
    var id: String
    var conversation_id: String
    var prev_hash: String  # hex
    var hash: String       # hex
    var cell_type: String
    var state: String      # JSON
    var source: String
    var timestamp_ms: Int64
    
    fn __init__(inout self, id: String, conversation_id: String, prev_hash: String,
                cell_type: String, state: String, source: String, timestamp_ms: Int64):
        self.id = id
        self.conversation_id = conversation_id
        self.prev_hash = prev_hash
        self.cell_type = cell_type
        self.state = state
        self.source = source
        self.timestamp_ms = timestamp_ms
        # Compute hash from canonical content
        self.hash = self._compute_hash()
    
    fn _compute_hash(self) -> String:
        """Compute the cell's hash from its canonical content (FNV-1a 64-bit)."""
        let canonical = String(self.id) + "|" + String(self.conversation_id) + "|" + \
                       String(self.prev_hash) + "|" + String(self.cell_type) + "|" + \
                       String(self.state) + "|" + String(self.source) + "|" + \
                       String(self.timestamp_ms)
        let h = fnv1a_64(canonical)
        # Format as '0x' + 16 hex digits (matches fleet style)
        return format_hash(h)
    
    fn to_payload(self) -> String:
        """Render as JSON for HTTP POST to /api/cell."""
        return String("{") + \
               "\"id\":\"" + String(self.id) + "\"," + \
               "\"type\":\"" + String(self.cell_type) + "\"," + \
               "\"state\":" + String(self.state) + "," + \
               "\"source\":\"" + String(self.source) + "\"," + \
               "\"conversation_id\":\"" + String(self.conversation_id) + "\"," + \
               "\"prev_hash\":\"" + String(self.prev_hash) + "\"," + \
               "\"hash\":\"" + String(self.hash) + "\"" + \
               "}"
