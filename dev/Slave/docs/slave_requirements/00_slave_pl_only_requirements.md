# Slave PL-only IP 요구사항

## 목적

이 문서는 현재 구현된 Master PL+PS 분석을 바탕으로, PS 없이 동작하는 Slave PL-only IP가 만족해야 할 요구사항을 정리한다.

Master는 PS `main.c`가 AXI register를 설정하고 상태를 읽는 구조이다. Slave는 그런 PS 제어 경로가 없으므로, Master의 통신 기대값 중 Slave에도 필요한 값은 Verilog parameter, localparam, 내부 FSM, 또는 Master broadcast 수신값으로 대체해야 한다.

## 확정 설계 전제

- Slave는 pure Verilog로 작성한다.
- Slave는 PL 단독 IP이다.
- Slave IP는 여러 node에 재사용된다.
- 각 node의 ID는 Verilog parameter로 기입한다.

```verilog
parameter [2:0] NODE_ID = 3'd0;
```

- Master broadcast frame의 `GUARD_TICKS` field는 수신하고 파싱한다.
- 수신한 `GUARD_TICKS`는 별도 flip-flop에 저장만 한다.
- `GUARD_TICKS`를 이용해 slave timing을 동적으로 바꾸는 기능은 이번 범위에서 보류한다.
- Slave initial sync는 Master broadcast의 첫 preamble 수신으로 잡는다.
- Preamble 첫 `1` 검출은 RX 내부 sync candidate로만 사용한다.
- Preamble `8'hAA` 검증 성공 시에만 sync를 commit한다.
- Sync commit 시 `sync_clk_cnt = 8 * BIT_DIV` preload를 `slave_slot_timer`에 전달한다.
- Preamble 검증 실패 시 sync하지 않는다.
- Master message가 올 때마다 slave timer를 다시 sync한다.
- Slave에는 현재 sync drift fault를 소비할 별도 fault 처리 모듈이 없으므로, 예상 sync window나 unexpected sync event는 계산/기록하지 않는다.
- Slave local timer 추정과 다른 시점에 Master preamble이 오더라도, 해당 preamble을 기준으로 즉시 resync한다.
- `halt_cmd[NODE_ID] == 1`이면 Slave는 기본적으로 침묵한다.
- 단, halt 상태에서 recovery 기능을 추가할 수 있도록 control FSM에 확장 여지를 남긴다.
- `payload[31:0]`은 Slave가 Master로 전달하는 32-bit 비트열이며, 통신 core는 이 값을 해석하지 않는다.
- 세부 모듈 구조와 포트 초안은 `docs/slave_design/00_slave_spec_and_module_structure.md`를 기준으로 한다.

## Master 호환 Slave 응답 Frame

Slave는 자기 slot에서 다음 50-bit NRZ frame을 송신해야 한다.

```text
frame[49:0] = {8'hAA, codeword[41:0]}
```

Hamming codeword는 Master `hamming_dec`와 동일한 systematic SECDED layout이어야 한다.

```text
codeword[41:0] = {data[34:0], p[5:0], p_overall}
data[34:32]    = NODE_ID
data[31:0]     = payload[31:0]
```

송신 순서:

- MSB-first.
- 첫 bit는 `8'hAA`의 MSB인 `1`.
- Master RX는 rising edge가 아니라 `GPIO_in == 1` level로 preamble 수신을 시작하므로, 첫 bit `1`이 중요하다.

## Timing 요구사항

Master의 의도된 slot timing:

```text
data_len_tick = 50 * BIT_DIV
total_tick    = data_len_tick + GUARD_TICKS
normal_done_window:
  data_len_tick + (GUARD_TICKS >> 2)
  <= master clk_cnt <
  total_tick - (GUARD_TICKS >> 2)
```

현재 Master 구현과 Slave 1차 설계는 `total_tick = 50 * BIT_DIV + GUARD_TICKS`를 기준으로 한다. Master 구현자 협의 결과에 따라 향후 `(50 + GUARD_TICKS) * BIT_DIV` 구조로 바뀔 수 있으므로, Slave 구현 source의 slot length 수식 근처에는 이 대안 수식을 주석으로 남긴다.

Slave 송신 시작 시점:

```text
tx_start_tick = GUARD_TICKS_DEFAULT >> 1
```

별도 off-by-one 보정은 적용하지 않는다.

Slave frame 완료 시점은 Master `rx_stat == 0` window에 들어가야 한다.

Master fault 판정:

