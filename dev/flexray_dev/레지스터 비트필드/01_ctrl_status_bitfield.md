# 01. 제어 / 상태 레지스터 비트필드

> 검토 목적: 각 필드의 필요 여부, 비트 수, 동작 방식 재설계  
> 블록: mod_cfg / poc_cmd / psr_status

---

## MCR — Module Configuration Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | MEN | R/W | 모듈 활성화. 1을 쓰면 Disabled Mode 탈출. 한 번 활성화하면 비활성화 불가. |
| 13 | SCM | R/W | 단채널 모드. 0=듀얼채널, 1=단채널. 우리는 1 고정. |
| 12 | CHB | R/W | 채널 B 활성화. 단채널이라 미사용. |
| 11 | CHA | R/W | 채널 A 활성화. 단채널이라 1 고정. |
| 10 | SFFE | R/W | 수신 sync frame 필터링 여부. |
| 3–1 | BITRATE | R/W | 버스 비트레이트. 000=10Mbps, 001=5Mbps, 010=2.5Mbps. |

---

## POCR — Protocol Operation Control Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | WME | R/W | EOC_AP, ERC_AP 쓰기 모드. 1이면 해당 필드 쓰기 무시. |
| 11–10 | EOC_AP | R/W | 외부 오프셋 보정값 적용 트리거. 00=미적용, 10=빼기, 11=더하기. |
| 9–8 | ERC_AP | R/W | 외부 레이트 보정값 적용 트리거. 00=미적용, 10=빼기, 11=더하기. |
| 7 | BSY | R | POC 명령 처리 중 플래그. 1이면 명령 수신 불가. 명령 전 반드시 확인. |
| 6 | WMC | R/W | POCCMD 쓰기 모드. 1이면 POCCMD 쓰기 무시. |
| 3–0 | POCCMD | R/W | POC 상태 전이 명령. 0010=config, 0100=ready, 0101=run, 0011=freeze, 0110=default_config. |

---

## PSR0 — Protocol Status Register 0

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–14 | ERRMODE | R | 현재 오류 모드. 00=ACTIVE, 01=PASSIVE, 10=COMM_HALT. |
| 13–12 | SLOTMODE | R | 현재 슬롯 모드. 00=SINGLE, 10=ALL. |
| 10–8 | PROTSTATE | R | 현재 POC 상태. 000=default_config, 001=config, 011=ready, 101=normal_active, 110=halt, 111=startup. |
| 7–4 | STARTUPSTATE | R | 스타트업 세부 상태. 정상 동작 중엔 의미없음. |
| 2–0 | WAKEUPSTATUS | R | 웨이크업 절차 결과. 미사용 시 000=UNDEFINED. |

---

## PSR1 — Protocol Status Register 1

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | CSAA | R/W | 콜드스타트 시도 중단 플래그. PS가 1 써서 클리어. |
| 14 | CSP | R | 이 노드가 leading coldstart로 네트워크를 시작했는지 여부. |
| 12–8 | REMCSAT | R | 남은 콜드스타트 시도 횟수. |
| 7 | CPN | R | 노이즈 환경에서 콜드스타트 성공 여부. |
| 6 | HHR | R | PS가 HALT 명령을 보냈고 아직 처리 대기 중. |
| 5 | FRZ | R | freeze 명령 또는 내부 오류로 POC:halt 진입 여부. |
| 4–0 | APTAC | R | passive→active 전이 대기 사이클 쌍 카운터. |

---

## PSR2 — Protocol Status Register 2

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | NBVB | R | NIT 구간 채널 B 경계 위반 감지. |
| 14 | NSEB | R | NIT 구간 채널 B 문법 오류 감지. |
| 13 | STCB | R | 심볼 윈도우 채널 B 송신 충돌. |
| 12 | SBVB | R | 심볼 윈도우 채널 B 경계 위반. |
| 11 | SSEB | R | 심볼 윈도우 채널 B 문법 오류. |
| 10 | MTB | R | 채널 B에서 MTS 심볼 수신. |
| 9 | NBVA | R | NIT 구간 채널 A 경계 위반 감지. |
| 8 | NSEA | R | NIT 구간 채널 A 문법 오류 감지. |
| 7 | STCA | R | 심볼 윈도우 채널 A 송신 충돌. |
| 6 | SBVA | R | 심볼 윈도우 채널 A 경계 위반. |
| 5 | SSEA | R | 심볼 윈도우 채널 A 문법 오류. |
| 4 | MTA | R | 채널 A에서 MTS 심볼 수신. |
| 3–0 | CLKCORRFAILCNT | R | 클럭 보정 실패 연속 횟수. 설정 한계 도달 시 오류 모드 전이. |

---

## 관련 필드 (타 블록)

### PIFR0 — 제어/상태와 연동되는 플래그 (인터럽트 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 15 | FATL_IF | 치명적 프로토콜 오류 발생. POC:halt 즉시 전이. |
| 14 | INTL_IF | 내부 프로토콜 오류. POC:halt 즉시 전이. |
| 13 | ILCF_IF | 불법 프로토콜 설정 감지. POC:halt 즉시 전이. |
| 12 | CSA_IF | 콜드스타트 시도 횟수 초과로 중단. |
| 0 | CYS_IF | 사이클 시작 플래그. 클럭 동기 인터럽트 트리거. |

### GIFER — 전역 인터럽트 (인터럽트 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 15 | MIF | 모듈 인터럽트 플래그 (OR 합산). |
| 13 | PRIF | 프로토콜 인터럽트 플래그. PIFR0 기반. |
