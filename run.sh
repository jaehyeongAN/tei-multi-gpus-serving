#!/bin/bash

# 공통 변수 설정
volume=$PWD/data
revision=main

# 실행 시 첫 번째 매개변수로 GPU 타입 입력 (기본값: T4)
gpu_type=${1:-T4}

# GPU 타입에 따른 이미지 선택
if [[ $gpu_type == "T4" ]]; then
  image_path=$PWD/tei-images/text-embeddings-inference-turing.tar
  image=ghcr.io/huggingface/text-embeddings-inference:turing-latest
elif [[ $gpu_type == "L4" ]]; then
  image_path=$PWD/tei-images/text-embeddings-inference-adalovelace.tar
  image=ghcr.io/huggingface/text-embeddings-inference:89-latest
elif [[ $gpu_type == "A100" ]]; then
  image_path=$PWD/tei-images/text-embeddings-inference-ampere80.tar
  image=ghcr.io/huggingface/text-embeddings-inference:latest
elif [[ $gpu_type == "H100" ]]; then
  image_path=$PWD/tei-images/text-embeddings-inference-hopper.tar
  image=ghcr.io/huggingface/text-embeddings-inference:hopper-latest
else
  echo "Invalid GPU type. Please specify 'T4', 'L4', 'A100', 'H100'"
  exit 1
fi

# Nginx
nginx_image_path=$PWD/tei-images/nginx.tar
nginx_image=nginx:latest

# Docker 네트워크 생성
# `tei-net`이라는 네트워크를 생성하여 모델 컨테이너와 Nginx 로드 밸런서를 연결
# `|| true`는 이미 네트워크가 존재하는 경우 오류를 무시하고 진행
docker network create tei-net || true

# Docker 컨테이너 실행을 위한 함수 정의
# 이 함수는 세 개의 인자를 받음:
# - model: 실행할 모델의 이름 (Hugging Face 모델 허브에 등록된 모델 ID)
# - port: Nginx 로드 밸런서가 외부에 노출할 포트 번호
# - service_name: 모델 컨테이너와 Nginx 컨테이너의 서비스명을 구성하는데 사용
# - config_file: Nginx 로드 밸런서 설정 파일 경로
run_docker() {
  local model=$1
  local port=$2
  local service_name=$3
  local config_file=$4  

  # 모델 컨테이너 실행 (해당 예제에서는 두 개의 GPU 장치를 사용해 컨테이너를 각각 실행하며, GPU ID는 0과 1로 할당)
  for i in $(seq 0 1); do
    # docker run -d --restart always --runtime=nvidia --gpus '"device='$i'"' \
    docker run -d --restart always --gpus '"device='$i'"' \
      --network tei-net --name ${service_name}-$i \
      -v $volume:$volume \
      -v $model:$model \
      --pull never $image --model-id $model --revision $revision --auto-truncate
  done

  # Nginx 로드 밸런서 컨테이너 실행
  # 모델에 따라 지정된 Nginx 설정 파일을 사용해 로드 밸런서 컨테이너를 시작
  docker run -d --restart always --network tei-net --name nginx-${service_name}-lb \
    -v $PWD/${config_file}:/etc/nginx/conf.d/default.conf:ro \
    -p $port:80 \
    $nginx_image
}

# 모델별 Docker 컨테이너 실행
# Text Embeddings 모델과 Re-ranker 모델의 컨테이너를 각각 실행하고, 각 모델에 대해 Nginx 로드 밸런서를 구성
# `bge-m3` 모델은 8001 포트를 통해 외부에 노출
# `bge-reranker-v2-m3` 모델은 8002 포트를 통해 외부에 노출
run_docker "BAAI/bge-m3" 8001 "bge-embedder-tei" "nginx-embedder.conf"
run_docker "BAAI/bge-reranker-v2-m3" 8002 "bge-reranker-tei" "nginx-reranker.conf"