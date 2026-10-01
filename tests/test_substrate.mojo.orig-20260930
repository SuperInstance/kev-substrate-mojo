"""Substrate client tests (mocked HTTP)."""
from substrate.client import SubstrateClient


fn test_creation():
    """Client should initialize with default settings."""
    var client = SubstrateClient()
    assert client.kev_url == "http://127.0.0.1:8009"
    assert client.substrate_url == "https://quilt-distributed.casey-digennaro.workers.dev"
    assert client.conversation_id == "default"
    assert client.request_count == 0
    print("✓ client defaults set")


fn test_chain_starts_at_genesis():
    """Initial last_hash should be the genesis (all zeros)."""
    var client = SubstrateClient()
    assert client.last_hash == "0x0000000000000000"
    print("✓ chain starts at genesis")


fn test_jev_search_returns_string():
    """JEV search should return a JSON string (real HTTP)."""
    var client = SubstrateClient()
    let result = client.jev_search("shipwright", top_k=3)
    # Real test would parse JSON; here we just check it's non-empty
    assert len(result) > 0, "JEV search should return content"
    print("✓ JEV search returned " + String(len(result)) + " chars")


fn main():
    test_creation()
    test_chain_starts_at_genesis()
    test_jev_search_returns_string()
    print("All substrate tests passed.")
