# Note for study about SAR image formation
date: 25.07.23. ~ present  
author: Kim, Seong Hyun  
subject: image formation, reconstruction theory about SAR  

---
## 1. SAR 영상 형성 단계 요약
> 1. Range Compression
>       - 각 펄스별로 시간 지연에 따라 수신된 echo에 대해 발사된 chrip 신호의 matched filter(matched filtering)를 적용합니다.
>       - 이를 통해 각 펄스의 에너지가 특정 거리(비탈각)에 응집되고, 원거리-거리 방향의 초점(focus)이 이루어집니다.
> 2. Range Cell Migration Correction (RCMC)
>       - 비행체 움직임 혹은 대상의 궤적 때문에 대상의 반사 신호가 여러 range-bin에 걸쳐 굴곡(hyperbolic curve)을 이루며 퍼집니다.
>       - 이를 보정해 "range line"이 직선이 되도록 정렬하는 단계입니다.
> 3. Azimuth Compression
>       - 정렬된 데이터(azimuth 방향 퍼짐)에 matched filtering 또는 FFT를 통해 압축을 적용하여 cross-range 초점을 수행합니다.
>       - 대표적으로 Range-Doppler Algorithm (RDA), Chirp Scaling Algorithm (CSA), Back-projection 등의 방법이 사용됩니다.
> 4. Inverse FFT / Imaging
>       - Azimuth 초점까지 완료된 신호를 inverse FFT로 변환하여 최종 SAR 이미지를 생성합니다.
> 5. Motion Compensation (보정)
>       - 플랫폼의 실제 움직임 오류, Doppler 중심 주파수 이동, PRF 오차 등 실환경에서 발생할 수 있는 오차를 보정하는 여러 기술을 적용하여 이미지의 품질을 향상시킵니다.
### 전체 처리 흐름  
Raw Data ▶ Range Compression (matched filtering) ▶ RCMC (곡선형 range bin 보정) ▶ Azimuth Compression (matched filter / FFT) ▶ Inverse FFT → SAR image
- 이 과정에서 각 단계마다 정확한 수학적 수식과 필터링 함수(ex. azimuth chirp, range chirp 등)가 필요합니다.

---
## Reference
