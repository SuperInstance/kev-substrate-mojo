"""SplineSnap — canonical anchor on an analogue trajectory.

Per the shipwright doctrine:
- Duck: high-confidence (≥ 0.7) precision plug in a known gap
- Batten: low-confidence (< 0.7) spacer that organizes, doesn't fill
- Negative space: unmeasured region between snaps, held by substrate

The quantum_basis field lets you project the snap into different measurement
bases (computational, Hadamard, mixed) — see quantum/ether.mojo.
"""


struct SplineSnap:
    var snap_id: String
    var t: Float64          # time coordinate (t-minus style)
    var position_x: Float64 # position in question space
    var position_y: Float64 # confidence is y, or second dim
    var question: String
    var answer_type: String # "noul" | "choice" | "score"
    var answer_value: String
    var confidence: Float64
    var basis: String       # quantum basis
    var extra_dims: String  # JSON dict (duck/batten, etc.)
    
    fn __init__(inout self, snap_id: String, t: Float64, position_x: Float64, position_y: Float64,
                question: String, answer_type: String, answer_value: String,
                confidence: Float64, basis: String = "|+⟩/|−⟩",
                extra_dims: String = "{}"):
        self.snap_id = snap_id
        self.t = t
        self.position_x = position_x
        self.position_y = position_y
        self.question = question
        self.answer_type = answer_type
        self.answer_value = answer_value
        self.confidence = confidence
        self.basis = basis
        self.extra_dims = extra_dims
    
    fn is_duck(self) -> Bool:
        """True if confidence is high enough to be a precision duck (anchor)."""
        return self.confidence >= 0.7
    
    fn is_batten(self) -> Bool:
        """True if confidence is low (organizes but doesn't fill)."""
        return self.confidence < 0.7
    
    fn classification(self) -> String:
        """Return 'duck', 'batten', or 'skip'."""
        if self.confidence >= 0.95:
            return "skip"  # trust the substrate, no snap needed
        elif self.confidence >= 0.7:
            return "duck"
        else:
            return "batten"
    
    fn to_dict(self) -> String:
        """Render as a JSON dict (for embedding in cell state)."""
        return String("{") + \
            "\"snap_id\":\"" + String(self.snap_id) + "\"," + \
            "\"t\":" + String(self.t) + "," + \
            "\"position\":[" + String(self.position_x) + "," + String(self.position_y) + "]," + \
            "\"question\":\"" + escape_json(self.question) + "\"," + \
            "\"answer_type\":\"" + String(self.answer_type) + "\"," + \
            "\"answer_value\":\"" + escape_json(self.answer_value) + "\"," + \
            "\"confidence\":" + String(self.confidence) + "," + \
            "\"basis\":\"" + String(self.basis) + "\"," + \
            "\"classification\":\"" + self.classification() + "\"," + \
            "\"extra_dims\":" + String(self.extra_dims) + \
            "}"


fn make_snap(question: String, answer_type: String, answer_value: String, confidence: Float64) -> SplineSnap:
    """Convenience: make a snap with auto-generated id and current time."""
    let snap_id = String("snap-") + String(current_nanos())
    let t = Float64(current_nanos()) / 1e9
    let pos_x = Float64(hash(question) % 1000) / 1000.0
    let pos_y = confidence
    let extra_dims = String("{\"classification\":\"") + classify(confidence) + "\"}"
    return SplineSnap(snap_id, t, pos_x, pos_y, question, answer_type, answer_value, confidence,
                     "|+⟩/|−⟩", extra_dims)


fn classify(confidence: Float64) -> String:
    if confidence >= 0.95:
        return "skip"
    elif confidence >= 0.7:
        return "duck"
    else:
        return "batten"
