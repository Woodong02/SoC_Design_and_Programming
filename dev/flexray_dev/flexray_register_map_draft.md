# FlexRay IP 레지스터 맵 초안

> MFR4310RM 기준. 32비트 정렬, 하위 16비트만 유효.  
> 비트 31–16: 항상 0 (reserved)  
> NXP 원본 주소 = 본 주소의 절반값

---

## 레지스터 주소 맵

| 주소 (32bit) | NXP 원본 | 레지스터 | 접근 |
|-------------|---------|----------|------|
| 0x0004 | 0x0002 | MCR | R/W |
| 0x0028 | 0x0014 | POCR | R/W |
| 0x002C | 0x0016 | GIFER | R/W |
| 0x0030 | 0x0018 | PIFR0 | R/W |
| 0x0038 | 0x001C | PIER0 | R/W |
| 0x0050 | 0x0028 | PSR0 | R |
| 0x0054 | 0x002A | PSR1 | R/W |
| 0x0058 | 0x002C | PSR2 | R |
| 0x0060 | 0x0030 | MTCTR | R |
| 0x0064 | 0x0032 | CYCTR | R |
| 0x0068 | 0x0034 | SLTCTAR | R |
| 0x0070 | 0x0038 | RTCORVR | R |
| 0x0074 | 0x003A | OFCORVR | R |
| 0x0078 | 0x003C | CIFRR | R |
| 0x00C8 | 0x0064 | SSSR | R/W |
| 0x00CC | 0x0066 | SSCCR | R/W |
| 0x00D0 | 0x0068 | SSR0 | R |
| 0x00D4 | 0x006A | SSR1 | R |
| 0x00D8 | 0x006C | SSR2 | R |
| 0x00DC | 0x006E | SSR3 | R |
| 0x00E0 | 0x0070 | SSR4 | R |
| 0x00E4 | 0x0072 | SSR5 | R |
| 0x00E8 | 0x0074 | SSR6 | R |
| 0x00EC | 0x0076 | SSR7 | R |
| 0x00F0 | 0x0078 | SSCR0 | R |
| 0x00F4 | 0x007A | SSCR1 | R |
| 0x00F8 | 0x007C | SSCR2 | R |
| 0x00FC | 0x007E | SSCR3 | R |
| 0x0140 | 0x00A0 | PCR0 | R/W |
| 0x0144 | 0x00A2 | PCR1 | R/W |
| 0x0148 | 0x00A4 | PCR2 | R/W |
| 0x014C | 0x00A6 | PCR3 | R/W |
| 0x0150 | 0x00A8 | PCR4 | R/W |
| 0x0168 | 0x00B4 | PCR10 | R/W |
| 0x0170 | 0x00B8 | PCR12 | R/W |
| 0x0180 | 0x00C0 | PCR16 | R/W |
| 0x0194 | 0x00CA | PCR21 | R/W |
| 0x0198 | 0x00CC | PCR22 | R/W |
| 0x01B4 | 0x00DA | PCR29 | R/W |
| 0x0200 + n×0x10 | 0x0100 + n×0x08 | MBCCSRn (n=0~127) | R/W |
| 0x0204 + n×0x10 | 0x0102 + n×0x08 | MBCCFRn (n=0~127) | R/W |
| 0x0208 + n×0x10 | 0x0104 + n×0x08 | MBFIDRn (n=0~127) | R/W |

> PCR: POC:config 상태에서만 쓰기 가능  
> MBCCSRn/MBCCFRn/MBFIDRn: POC:config 또는 MB_DIS 상태에서 쓰기 가능

---

## 비트 필드

---

### MCR — Module Configuration Register (NXP p.70)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | MEN | Module Enable |
| 13 | SCM | Single Channel Mode |
| 12 | CHB | Channel B Enable |
| 11 | CHA | Channel A Enable |
| 10 | SFFE | Sync Frame Filter Enable |
| 3–1 | BITRATE | FlexRay Bus Bit Rate |

---

### POCR — Protocol Operation Control Register (NXP p.77)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | WME | Write Mode External Correction |
| 11–10 | EOC_AP | External Offset Correction Application |
| 9–8 | ERC_AP | External Rate Correction Application |
| 7 | BSY | Protocol Control Command Write Busy |
| 6 | WMC | Write Mode Command |
| 3–0 | POCCMD | Protocol Control Command |

