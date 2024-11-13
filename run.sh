#!/bin/bash

# 공통 변수 설정
# 현재 디렉토리의 `data` 폴더를 Docker 컨테이너에 마운트할 볼륨 디렉토리로 지정
volume=$PWD/data
# 사용할 Docker 이미지 지정 (해당 예제에서는 Nvidia T4 기반의 이미지 활용)
image=ghcr.io/huggingface/text-embeddings-inference:turing-1.3 # Tesla T4
# 사용할 모델의 버전(revision)을 지정 (기본은 main 브랜치)
revision=main

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
    docker run --runtime=nvidia -d --gpus '"device='$i'"' \
      --network tei-net --name ${service_name}-$i \
      -v $volume:/data --pull always $image \
      --model-id $model --revision $revision --auto-truncate
  done

  # Nginx 로드 밸런서 컨테이너 실행
  # 모델에 따라 지정된 Nginx 설정 파일을 사용해 로드 밸런서 컨테이너를 시작
  docker run -d --network tei-net --name nginx-${service_name}-lb \
    -v $PWD/${config_file}:/etc/nginx/conf.d/default.conf:ro \
    -p $port:80 nginx:latest
}

# 모델별 Docker 컨테이너 실행
# Text Embeddings 모델과 Re-ranker 모델의 컨테이너를 각각 실행하고, 각 모델에 대해 Nginx 로드 밸런서를 구성
# `bge-m3` 모델은 8001 포트를 통해 외부에 노출
# `bge-reranker-v2-m3` 모델은 8002 포트를 통해 외부에 노출
run_docker "BAAI/bge-m3" 8001 "bge-embedder-tei" "nginx-embedder.conf"
run_docker "BAAI/bge-reranker-v2-m3" 8002 "bge-reranker-tei" "nginx-reranker.conf"