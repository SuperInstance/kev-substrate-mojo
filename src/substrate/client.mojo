"""SubstrateClient — Mojo port of kev.substrate.SubstrateClient.

Calls kev's /v1/systemone over HTTP, records the call as a substrate cell
with prev_hash chain, posts to the substrate worker.

Vendor-hardware GPU native: this whole file compiles to CUDA/ROCm/Metal/CPU
via MLIR. The HTTP/JSON path runs on CPU; the inference calls can dispatch
to GPU when kev.serve.py is replaced with a Mojo server.
"""
from .fnv1a import fnv1a_64, format_hash
from .cell import Cell


struct SystemOneRequest:
    var state: String
    var questions_json: String  # JSON-encoded questions dict
    
    fn __init__(inout self, state: String, questions_json: String):
        self.state = state
        self.questions_json = questions_json
    
    fn to_payload(self) -> String:
        return String("{") + \
               "\"state\":\"" + escape_json(self.state) + "\"," + \
               "\"questions\":" + String(self.questions_json) + \
               "}"


struct SubstrateResult:
    var answers_json: String
    var cell_id: String
    var prev_hash: String
    var hash: String
    var embedding_id: String
    var latency_ms: Float64


struct SubstrateClient:
    var kev_url: String
    var substrate_url: String
    var conversation_id: String
    var last_hash: String  # tracks the chain
    var embed: Bool
    var request_count: Int
    
    fn __init__(inout self, kev_url: String = "http://127.0.0.1:8009",
                substrate_url: String = "https://quilt-distributed.casey-digennaro.workers.dev",
                conversation_id: String = "default", embed: Bool = True):
        self.kev_url = kev_url
        self.substrate_url = substrate_url
        self.conversation_id = conversation_id
        self.last_hash = String("0x0000000000000000")  # genesis
        self.embed = embed
        self.request_count = 0
    
    fn systemone(inout self, state: String, questions_json: String) -> SubstrateResult:
        """Call kev's /v1/systemone and record as a substrate cell.
        
        Args:
            state: Conversation state as a string
            questions_json: JSON-encoded dict of questions
                e.g. {"dept": {"type": "choice", "instructions": "...", "criteria": [...]}}
        
        Returns:
            SubstrateResult with answers, cell_id, prev_hash, hash, embedding_id, latency_ms
        """
        # Start timer
        let t0 = now_ms()
        
        # Build request
        let request = SystemOneRequest(state, questions_json)
        let payload = request.to_payload()
        
        # POST to kev (HTTP)
        let kev_response = http_post(self.kev_url + "/v1/systemone", payload)
        let answers_json = extract_answers(kev_response)
        
        # Build the substrate cell
        let prev_hash = self.last_hash
        let timestamp_ms = now_ms()
        let cell_id = String("mojo-") + String(self.request_count)
        
        # Compute the cell's canonical hash
        let canonical = String(cell_id) + "|" + String(self.conversation_id) + "|" + \
                       String(prev_hash) + "|" + String(answers_json) + "|" + \
                       String(timestamp_ms)
        let cell_hash_int = fnv1a_64(canonical)
        let cell_hash = format_hash(cell_hash_int)
        
        # POST to substrate worker
        let cell_payload = String("{") + \
            "\"id\":\"" + String(cell_id) + "\"," + \
            "\"type\":\"kev-call\"," + \
            "\"state\":\"" + escape_json(answers_json) + "\"," + \
            "\"source\":\"kev-substrate-mojo\"," + \
            "\"conversation_id\":\"" + String(self.conversation_id) + "\"," + \
            "\"prev_hash\":\"" + String(prev_hash) + "\"," + \
            "\"hash\":\"" + String(cell_hash) + "\"" + \
            "}"
        
        let substrate_response = http_post(self.substrate_url + "/api/cell", cell_payload)
        let embedding_id = extract_embedding_id(substrate_response)
        
        # Update chain
        self.last_hash = cell_hash
        self.request_count += 1
        
        let t1 = now_ms()
        let latency_ms = Float64(t1 - t0)
        
        return SubstrateResult(
            answers_json=answers_json,
            cell_id=cell_id,
            prev_hash=prev_hash,
            hash=cell_hash,
            embedding_id=embedding_id,
            latency_ms=latency_ms,
        )
    
    fn jev_search(self, query: String, top_k: Int = 5) -> String:
        """Search the substrate canon via JEV. Returns JSON results."""
        let payload = String("{") + \
            "\"query\":\"" + escape_json(query) + "\"," + \
            "\"top_k\":" + String(top_k) + \
            "}"
        let response = http_post(self.substrate_url + "/api/jev/search", payload)
        return response
