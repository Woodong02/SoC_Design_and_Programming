# light_sensor IP

## 개요

조도 센서 값을 읽어 32비트 데이터로 출력하는 IP. FlexRay 버스를 통해 연결된다.

---

## 레지스터 맵

| 오프셋 | 이름 | R/W | 설명 |
|---|---|---|---|
| 0x00 | DATA | R | 조도 센서 32비트 읽기값 |
| 0x04 | CTRL | R/W | 제어 레지스터 1 (Reserved) |
| 0x08 | CTRL2 | R/W | 제어 레지스터 2 (Reserved) |
| 0x0C | CTRL3 | R/W | 제어 레지스터 3 (Reserved) |

---

## 비트필드

### 0x00 DATA (R)

| 비트 | 이름 | 설명 |
|---|---|---|
| [31:0] | DATA | 조도 센서 읽기값 |

### 0x04 CTRL (R/W)

Reserved

### 0x08 CTRL2 (R/W)

Reserved

### 0x0C CTRL3 (R/W)

Reserved
