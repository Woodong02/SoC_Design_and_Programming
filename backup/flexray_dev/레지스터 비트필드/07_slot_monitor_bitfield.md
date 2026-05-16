# 07. 슬롯 모니터링 레지스터 비트필드

> 검토 목적: 각 필드의 필요 여부, 모니터링 슬롯 수 결정  
> 블록: slot_sel / slot_status / slot_counter  
> 동작 흐름: SSSR로 슬롯 선택 → SSR0~7에 상태 캡처 → SSCCR 조건으로 SSCR0~3 카운팅

---

## SSSR — Slot Status Selection Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | WMD | R/W | 쓰기 모드. 0=전체 필드 쓰기, 1=SEL 필드만 쓰기. |
| 13–12 | SEL | R/W | 내부 슬롯 선택 레지스터 선택. 00=SSSR0, 01=SSSR1, 10=SSSR2, 11=SSSR3. |
| 10–0 | SLOTNUMBER | R/W | 모니터링할 슬롯 번호. 0이면 심볼 윈도우/NIT 상태 제공. |

> SSSR0~SSSR3 4개의 내부 레지스터를 SEL로 선택해 접근. 각각 SSR 쌍과 매핑됨.  
> SSSR0 → SSR0(짝수 사이클), SSR1(홀수 사이클)  
> SSSR1 → SSR2, SSR3 / SSSR2 → SSR4, SSR5 / SSSR3 → SSR6, SSR7

---

## SSCCR — Slot Status Counter Condition Register

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | WMD | R/W | 쓰기 모드. 0=전체 필드 쓰기, 1=SEL 필드만 쓰기. |
| 13–12 | SEL | R/W | 내부 카운터 조건 레지스터 선택. 00=SSCCR0~SSCR0 대응. |
| 10–9 | CNTCFG | R/W | 카운터 채널 조건. 00=채널 A, 01=채널 B, 10=둘 중 하나, 11=둘 다. |
| 8 | MCY | R/W | 멀티사이클 누적 모드. 0=직전 사이클만, 1=여러 사이클 누적. |
| 7 | VFR | R/W | 유효 프레임만 카운팅. |
| 6 | SYF | R/W | sync frame만 카운팅. |
| 5 | NUF | R/W | null frame 제외 카운팅. |
| 4 | SUF | R/W | startup frame만 카운팅. |
| 3–0 | STATUSMASK | R/W | 에러 조건 마스크. [3]=문법오류, [2]=내용오류, [1]=경계위반, [0]=송신충돌. |

---

## SSR0~SSR7 — Slot Status Registers

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15 | VFB | R | 채널 B 유효 프레임 수신. |
| 14 | SYB | R | 채널 B sync frame 수신. |
| 13 | NFB | R | 채널 B null frame 수신. |
| 12 | SUB | R | 채널 B startup frame 수신. |
| 11 | SEB | R | 채널 B 문법 오류. |
| 10 | CEB | R | 채널 B 내용 오류. |
| 9 | BVB | R | 채널 B 경계 위반. |
| 8 | TCB | R | 채널 B 송신 충돌. |
| 7 | VFA | R | 채널 A 유효 프레임 수신. |
| 6 | SYA | R | 채널 A sync frame 수신. |
| 5 | NFA | R | 채널 A null frame 수신. |
| 4 | SUA | R | 채널 A startup frame 수신. |
| 3 | SEA | R | 채널 A 문법 오류. |
| 2 | CEA | R | 채널 A 내용 오류. |
| 1 | BVA | R | 채널 A 경계 위반. |
| 0 | TCA | R | 채널 A 송신 충돌. |

---

## SSCR0~SSCR3 — Slot Status Counter Registers

| 비트 | 필드 | R/W | 설명 |
|------|------|-----|------|
| 15–0 | SLOTSTATUSCNT | R | 슬롯 상태 카운터 값. SSCCR 조건에 따라 사이클 시작 시 업데이트. 0xFFFF에서 멈춤 (누적 모드). |

---

## 관련 필드 (타 블록)

### MBFIDRn — 슬롯 번호 참조 (메시지 버퍼 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 10–0 | FID | SSSR의 SLOTNUMBER와 같은 값으로 설정하면 해당 버퍼 슬롯 상태 모니터링 가능. |

### SLTCTAR — 현재 슬롯 번호 (타이밍/카운터 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 10–0 | SLOTCNTA | SSR 업데이트 시점의 슬롯 번호와 대응. |

### PIFR0 — 슬롯 관련 오류 플래그 (인터럽트 블록)

| 비트 | 필드 | 설명 |
|------|------|------|
| 5 | LTXA_IF | 채널 A 동적 세그먼트 경계 초과. SSR의 BVA와 연관. |
| 3 | TBVA_IF | 채널 A 슬롯 경계 초과 송신. SSR의 TCA와 연관. |
