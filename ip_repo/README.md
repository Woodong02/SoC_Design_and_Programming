# ip_repo

## 개요

패키징 완료된 커스텀 IP 보관소. Vivado IP Packager로 패키징된 IP만 여기에 위치한다.
작업 중인 IP는 `dev/` 폴더에서 관리하고, 패키징 완료 후 이곳으로 옮긴다.

Vivado에서 이 폴더를 IP Repository로 등록하면 Block Design에서 커스텀 IP를 사용할 수 있다.

---

## IP 목록

| 폴더 | 인터페이스 | 상태 |
|---|---|---|
| flexray | AXI | 작업 중 |
| tft_lcd | AXI | 작업 중 |
| seven_seg | FlexRay | 작업 중 |
| text_lcd | AXI | 작업 중 |
| light_sensor | FlexRay | 작업 중 |

---

## IP Repository 등록 방법

Vivado에서 아래 경로로 이 폴더를 등록한다.

```
Tools → Settings → IP → Repository → + → ip_repo 경로 선택
```

---

## 폴더 구조 규칙

- 각 IP 폴더 내부 구조는 Vivado IP Packager가 자동 관리한다.
- `hdl/` — RTL 소스
- `xgui/` — Vivado GUI 자동생성 (수정 금지)
- `component.xml` — IP 메타데이터 (수정 금지)
- `README.md` — 해당 IP 레지스터 맵 상세