---

### GIFER — Global Interrupt Flag and Enable Register (NXP p.78)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | MIF | Module Interrupt Flag |
| 13 | PRIF | Protocol Interrupt Flag |
| 13 | CHIF | CHI Interrupt Flag (PRIF와 비트 공유, PDF 원본 동일) |
| 12 | WUPIF | Wakeup Interrupt Flag |
| 11 | FNEBIF | Receive FIFO B Not Empty Flag |
| 10 | FNEAIF | Receive FIFO A Not Empty Flag |
| 9 | RBIF | Receive Buffer Interrupt Flag |
| 8 | TBIF | Transmit Buffer Interrupt Flag |
| 7 | MIE | Module Interrupt Enable |
| 6 | PRIE | Protocol Interrupt Enable |
| 5 | CHIE | CHI Interrupt Enable |
| 4 | WUPIE | Wakeup Interrupt Enable |
| 3 | FNEBIE | Receive FIFO B Not Empty Enable |
| 2 | FNEAIE | Receive FIFO A Not Empty Enable |
| 1 | RBIE | Receive Buffer Interrupt Enable |
| 0 | TBIE | Transmit Interrupt Enable |

---

### PIFR0 — Protocol Interrupt Flag Register 0 (NXP p.81)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | FATL_IF | Fatal Protocol Error |
| 14 | INTL_IF | Internal Protocol Error |
| 13 | ILCF_IF | Illegal Protocol Configuration |
| 12 | CSA_IF | Cold Start Abort |
| 11 | MRC_IF | Missing Rate Correction |
| 10 | MOC_IF | Missing Offset Correction |
| 9 | CCL_IF | Clock Correction Limit Reached |
| 8 | MXS_IF | Max Sync Frames Detected |
| 7 | MTX_IF | MTS Received |
| 6 | LTXB_IF | pLatestTx Violation Ch B |
| 5 | LTXA_IF | pLatestTx Violation Ch A |
| 4 | TBVB_IF | Transmission across Boundary Ch B |
| 3 | TBVA_IF | Transmission across Boundary Ch A |
| 2 | TI2_IF | Timer 2 Expired (타이머 미사용, Reserved) |
| 1 | TI1_IF | Timer 1 Expired (타이머 미사용, Reserved) |
| 0 | CYS_IF | Cycle Start |

---

### PIER0 — Protocol Interrupt Enable Register 0 (NXP p.84)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | FATL_IE | Fatal Protocol Error IE |
| 14 | INTL_IE | Internal Protocol Error IE |
| 13 | ILCF_IE | Illegal Protocol Configuration IE |
| 12 | CSA_IE | Cold Start Abort IE |
| 11 | MRC_IE | Missing Rate Correction IE |
| 10 | MOC_IE | Missing Offset Correction IE |
| 9 | CCL_IE | Clock Correction Limit Reached IE |
| 8 | MXS_IE | Max Sync Frames Detected IE |
| 7 | MTX_IE | MTS Received IE |
| 6 | LTXB_IE | pLatestTx Violation Ch B IE |
| 5 | LTXA_IE | pLatestTx Violation Ch A IE |
| 4 | TBVB_IE | Transmission across Boundary Ch B IE |
| 3 | TBVA_IE | Transmission across Boundary Ch A IE |
| 2 | TI2_IE | Timer 2 IE (타이머 미사용, Reserved) |
| 1 | TI1_IE | Timer 1 IE (타이머 미사용, Reserved) |
| 0 | CYS_IE | Cycle Start IE |

---

### PSR0 — Protocol Status Register 0 (NXP p.90)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–14 | ERRMODE | Error Mode |
| 13–12 | SLOTMODE | Slot Mode |
| 10–8 | PROTSTATE | Protocol State |
| 7–4 | STARTUPSTATE | Startup State |
| 2–0 | WAKEUPSTATUS | Wakeup Status |

---

### PSR1 — Protocol Status Register 1 (NXP p.91)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | CSAA | Cold Start Attempt Aborted Flag |
| 14 | CSP | Leading Cold Start Path |
| 12–8 | REMCSAT | Remaining Coldstart Attempts |
| 7 | CPN | Leading Cold Start Path Noise |
| 6 | HHR | Host Halt Request Pending |
| 5 | FRZ | Freeze Occurred |
| 4–0 | APTAC | Allow Passive to Active Counter |

