# Text Embeddings Inference 멀티 GPU 추론
이 시스템은 nginx를 사용하여 TEI 컨테이너에 대한 로드 밸런싱을 제공하여 멀티 GPU 환경에서 추론을 수행할 수 있도록 설계되었습니다. `nginx-embedder.conf`와 `nginx-reranker.conf` 파일은 각각 임베더와 리랭커 서비스에 대한 nginx 설정을 정의합니다.

  

## 도식 
다음은 시스템의 기본 아키텍처입니다.
+-------------------+ +-----------------------+ +-----------------------+
| 클라이언트 요청 | --> | nginx (로드 밸런서) | --> | TEI 컨테이너 (멀티 GPU) |
+-------------------+ +-----------------------+ +-----------------------+

nginx는 들어오는 요청을 여러 TEI 컨테이너에 분산하여 멀티 GPU를 효율적으로 활용하고 추론 성능을 향상시킵니다.

  
## 설정
### nginx
nginx는 `nginx.conf` 파일을 사용하여 설정됩니다. 이 파일은 `nginx-embedder.conf`와 `nginx-reranker.conf`에서 정의된 업스트림 서버를 사용하여 로드 밸런싱을 구성합니다.

`nginx-embedder.conf` 파일은 `bge-embedder-tei` 업스트림을 정의하고, `bge-embedder-tei-0` 및 `bge-embedder-tei-1` 서버로 라우팅합니다.

`nginx-reranker.conf` 파일은 `bge-reranker-tei` 업스트림을 정의하고, `bge-reranker-tei-0` 및 `bge-reranker-tei-1` 서버로 라우팅합니다.


### Docker

Dockerfile은 nginx 이미지를 기반으로 빌드됩니다. `default.conf` 파일을 제거하고, 프로젝트의 `nginx.conf` 파일을 사용하도록 설정합니다. 80 포트를 통해 서비스를 제공합니다.

## 실행 방법
### Nginx 로드밸런서 실행

`./run-nginx-loadbalancer.sh`

### TEI 컨테이너 실행

`./run-tei-container.sh`