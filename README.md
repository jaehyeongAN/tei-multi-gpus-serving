# Text Embeddings Inference Multi-GPU Serving

## Overview
This system provides load balancing for Text Embeddings Inference (TEI) containers using Nginx, enabling efficient inference across multiple GPUs. The architecture distributes incoming requests to multiple TEI containers to maximize GPU utilization and improve inference performance.

## Architecture
![tei-lb](./tei-lb.png)

The system consists of:
- Multiple TEI containers running on separate GPUs
- Nginx as a load balancer to distribute requests
- Configuration for both embedding and reranking services

## Components

### Nginx Load Balancer
- Uses separate configuration files for each service type:
  - `nginx-embedder.conf`: Defines the `bge-embedder-tei` upstream for embedding services
  - `nginx-reranker.conf`: Defines the `bge-reranker-tei` upstream for reranking services
- Routes requests to appropriate TEI container instances

### TEI Containers
- Each container runs on a dedicated GPU
- Support for different GPU types (T4, L4, A100, H100)
- Configured for specific models:
  - Embedding model: `BAAI/bge-m3` (exposed on port 8001)
  - Reranking model: `BAAI/bge-reranker-v2-m3` (exposed on port 8002)

## Setup and Configuration

### 1. Clone Repo
```
git clone -b feature/closed-network https://github.com/HelpNow-AI/tei-multi-gpu-loadbalancing.git
```

### 2. Downdload Nginx image and Save to. `.tar`
```
docker pull nginx:latest
docker save -o ./tei-images/nginx.tar nginx:latest
```

### 3. Download TEI Image based on your GPU architecture and Save to `.tar`
```
# Option 1: Turing architecture (T4, RTX 2000 series, …)
docker pull ghcr.io/huggingface/text-embeddings-inference:turing-latest
docker save -o ./tei-images/text-embeddings-inference-turing.tar ghcr.io/huggingface/text-embeddings-inference:turing-latest
```
```
# Option 2: Ampere 80 architecture (A100, A30)
docker pull ghcr.io/huggingface/text-embeddings-inference:89-latest
docker save -o ./tei-images/text-embeddings-inference-ampere80.tar ghcr.io/huggingface/text-embeddings-inference:89-latest
```
```
# Option 3: Ada Lovelave architecture (RTX 4000 series, …)
docker pull ghcr.io/huggingface/text-embeddings-inference:latest 
docker save -o ./tei-images/text-embeddings-inference-adalovelace.tar ghcr.io/huggingface/text-embeddings-inference:latest
```
```
# Option 4: Hopper architecture (H100)
docker pull ghcr.io/huggingface/text-embeddings-inference:hopper-latest
docker save -o ./tei-images/text-embeddings-inference-hopper.tar ghcr.io/huggingface/text-embeddings-inference:hopper-latest
```

### 4. Download HF Models (prerequisite: Git LFS install)
```
mkdir models
cd ./models

git clone https://huggingface.co/BAAI/bge-m3 # bge-m3
git clone https://huggingface.co/BAAI/bge-reranker-v2-m3 # bge-reranker-v2-m3
```

## Deployment

### Running the System
1. To start the entire system with both embedder and reranker services:
```bash
./run.sh [GPU_TYPE]
```
Where `GPU_TYPE` is one of: T4 (default), L4, A100, or H100.

2. The script will:
   - Create a Docker network
   - Start two TEI containers for each service (embedder and reranker)
   - Configure and start Nginx load balancers for each service

### Access Points
- Embedding service: http://localhost:8001
- Reranking service: http://localhost:8002

## Data Storage
The system mounts a local `data` directory to each container for persistent storage and model caching.