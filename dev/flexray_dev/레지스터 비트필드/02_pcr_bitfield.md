# 02. 프로토콜 설정 레지스터 비트필드

> 검토 목적: 각 필드의 필요 여부, 값 범위 재설계  
> 블록: slot_timing / node_param / corr_param / startup_param  
> 주의: 전부 POC:config 상태에서만 쓰기 가능

---

## PCR0 — Protocol Configuration Register 0

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | action_point_offset | R/W | 슬롯 내 액션 포인트 오프셋. gdActionPointOffset - 1 (매크로틱 단위). |
| 10–0 | static_slot_length | R/W | 정적 슬롯 길이. gdStaticSlot (매크로틱 단위). |

---

## PCR1 — Protocol Configuration Register 1

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 13–0 | macro_after_first_static_slot | R/W | 첫 번째 정적 슬롯 이후 남은 매크로틱 수. gMacroPerCycle - gdStaticSlot. |

---

## PCR2 — Protocol Configuration Register 2

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | minislot_after_action_point | R/W | 액션 포인트 이후 미니슬롯 수. gdMinislot - gdMinislotActionPointOffset - 1. |
| 10–0 | number_of_static_slots | R/W | 정적 세그먼트 슬롯 수. gNumberOfStaticSlots. |

---

## PCR3 — Protocol Configuration Register 3

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | wakeup_symbol_rx_low | R/W | 웨이크업 심볼 수신 low 구간 길이 (비트 단위). |
| 10–6 | minislot_action_point_offset | R/W | 미니슬롯 액션 포인트 오프셋 - 1 (매크로틱 단위). |
| 5–0 | coldstart_attempts | R/W | 콜드스타트 최대 시도 횟수. gColdstartAttempts. |

---

## PCR4 — Protocol Configuration Register 4

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–9 | cas_rx_low_max | R/W | CAS 수신 low 구간 최대값 - 1 (비트 단위). |
| 8–0 | wakeup_symbol_rx_window | R/W | 웨이크업 심볼 수신 윈도우 크기 (비트 단위). |

---

## PCR10 — Protocol Configuration Register 10

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | single_slot_enabled | R/W | 단일 슬롯 모드 활성화 여부. pSingleSlotEnabled. |
| 14 | wakeup_channel | R/W | 웨이크업에 사용할 채널 선택. |
| 13–0 | macro_per_cycle | R/W | 사이클당 매크로틱 수. gMacroPerCycle. TDMA 사이클 길이의 핵심 파라미터. |

---

## PCR12 — Protocol Configuration Register 12

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | allow_passive_to_active | R/W | passive→active 전이 허용 전 대기 사이클 쌍 수. pAllowPassiveToActive. |
| 10–0 | key_slot_header_crc | R/W | 키 슬롯 헤더 CRC 값. |

---

## PCR16 — Protocol Configuration Register 16

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–9 | macro_initial_offset_b | R/W | 채널 B 초기 매크로틱 오프셋. pMacroInitialOffset[B]. |
| 8–0 | noise_listen_timeout[24:16] | R/W | 노이즈 청취 타임아웃 상위 비트. (gListenNoise × pdListenTimeout) - 1. |

---

## PCR21 — Protocol Configuration Register 21

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | extern_rate_correction | R/W | 외부 레이트 보정값 한계. pExternRateCorrection (마이크로틱 단위). |
| 10–0 | latest_tx | R/W | 동적 세그먼트 최후 송신 슬롯. gNumberOfMinislots - pLatestTx. |

---

## PCR22 — Protocol Configuration Register 22

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 14–5 | comp_accepted_startup_range_a | R/W | 채널 A 스타트업 허용 범위. pdAcceptedStartupRange - pDelayCompensationChA. |
| 3–0 | micro_per_cycle[19:16] | R/W | 사이클당 마이크로틱 수 상위 4비트. pMicroPerCycle 상위. |

---

## PCR29 — Protocol Configuration Register 29

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–11 | extern_offset_correction | R/W | 외부 오프셋 보정값 한계. pExternOffsetCorrection (마이크로틱 단위). |
| 10–0 | minislots_max | R/W | 동적 세그먼트 미니슬롯 최대값. gNumberOfMinislots - 1. |

---

## 관련 필드 (타 블록)

### POCR — PCR 쓰기 전제 조건 (제어/상태 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 3–0 | POCCMD | 0010=config 명령으로 전이해야 PCR 쓰기 가능. |
| 7 | BSY | config 명령 전 BSY=0 확인 필요. |

### PSR0 — PCR 쓰기 가능 상태 확인 (제어/상태 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 10–8 | PROTSTATE | 001=config 상태일 때만 PCR 쓰기 가능. |