| Master condition at `in_sig` | Result |
|---|---|
| `rx_stat == 0` and `NODE_ID == slot` | 정상 timing |
| `rx_stat == 1` | weak timing error, `slot_timeout_cnt += 6` |
| `rx_stat == 2` | severe timing error, `slot_timeout_cnt = 255` |
| decoded address != current `slot` | severe timing/address error |

주의:

- Master는 frame 시작 시점이 아니라 frame 완료 pulse인 `in_sig` 시점으로 timing을 판정한다.
- Master source에는 `DIV_p1` 미선언/no-driver 구현 버그가 있었고, `Master_ip/Master_top.v`에서 `DIV_p1 = DIV + 1`로 수정했다.
- Master 담당자 확인상 의도 사양은 `DIV_effective = DIV + 1`이며, `NODE_CNT`는 그대로 쓰는 것이다.
- Slave timing은 버그가 있는 원본 연결이 아니라 확인된 의도 사양을 기준으로 맞춘다.

Slot index:

- `NODE_CNT[2:0]`는 마지막 slot index이며 허용 범위는 `0..7`이다.
- 실제 slot 순환 범위는 `0..NODE_CNT`이다.
- `NODE_ID > NODE_CNT`이면 해당 slave는 TX trigger를 만들지 않는다.

## Master Broadcast 수신 요구사항

Master broadcast frame:

```text
frame = {8'hAA, hamming_enc(master_data[34:0])}
```

현재 Master 구현의 `master_data`:

```text
master_data[34:27] = halt_cmd[7:0]
master_data[26:17] = GUARD_TICKS[9:0]
master_data[16:0]  = 17'b0
```

Slave는 다음을 수행해야 한다.

- `8'hAA` preamble을 검출한다.
- 42-bit codeword를 수신한다.
- Hamming decode를 수행한다.
- `halt_cmd[NODE_ID]`를 추출한다.
- `GUARD_TICKS[9:0]`를 추출하고 내부 보관한다.
- 현재 구현 범위에서는 추출한 `GUARD_TICKS`로 timing을 즉시 재설정하지 않는다.

중요:

- Master broadcast에는 실제 코드상 `DIV`가 포함되지 않는다.
- 따라서 Slave `BIT_DIV`는 parameter/localparam으로 Master와 맞춘다.

## 권장 Parameter

초안:

```verilog
parameter [2:0] NODE_ID = 3'd0;
parameter [9:0] BIT_DIV = 10'd1024;
parameter [9:0] GUARD_TICKS_DEFAULT = 10'd256;
parameter [31:0] PAYLOAD_DEFAULT = 32'd0;
```

`BIT_DIV` 기본값은 `main.c` 사용자값 `DIV=1024`를 기준으로 둔 초안이다. 여기서 `BIT_DIV`는 Master의 의도된 effective bit period, 즉 PS register field `DIV + 1`을 뜻한다.

## Halt 동작 요구사항

확인됨:

- Master는 node별 `halt_cmd`를 broadcast한다.
- `halt_cmd[N]`는 `preamble_err_cnt + slot_timeout_cnt + hamming_err_cnt > FAULT_TH`일 때 1이다.
- `silent_cnt`는 `halt_cmd` 산출에서 제외된다.

확정 정책:

- `halt_cmd[NODE_ID] == 1`이면 slave TX를 정지하고 침묵한다.
- 침묵 상태에서는 Master silent counter가 증가할 수 있다.
- Recovery 기능은 이번 범위에서 구현하지 않지만, `slave_control` FSM에 확장 여지를 남긴다.

## 최소 Module 구조 후보

| Module | Function |
|---|---|
| `slave_hamming_enc` | response frame SECDED encoding |
| `slave_hamming_dec` | master broadcast SECDED decoding |
| `slave_rx` | master broadcast preamble/codeword 수신 |
| `slave_tx` | `{NODE_ID, payload}` response frame 송신 |
| `slave_slot_timer` | local TDMA slot/cycle timer |
| `slave_control` | halt, payload, tx trigger 제어 |
| `slave_top` | parameters and IO integration |

각 module 작성 전에는 AGENTS.md 규칙에 따라 Korean-centered design note를 먼저 작성해야 한다.

## 미확인 항목

- Slave TX line과 Master TX line의 물리적 분리/연결 구조.
- Recovery 기능의 실제 조건과 동작.
- Latched `GUARD_TICKS`를 동적 timing에 반영하는 향후 확장 여부.
