# 06. 인터럽트 레지스터 비트필드

> 검토 목적: 각 플래그의 필요 여부, enable 마스킹 설계  
> 블록: irq_flag / irq_enable / irq_combine  
> 동작 흐름: 개별 플래그 세트 → enable 마스킹 → CIFRR OR 합산 → PS 인터럽트 라인

---

## GIFER — Global Interrupt Flag and Enable Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | MIF | R | 모듈 인터럽트 플래그. 하위 플래그 중 하나라도 세트+enable이면 1. |
| 13 | PRIF | R | 프로토콜 인터럽트 플래그. PIFR0 기반 OR 합산. |
| 13 | CHIF | R | CHI 인터럽트 플래그. PRIF와 비트 공유 (PDF 원본 동일). |
| 12 | WUPIF | R/W | 웨이크업 수신 플래그. 1을 써서 클리어. |
| 11 | FNEBIF | R/W | 수신 FIFO B 비어있지 않음 플래그. 미사용 (단채널). |
| 10 | FNEAIF | R/W | 수신 FIFO A 비어있지 않음 플래그. |
| 9 | RBIF | R | 수신 버퍼 인터럽트 플래그. MBCCSRn MBIF+MBIE 기반 OR 합산. |
| 8 | TBIF | R | 송신 버퍼 인터럽트 플래그. MBCCSRn MBIF+MBIE 기반 OR 합산. |
| 7 | MIE | R/W | 모듈 인터럽트 라인 활성화. |
| 6 | PRIE | R/W | 프로토콜 인터럽트 라인 활성화. |
| 5 | CHIE | R/W | CHI 인터럽트 라인 활성화. |
| 4 | WUPIE | R/W | 웨이크업 인터럽트 활성화. |
| 3 | FNEBIE | R/W | 수신 FIFO B 인터럽트 활성화. 미사용 (단채널). |
| 2 | FNEAIE | R/W | 수신 FIFO A 인터럽트 활성화. |
| 1 | RBIE | R/W | 수신 버퍼 인터럽트 활성화. |
| 0 | TBIE | R/W | 송신 버퍼 인터럽트 활성화. |

---

## PIFR0 — Protocol Interrupt Flag Register 0

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | FATL_IF | R/W | 치명적 프로토콜 오류. POC:halt 즉시 전이. 1을 써서 클리어. |
| 14 | INTL_IF | R/W | 내부 프로토콜 오류. POC:halt 즉시 전이. |
| 13 | ILCF_IF | R/W | 불법 프로토콜 설정 감지. POC:halt 즉시 전이. |
| 12 | CSA_IF | R/W | 콜드스타트 시도 횟수 초과. |
| 11 | MRC_IF | R/W | 레이트 보정 측정값 부족. |
| 10 | MOC_IF | R/W | 오프셋 보정 측정값 부족. |
| 9 | CCL_IF | R/W | 보정값이 설정 한계 초과. |
| 8 | MXS_IF | R/W | 최대 sync frame 수 초과 감지. |
| 7 | MTX_IF | R/W | MTS 심볼 수신. |
| 6 | LTXB_IF | R/W | 채널 B 동적 세그먼트 경계 초과 송신. 미사용 (단채널). |
| 5 | LTXA_IF | R/W | 채널 A 동적 세그먼트 경계 초과 송신. |
| 4 | TBVB_IF | R/W | 채널 B 슬롯 경계 초과 송신. 미사용 (단채널). |
| 3 | TBVA_IF | R/W | 채널 A 슬롯 경계 초과 송신. |
| 2 | TI2_IF | R/W | 타이머 2 만료. 타이머 미사용으로 Reserved. |
| 1 | TI1_IF | R/W | 타이머 1 만료. 타이머 미사용으로 Reserved. |
| 0 | CYS_IF | R/W | 사이클 시작. 클럭 동기 루틴 트리거. 핵심 인터럽트. |

---

## PIER0 — Protocol Interrupt Enable Register 0

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | FATL_IE | R/W | FATL_IF 인터럽트 활성화. |
| 14 | INTL_IE | R/W | INTL_IF 인터럽트 활성화. |
| 13 | ILCF_IE | R/W | ILCF_IF 인터럽트 활성화. |
| 12 | CSA_IE | R/W | CSA_IF 인터럽트 활성화. |
| 11 | MRC_IE | R/W | MRC_IF 인터럽트 활성화. |
| 10 | MOC_IE | R/W | MOC_IF 인터럽트 활성화. |
| 9 | CCL_IE | R/W | CCL_IF 인터럽트 활성화. |
| 8 | MXS_IE | R/W | MXS_IF 인터럽트 활성화. |
| 7 | MTX_IE | R/W | MTX_IF 인터럽트 활성화. |
| 6 | LTXB_IE | R/W | LTXB_IF 인터럽트 활성화. 미사용 (단채널). |
| 5 | LTXA_IE | R/W | LTXA_IF 인터럽트 활성화. |
| 4 | TBVB_IE | R/W | TBVB_IF 인터럽트 활성화. 미사용 (단채널). |
| 3 | TBVA_IE | R/W | TBVA_IF 인터럽트 활성화. |
| 2 | TI2_IE | R/W | 타이머 미사용으로 Reserved. |
| 1 | TI1_IE | R/W | 타이머 미사용으로 Reserved. |
| 0 | CYS_IE | R/W | CYS_IF 인터럽트 활성화. 클럭 동기에 필수. |

---

## CIFRR — Combined Interrupt Flag Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 7 | MIF | R | 전체 인터럽트 OR 합산. 인터럽트 핸들러 진입 시 가장 먼저 확인. |
| 6 | PRIF | R | 프로토콜 인터럽트 OR 합산. enable 비트 무관하게 플래그만 반영. |
| 5 | CHIF | R | CHI 인터럽트 OR 합산. |
| 4 | WUPIF | R | GIFER[WUPIF] 복사본. |
| 3 | FNEBIF | R | GIFER[FNEBIF] 복사본. |
| 2 | FNEAIF | R | GIFER[FNEAIF] 복사본. |
| 1 | RBIF | R | 수신 버퍼 인터럽트 OR 합산. enable 무관. |
| 0 | TBIF | R | 송신 버퍼 인터럽트 OR 합산. enable 무관. |

---

## 관련 필드 (타 블록)

### MBCCSRn — 버퍼별 인터럽트 (메시지 버퍼 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 8 | MBIE | 해당 버퍼 인터럽트 활성화. GIFER[RBIF/TBIF]에 합산됨. |
| 0 | MBIF | 해당 버퍼 인터럽트 플래그. 1을 써서 클리어. |

### PSR2 — 프로토콜 오류 상태 (제어/상태 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 3–0 | CLKCORRFAILCNT | MRC_IF/MOC_IF 누적 횟수와 연동. |
