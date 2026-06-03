# `slave2_top` full serial 검증 노트

## 목적

`tb_slave2_top_full_serial`은 `slave2_top`에 실제 Master broadcast serial frame을 넣고, RX decode, control state, timebase status, TX response frame을 end-to-end로 확인한다.

이 검증은 smoke test와 달리 `slave2_rx` 내부 신호를 force하지 않는다.

## 대상

- `Slave_ip/v2_0/slave2_line_sync.v`
- `Slave_ip/v2_0/slave2_rx.v`
- `Slave_ip/v2_0/slave2_timebase.v`
- `Slave_ip/v2_0/slave2_tx.v`
- `Slave_ip/v2_0/slave2_top.v`
- 1.0 재사용: `slave_hamming_enc`, `slave_hamming_dec`, `slave_control`

## 검증 범위

- reset 후 idle 상태
- valid broadcast 수신 및 guard latch
- clear halt broadcast 후 response frame decode
- halt broadcast 후 TX silence
- halt clear 후 새 payload response
- corrupt preamble이 control state/guard를 변경하지 않는지 확인

## 판정 정책

이 테스트는 가혹 환경 테스트가 아니다. 실패는 RTL 또는 TB 오류로 보고 수정 대상이다.

