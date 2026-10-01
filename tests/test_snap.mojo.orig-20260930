"""SplineSnap tests — duck/batten classification."""
from splines.snap import SplineSnap, make_snap


fn test_duck_at_high_confidence():
    """Confidence >= 0.7 should classify as duck."""
    let snap = make_snap("Clear question?", "noul", "yes", 0.85)
    assert snap.is_duck() == True
    assert snap.is_batten() == False
    assert snap.classification() == "duck"
    print("✓ high-confidence snap → duck")


fn test_batten_at_low_confidence():
    """Confidence < 0.7 should classify as batten."""
    let snap = make_snap("Ambiguous?", "choice", "billing", 0.5)
    assert snap.is_duck() == False
    assert snap.is_batten() == True
    assert snap.classification() == "batten"
    print("✓ low-confidence snap → batten")


fn test_skip_at_very_high_confidence():
    """Confidence >= 0.95 should classify as skip (no snap needed)."""
    let snap = make_snap("Trivially true?", "noul", "yes", 0.98)
    assert snap.classification() == "skip"
    print("✓ very-high-confidence → skip")


fn test_to_dict_renders_json():
    """to_dict should return a JSON-string with all fields."""
    let snap = make_snap("Test?", "noul", "yes", 0.85)
    let d = snap.to_dict()
    assert "snap_id" in d
    assert "question" in d
    assert "confidence" in d
    print("✓ snap.to_dict() → " + String(len(d)) + " chars")


fn main():
    test_duck_at_high_confidence()
    test_batten_at_low_confidence()
    test_skip_at_very_high_confidence()
    test_to_dict_renders_json()
    print("All SplineSnap tests passed.")
