# SAR simulator 기반 AI roadmap
## 📌 SAR 기반 AI 전체 로드맵
### 1단계. 물리 기반 SAR 시뮬레이션
- 목적: 현실에서 얻기 힘든 SAR 데이터를 무제한 생성
- 도구: MATLAB, Python, Drozdowicz 3D 시뮬레이터, Range-Doppler, InSAR, Backprojection 등

1. 시뮬레이터 개발  
    - 입력: 지형(DEM), 타겟(건물, 선박, 차량), 레이더 파라미터(주파수, 대역폭, 경사각 등)
    - 처리:
        - 전파 전파 모델링
        - 플랫폼 궤적 시뮬레이션
        - 신호 수신 & 압축(범위 압축, 방위 압축)
        - 2D/3D 영상 생성
    - 출력: SAR 영상(다양한 관측 조건)

2. 데이터 다양성 확보  
    - 다양한 각도, 고도, 주파수, 해상도
    - 다양한 환경: 바다, 도시, 산악
    - 다양한 물체: 크기, 모양, 배치

### 2단계. AI 학습용 데이터 구축
- 목적: 데이터 부족 문제 해결 + AI 학습 최적화

1. 라벨 데이터셋 생성
    - 시뮬레이터에서 각 물체의 위치·클래스 정보 자동 추출 → Bounding Box, Segmentation Mask 생성 가능
2. Self-Supervised Pretraining
    - 시뮬레이션 SAR 영상 + 실제 SAR 영상(라벨X)
    - 자기 지도 학습 모델 예:
        - MoCo, SimCLR → 대조 학습
        - MAE (Masked Autoencoder) → 마스크 복원
        - BYOL, DINO → 표현 학습
    - 결과: SAR 전용 Feature Extractor 학습

### 3단계. 다운스트림 AI 활용
- 목적: 다양한 SAR AI 응용 분야에 활용
1. Object Detection (탐지)
    - 예: YOLO, Faster R-CNN
    - 선박, 차량, 건물 탐지
    - 학습: Self-Supervised Feature Extractor + 소량 라벨로 Fine-tuning
2. Classification (분류)
    - 물체 종류, 선박 타입, 구조물 식별
    - SAR → EO 변환 후 분류 가능
3. Segmentation (분할)
    - 건물, 도로, 수역 등 영역 분할
    - U-Net, SegFormer 활용
4. SAR-to-EO Translation
    - Pix2PixHD, ParallelGAN → SAR 이미지를 광학 영상처럼 변환
    - EO 학습 데이터 부족 지역 해소 가능
5. 3D Reconstruction & Change Detection
    - InSAR, PolSAR 데이터로 지형 고도맵, 구조물 변화 탐지

