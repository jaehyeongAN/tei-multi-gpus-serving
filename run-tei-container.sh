run_docker "BAAI/bge-m3" 8001 "bge-embedder-tei" "nginx-embedder.conf"
run_docker "BAAI/bge-reranker-v2-m3" 8002 "bge-reranker-tei" "nginx-reranker.conf"