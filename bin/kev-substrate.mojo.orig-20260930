"""kev-substrate CLI entry point in Mojo.

Usage:
    kev-substrate --state "Customer is upset about billing" --question "dept:choice:Which team:returns=Returns|billing=Billing"
    
    kev-substrate --search "shipwright Jev" --top-k 3
"""
from substrate.client import SubstrateClient
from splines.snap import make_snap


fn main():
    # Parse args (simplified — real impl uses proper arg parsing)
    let args = get_args()
    
    var client = SubstrateClient()
    
    if "--search" in args:
        let query = get_arg_value(args, "--search")
        let top_k_str = get_arg_value(args, "--top-k")
        let top_k = Int(top_k_str) if top_k_str else 5
        let results = client.jev_search(query, top_k)
        print("JEV search results:")
        print(results)
    elif "--state" in args and "--question" in args:
        let state = get_arg_value(args, "--state")
        let question_str = get_arg_value(args, "--question")
        # Simple parsing: "qid:type:text:opt1=val1|opt2=val2"
        let question_json = parse_question(question_str)
        let result = client.systemone(state, question_json)
        print("SystemOne result:")
        print("  answers: " + result.answers_json)
        print("  cell_id: " + result.cell_id)
        print("  prev_hash: " + result.prev_hash)
        print("  hash: " + result.hash)
        print("  embedding_id: " + result.embedding_id)
        print("  latency_ms: " + String(result.latency_ms))
    elif "--snap" in args:
        # Demo: snap a question with mock confidence
        let question = get_arg_value(args, "--snap")
        let snap = make_snap(question, "noul", "yes", 0.85)
        print("SplineSnap:")
        print(snap.to_dict())
    else:
        print("Usage: kev-substrate [--state ... --question ...] | [--search ... --top-k N] | [--snap ...]")
        print("")
        print("Examples:")
        print("  kev-substrate --state 'Customer is upset' --question 'dept:choice:Which team:returns=Returns|billing=Billing'")
        print("  kev-substrate --search 'shipwright Jev' --top-k 3")
        print("  kev-substrate --snap 'Is this a duck?'")