---

### PSR2 — Protocol Status Register 2 (NXP p.92)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | NBVB | NIT Boundary Violation Ch B |
| 14 | NSEB | NIT Syntax Error Ch B |
| 13 | STCB | Symbol Window Tx Conflict Ch B |
| 12 | SBVB | Symbol Window Boundary Violation Ch B |
| 11 | SSEB | Symbol Window Syntax Error Ch B |
| 10 | MTB | MTS Received Ch B |
| 9 | NBVA | NIT Boundary Violation Ch A |
| 8 | NSEA | NIT Syntax Error Ch A |
| 7 | STCA | Symbol Window Tx Conflict Ch A |
| 6 | SBVA | Symbol Window Boundary Violation Ch A |
| 5 | SSEA | Symbol Window Syntax Error Ch A |
| 4 | MTA | MTS Received Ch A |
| 3–0 | CLKCORRFAILCNT | Clock Correction Failed Counter |

---

### MTCTR — Macrotick Counter Register (NXP p.96)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 13–0 | MTCT | Macrotick Counter (vMacrotick) |

---

### CYCTR — Cycle Counter Register (NXP p.96)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 5–0 | CYCCNT | Cycle Counter (vCycleCounter, 0~63) |

---

### SLTCTAR — Slot Counter Channel A Register (NXP p.97)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 10–0 | SLOTCNTA | Slot Counter Value for Channel A |

---

### RTCORVR — Rate Correction Value Register (NXP p.97)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–0 | RATECORR | Rate Correction Value (μT, 2's complement) |

---

### OFCORVR — Offset Correction Value Register (NXP p.98)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–0 | OFFSETCORR | Offset Correction Value (μT, 2's complement) |

---

### CIFRR — Combined Interrupt Flag Register (NXP p.98)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 7 | MIF | Module Interrupt Flag (OR of all) |
| 6 | PRIF | Protocol Interrupt Flag |
| 5 | CHIF | CHI Interrupt Flag |
| 4 | WUPIF | Wakeup Interrupt Flag |
| 3 | FNEBIF | FIFO B Not Empty |
| 2 | FNEAIF | FIFO A Not Empty |
| 1 | RBIF | Receive Buffer Interrupt Flag |
| 0 | TBIF | Transmit Buffer Interrupt Flag |

---

### SSSR — Slot Status Selection Register (NXP p.108)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | WMD | Write Mode |
| 13–12 | SEL | Selector (SSSR0~3 중 선택) |
| 10–0 | SLOTNUMBER | 모니터링할 슬롯 번호 |

---

### SSCCR — Slot Status Counter Condition Register (NXP p.109)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | WMD | Write Mode |
| 13–12 | SEL | Selector (SSCCR0~3 중 선택) |
| 10–9 | CNTCFG | Counter Configuration (채널 조건) |
| 8 | MCY | Multi Cycle Selection |
| 7 | VFR | Valid Frame Restriction |
| 6 | SYF | Sync Frame Restriction |
| 5 | NUF | Null Frame Restriction |
| 4 | SUF | Startup Frame Restriction |
| 3–0 | STATUSMASK | Slot Status Error Mask |

---

### SSR0~SSR7 — Slot Status Registers (NXP p.111)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | VFB | Valid Frame Ch B |
| 14 | SYB | Sync Frame Indicator Ch B |
| 13 | NFB | Null Frame Indicator Ch B |
| 12 | SUB | Startup Frame Indicator Ch B |
| 11 | SEB | Syntax Error Ch B |
| 10 | CEB | Content Error Ch B |
| 9 | BVB | Boundary Violation Ch B |
| 8 | TCB | Transmission Conflict Ch B |
| 7 | VFA | Valid Frame Ch A |
| 6 | SYA | Sync Frame Indicator Ch A |
| 5 | NFA | Null Frame Indicator Ch A |
| 4 | SUA | Startup Frame Indicator Ch A |
| 3 | SEA | Syntax Error Ch A |
| 2 | CEA | Content Error Ch A |
| 1 | BVA | Boundary Violation Ch A |
| 0 | TCA | Transmission Conflict Ch A |

---

### SSCR0~SSCR3 — Slot Status Counter Registers (NXP p.112)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–0 | SLOTSTATUSCNT | Slot Status Counter Value |

