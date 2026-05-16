# 03. 타이밍 / 카운터 레지스터 비트필드

> 검토 목적: 각 필드의 필요 여부, 비트 수 재설계  
> 블록: timing_counter  
> 주의: 전부 읽기 전용. PE의 tdma_scheduler가 업데이트.

---

## MTCTR — Macrotick Counter Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 13–0 | MTCT | R | 현재 사이클 내 매크로틱 카운터 값. vMacrotick. 사이클 시작 시 0으로 리셋. |

---

## CYCTR — Cycle Counter Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 5–0 | CYCCNT | R | 현재 통신 사이클 번호. vCycleCounter. 0~63 순환. |

---

## SLTCTAR — Slot Counter Channel A Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 10–0 | SLOTCNTA | R | 현재 사이클 내 채널 A 슬롯 카운터. vSlotCounter. |

---

## 관련 필드 (타 블록)

### PCR10 — 사이클 길이 설정 (프로토콜 설정 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 13–0 | macro_per_cycle | MTCTR의 최대값을 결정. TDMA 사이클 전체 길이. |

### PCR0 — 슬롯 길이 설정 (프로토콜 설정 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 10–0 | static_slot_length | SLTCTAR 슬롯 경계 타이밍 기준. |

### PIFR0 — 사이클 시작 인터럽트 (인터럽트 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 0 | CYS_IF | 사이클 시작 시 세트. CYCTR, MTCTR 리셋 시점과 동기. PS 클럭 동기 루틴 트리거. |
