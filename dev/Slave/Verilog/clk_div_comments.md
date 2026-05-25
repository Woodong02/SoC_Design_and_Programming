# clk_div.v — 한글 주석 설명서

## 모듈 역할

시스템 클럭(`clk`)을 분주하여 `clk_tick` 펄스를 생성한다.
`clk_tick`은 주기 = `DIV+1` 클럭의 1클럭 폭 펄스다.

TDMA NRZ 비트 주기 = `2*(DIV+1)` 클럭이므로,
`clk_tick` 두 번이 한 비트에 해당한다.

> 현재 구현에서는 `master_rx`, `slave_tx`, `slave_rx`, `master_tx` 모두
> `clk_tick`을 사용하지 않고 `div`를 직접 받아 내부 카운터로 비트 타이밍을 계산한다.
> `clk_div`는 향후 확장을 위해 `tdma_slave_top`에서 인스턴스를 유지한다.

---

## 포트

| 포트 | 방향 | 설명 |
|------|------|------|
| `clk` | 입력 | 시스템 클럭 |
| `rst_n` | 입력 | 비동기 액티브-로우 리셋 |
| `div[9:0]` | 입력 | 분주비. 카운터가 0~DIV를 순환 (주기 = DIV+1 클럭) |
| `clk_tick` | 출력 | 주기 DIV+1 클럭의 1클럭 폭 펄스 |

---

## 로직 설명

```verilog
reg [9:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 10'd0;       // 리셋 시 카운터 초기화
    else if (cnt == div)
        cnt <= 10'd0;       // DIV에 도달하면 0으로 리셋 → 주기 = DIV+1
    else
        cnt <= cnt + 10'd1; // 매 클럭 1씩 증가
end

assign clk_tick = (cnt == div); // cnt가 DIV일 때 1클럭 동안 HIGH
```

- **카운터 범위**: 0, 1, 2, …, DIV, 0, 1, … (총 DIV+1 스텝)
- **clk_tick**: `cnt == div` 조건이 참인 클럭 사이클에서 HIGH
- `div = 3`이면 clk_tick 주기 = 4 클럭, 비트 주기 = 8 클럭

---

## 타이밍 예 (div=3)

```
clk:      ┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─┐_┌─
cnt:       0   1   2   3   0   1   2   3
clk_tick:              H               H
```
