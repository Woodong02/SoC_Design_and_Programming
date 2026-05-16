# DIP 스위치 사양

## 개요

8비트 DIP 스위치(SW1)를 통해 해당 노드의 FlexRay 타임슬롯 번호를 외부에서 설정한다.  
PS가 부팅 시 AXI GPIO IP를 통해 값을 읽고, MBFIDRn의 FID 필드에 써넣는다.

---

## 핀 맵

| 스위치 | Signal Name | FPGA Pin | BANK |
|--------|-------------|----------|------|
| SW1-1 | DIP8_G0 | Y20 | 33 |
| SW1-2 | DIP8_G1 | Y21 | 33 |
| SW1-3 | DIP8_G2 | AB19 | 33 |
| SW1-4 | DIP8_G3 | AB20 | 33 |
| SW1-5 | DIP8_G4 | AA22 | 33 |
| SW1-6 | DIP8_G5 | AB22 | 33 |
| SW1-7 | DIP8_G6 | AA21 | 33 |
| SW1-8 | DIP8_G7 | AB21 | 33 |

---

## 전기적 특성

- **Active Low**: 스위치 ON → 해당 핀 Low (0)
- Pull-up 저항 4.7K 내장 (RP11, RP12)
- 슬롯 번호 설정 범위: 0~255 (8비트)
- FlexRay FID는 11비트이나 DIP 8비트로 충분

---

## 슬롯 번호 매핑

DIP8_G0이 LSB, DIP8_G7이 MSB.

| DIP 상태 (SW1-8 ~ SW1-1) | 읽힌 값 (Active Low 반전 전) | 슬롯 번호 |
|--------------------------|---------------------------|----------|
| 모두 OFF | 0xFF | 0 |
| SW1-1만 ON | 0xFE | 1 |
| SW1-2만 ON | 0xFD | 2 |
| ... | ... | ... |
| 모두 ON | 0x00 | 255 |

---

## PS 처리 방법

```c
uint32_t dip_raw = AXI_GPIO_READ();   // Active Low 원시값
uint8_t slot_id  = (~dip_raw) & 0xFF; // 비트 반전으로 슬롯 번호 추출
MBFIDRn_WRITE(slot_id);               // FlexRay FID에 써넣기
```

---

## 주의사항

- 슬롯 번호는 POC:config 상태에서 MBFIDRn에 써야 한다.
- 런타임 중 DIP 스위치를 변경해도 즉시 반영되지 않는다. 재부팅 또는 재설정 시퀀스가 필요하다.