---

### PCR0 — Protocol Configuration Register 0 (NXP p.123)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | action_point_offset | gdActionPointOffset - 1 (MT) |
| 10–0 | static_slot_length | gdStaticSlot (MT) |

---

### PCR1 — Protocol Configuration Register 1 (NXP p.123)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 13–0 | macro_after_first_static_slot | gMacroPerCycle - gdStaticSlot (MT) |

---

### PCR2 — Protocol Configuration Register 2 (NXP p.123)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | minislot_after_action_point | gdMinislot - gdMinislotActionPointOffset - 1 (MT) |
| 10–0 | number_of_static_slots | gNumberOfStaticSlots |

---

### PCR3 — Protocol Configuration Register 3 (NXP p.124)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | wakeup_symbol_rx_low | gdWakeupSymbolRxLow (gdBit) |
| 10–6 | minislot_action_point_offset | gdMinislotActionPointOffset - 1 (MT) |
| 5–0 | coldstart_attempts | gColdstartAttempts |

---

### PCR4 — Protocol Configuration Register 4 (NXP p.124)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–9 | cas_rx_low_max | gdCASRxLowMax - 1 (gdBit) |
| 8–0 | wakeup_symbol_rx_window | gdWakeupSymbolRxWindow (gdBit) |

---

### PCR10 — Protocol Configuration Register 10 (NXP p.125)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | single_slot_enabled | pSingleSlotEnabled |
| 14 | wakeup_channel | pWakeupChannel |
| 13–0 | macro_per_cycle | gMacroPerCycle (MT) |

---

### PCR12 — Protocol Configuration Register 12 (NXP p.126)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | allow_passive_to_active | pAllowPassiveToActive (cyclepairs) |
| 10–0 | key_slot_header_crc | Header CRC for key slot |

---

### PCR16 — Protocol Configuration Register 16 (NXP p.126)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–9 | macro_initial_offset_b | pMacroInitialOffset[B] (MT) |
| 8–0 | noise_listen_timeout[24:16] | (gListenNoise × pdListenTimeout) - 1 상위 비트 (μT) |

---

### PCR21 — Protocol Configuration Register 21 (NXP p.127)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | extern_rate_correction | pExternRateCorrection (μT) |
| 10–0 | latest_tx | gNumberOfMinislots - pLatestTx (minislot) |

---

### PCR22 — Protocol Configuration Register 22 (NXP p.128)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 14–5 | comp_accepted_startup_range_a | pdAcceptedStartupRange - pDelayCompensationChA (μT) |
| 3–0 | micro_per_cycle[19:16] | pMicroPerCycle 상위 비트 (μT) |

---

### PCR29 — Protocol Configuration Register 29 (NXP p.129)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15–11 | extern_offset_correction | pExternOffsetCorrection (μT) |
| 10–0 | minislots_max | gNumberOfMinislots - 1 (minislot) |

---

### MBCCSRn — Message Buffer Configuration, Control, Status Register (NXP p.130)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 14 | MCM | Message Buffer Commit Mode |
| 13 | MBT | Message Buffer Type (single/double) |
| 12 | MTD | Message Buffer Transfer Direction (RX/TX) |
| 11 | CMT | Commit for Transmission |
| 10 | EDT | Enable/Disable Trigger |
| 9 | LCKT | Lock/Unlock Trigger |
| 8 | MBIE | Message Buffer Interrupt Enable |
| 4 | DUP | Data Updated |
| 3 | DVAL | Data Valid |
| 2 | EDS | Enable/Disable Status |
| 1 | LCKS | Lock Status |
| 0 | MBIF | Message Buffer Interrupt Flag |

---

### MBCCFRn — Message Buffer Cycle Counter Filter Register (NXP p.132)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 15 | MTM | Message Buffer Transmission Mode |
| 14 | CHA | Channel A Assignment |
| 13 | CHB | Channel B Assignment |
| 12 | CCFE | Cycle Counter Filtering Enable |
| 11–6 | CCFMSK | Cycle Counter Filtering Mask |
| 5–0 | CCFVAL | Cycle Counter Filtering Value |

---

### MBFIDRn — Message Buffer Frame ID Register (NXP p.133)

| 비트[15:0] | 필드 | 설명 |
|-----------|------|------|
| 10–0 | FID | Frame ID (슬롯 번호) |
