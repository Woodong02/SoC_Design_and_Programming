# SoC_Design_and_Programming

## 프로젝트 개요

Zynq-7000 기반 학습용 보드 2대로 TDMA 필드버스(FlexRay)를 구성하고, 조도 센서 데이터를 노드 간 전송하는 시스템을 구현한다.

- **보드**: Zynq-7000 학습용 보드 × 2 (동일 HW 구성)
- **툴**: Vivado (버전 고정)
- **협업**: 2인, main 브랜치 단일 운용

---

## 시스템 구성

### 사용 HW
TFT-LCD, 7-Segment, Text LCD, 조도 센서, GPIO, DIP 스위치

### 사용 IP
| IP | 인터페이스 | 역할 |
|---|---|---|
| TFT-LCD | AXI | PS가 가공한 데이터 출력 |
| 7-Segment | FlexRay | 통신 관련 실시간 숫자 정보 표시 |
| Text LCD | AXI | 통신 관련 실시간 문자 정보 표시 |
| FlexRay | AXI | TDMA 통신 전체 담당 (프레이밍, 클럭 동기 포함) |
| 조도 센서 | FlexRay | 조도 값을 32비트로 출력 |
| GPIO | FlexRay | 통신 신호 투명 연결 |

### PS / PL 역할 분담
- **PL**: GPIO 통신, IP 구현, 센서 인터페이스
- **PS**: 제어 레지스터 조작, 데이터 읽기 및 가공

### 노드 역할
미정 (추후 업데이트 예정)

---

## 폴더 구조

```
SoC_Design_and_Programming/
├── ip/                  # 패키징 완료된 커스텀 IP
│   ├── flexray_v1.0/
│   ├── tft_lcd_v1.0/
│   ├── seven_seg_v1.0/
│   ├── text_lcd_v1.0/
│   ├── light_sensor_v1.0/
│   └── gpio_v1.0/
│       ├── hdl/         # RTL 소스
│       ├── bd/          # IP Packager 자동생성
│       ├── xgui/        # Vivado GUI 자동생성
│       ├── drivers/     # C 드라이버 (Vitis용)
│       ├── example_designs/
│       ├── component.xml
│       └── README.md    # 해당 IP 레지스터 맵 상세
├── dev/                 # 패키징 전 작업 파일
│   ├── flexray/
│   │   ├── rtl/
│   │   └── tb/
│   ├── tft_lcd/
│   ├── seven_seg/
│   ├── text_lcd/
│   ├── light_sensor/
│   └── gpio/
├── docs/                # 프로젝트 전체 사양 오버뷰
│   └── register_map_overview.md
├── bd/                  # Block Design tcl export
├── constraints/         # XDC 제약 파일
├── scripts/             # 프로젝트 재생성 tcl 스크립트
└── README.md
```

---

## 작업 현황

- [x] 폴더 구조 확정
- [ ] 레지스터 맵 작업 중
- [ ] RTL 설계
- [ ] IP 패키징
- [ ] Block Design 구성
- [ ] 검증 및 테스트

---

## 프로젝트 재생성 방법

Vivado에서 아래 스크립트를 실행하면 프로젝트가 로컬에 재생성된다.

```tcl
source scripts/create_project.tcl
```

> **주의**: 팀원 간 Vivado 버전이 일치해야 한다.
