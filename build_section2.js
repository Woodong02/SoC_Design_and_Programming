const pptxgen = require("pptxgenjs");

const FONT = "Noto Sans CJK KR";
const C = {
  title: "111111", body: "222222", sub: "666666",
  num: "999999", secBg: "F2F2F2", tblHdr: "2D2D2D"
};
const D = __dirname + "/diagrams/";

function addPageNum(slide, n) {
  slide.addText(`${n}`, {
    x: 9.3, y: 5.2, w: 0.5, h: 0.3,
    fontSize: 12, color: C.num, fontFace: FONT, align: "right"
  });
}
function addTitle(slide, text) {
  slide.addText(text, {
    x: 0.6, y: 0.3, w: 8.8, h: 0.85,
    fontSize: 36, bold: true, fontFace: FONT,
    color: C.title, margin: 0
  });
}

let pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "TDMA PHY · Datalink · 프로토콜 정의";

// Slide 1: 섹션 구분
{
  let s = pres.addSlide();
  s.background = { color: C.secBg };
  s.addText("2. TDMA PHY · Datalink · 프로토콜 정의", {
    x: 0.6, y: 2.0, w: 8.8, h: 1.5,
    fontSize: 40, bold: true, fontFace: FONT,
    color: C.title, align: "left", valign: "middle"
  });
  s.addText("프레임 구조부터 동기화, 흐름 제어까지 통신 규약을 설계한다", {
    x: 0.6, y: 3.4, w: 8.8, h: 0.5,
    fontSize: 20, fontFace: FONT, color: C.sub, align: "left"
  });
  addPageNum(s, 1);
}

// Slide 2: TDMA는 PHY와 DLL만 직접 정의한다 (텍스트 전용)
{
  let s = pres.addSlide();
  addTitle(s, "TDMA는 PHY와 DLL만 직접 정의한다");
  s.addText([
    { text: "OSI 7계층 풀스택의 한계", options: { bullet: true, breakLine: true, fontSize: 20, color: C.body, paraSpaceAfter: 12 } },
    { text: "필드 디바이스(센서·액추에이터) 레벨에서는 과도한 지연·오버헤드 유발", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 17, color: "444444", paraSpaceAfter: 8 } },
    { text: "TDMA의 계층 단축", options: { bullet: true, breakLine: true, fontSize: 20, color: C.body, paraSpaceAfter: 12 } },
    { text: "Application이 Data Link Layer에 직접 접근 → PHY, DLL 두 계층만 직접 정의", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 17, color: "444444", paraSpaceAfter: 8 } },
    { text: "이후 PHY → DLL(프레임/MAC/Flow Control) 순으로 차례로 짚어나간다", options: { bullet: true, fontSize: 20, color: C.body } },
  ], { x: 0.6, y: 1.35, w: 8.8, h: 3.25, fontFace: FONT, valign: "top" });
  addPageNum(s, 2);
}

// Slide 3: PHY 정의 (패턴 B - phy_wiring.png, N개 슬레이브 공유 버스, ~1.19:1)
{
  let s = pres.addSlide();
  addTitle(s, "PHY 정의");
  s.addText([
    { text: "연결 구조", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 10 } },
    { text: "GPIO 단자 기반 공유 버스, Master 1 : Slave N (NODE_CNT)", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "라인 코딩", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 10 } },
    { text: "NRZ (Non-Return-to-Zero)", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "배선", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 10 } },
    { text: "TX 1선 + RX 1선 + 공통 GND = 3선 — Slave는 자신의 슬롯에만 TX 구동", options: { bullet: true, indentLevel: 1, fontSize: 16, color: "444444" } },
  ], { x: 0.6, y: 1.35, w: 4.3, h: 3.25, fontFace: FONT, valign: "top" });

  const bw = 4.3, bh = bw * (411 / 491);
  s.addImage({
    path: D + "phy_wiring.png",
    x: 5.1, y: 1.4, w: bw, h: bh,
    sizing: { type: "contain", w: bw, h: bh }
  });
  s.addText("Master ↔ Slave 1..N 공유 버스 배선 구조", {
    x: 5.1, y: 1.4 + bh + 0.08, w: bw, h: 0.3,
    fontSize: 9, color: C.num, fontFace: FONT, align: "center"
  });
  addPageNum(s, 3);
}

// Slide 4: DLL - Slave 프레임 구조 (비트필드: preamble→slot_id→payload→hamming, 전송 순서)
{
  let s = pres.addSlide();
  addTitle(s, "DLL - Slave 프레임 구조");
  s.addText([
    { text: "필드 구성 (총 50비트)", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "preamble(8, 0xAA) + slot_id(3) + payload(32) + hamming parity(7)", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "에러 검출/정정", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "SEC-DED 방식 — 1비트 에러는 검출 후 정정, 2비트 에러는 검출만 가능", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "slot_id의 의미", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "Slave 고유 식별자가 아니라 TDMA 슬롯 번호로 운용됨", options: { bullet: true, indentLevel: 1, fontSize: 16, color: "444444" } },
  ], { x: 0.6, y: 1.35, w: 8.8, h: 2.05, fontFace: FONT, valign: "top" });

  const iw = 8.8, ih = iw * (56 / 800);
  s.addImage({
    path: D + "slave_frame.png",
    x: 0.6, y: 3.55, w: iw, h: ih,
    sizing: { type: "contain", w: iw, h: ih }
  });
  s.addText("Slave 프레임 비트필드 (전송 순서: preamble → slot_id → payload → hamming)", {
    x: 0.6, y: 3.55 + ih + 0.1, w: iw, h: 0.25,
    fontSize: 9, color: C.num, fontFace: FONT, align: "center"
  });
  addPageNum(s, 4);
}

// Slide 5: DLL - Master 프레임 구조
{
  let s = pres.addSlide();
  addTitle(s, "DLL - Master 프레임 구조");
  s.addText([
    { text: "필드 구성", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "preamble(8) + halt_cmd(8) + guard_ticks(10) + reserved(17) + hamming parity(7)", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "halt_cmd", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "Slave별 1비트 마스크 — err_cnt가 임계치(FAULT_TH) 초과 시 해당 비트 set, 고장 Slave 중단 명령", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 16, color: "444444", paraSpaceAfter: 6 } },
    { text: "에러 검출/정정", options: { bullet: true, breakLine: true, fontSize: 19, color: C.body, paraSpaceAfter: 8 } },
    { text: "Slave 프레임과 동일한 SEC-DED 방식 적용", options: { bullet: true, indentLevel: 1, fontSize: 16, color: "444444" } },
  ], { x: 0.6, y: 1.35, w: 8.8, h: 2.25, fontFace: FONT, valign: "top" });

  const iw = 8.8, ih = iw * (56 / 800);
  s.addImage({
    path: D + "master_frame.png",
    x: 0.6, y: 3.7, w: iw, h: ih,
    sizing: { type: "contain", w: iw, h: ih }
  });
  s.addText("Master 프레임 비트필드 (전송 순서: preamble → halt_cmd → guard_ticks → reserved → hamming)", {
    x: 0.6, y: 3.7 + ih + 0.1, w: iw, h: 0.25,
    fontSize: 9, color: C.num, fontFace: FONT, align: "center"
  });
  addPageNum(s, 5);
}

// Slide 6: DLL - MAC: 동기화와 타임슬롯 (½guard - data - ½guard 구조, 3:1 비율 다이어그램)
{
  let s = pres.addSlide();
  addTitle(s, "DLL - MAC: 동기화와 타임슬롯");
  s.addText([
    { text: "Sync 기준점", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 6 } },
    { text: "Master가 매 사이클 마지막 슬롯에서 전송한 sync를 다음 사이클 슬롯 계산 기준점으로 사용", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 15, color: "444444", paraSpaceAfter: 4 } },
    { text: "슬롯 내부 구조", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 6 } },
    { text: "½ guard tick 대기 → 데이터 전송 → ½ guard tick 대기", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 15, color: "444444", paraSpaceAfter: 4 } },
    { text: "Guard Tick의 역할", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 6 } },
    { text: "인접 슬롯의 절반씩이 경계에서 맞물려 슬롯 침범 방지", options: { bullet: true, indentLevel: 1, fontSize: 15, color: "444444" } },
  ], { x: 0.6, y: 1.35, w: 8.8, h: 1.5, fontFace: FONT, valign: "top" });

  const iw = 7.0, ih = iw * (255 / 784);
  s.addImage({
    path: D + "slot_timeline.png",
    x: (10 - iw) / 2, y: 3.0, w: iw, h: ih,
    sizing: { type: "contain", w: iw, h: ih }
  });
  s.addText("Sync → [½G · 데이터 · ½G] × (Slot 0...N) → Sync", {
    x: (10 - iw) / 2, y: 3.0 + ih + 0.1, w: iw, h: 0.25,
    fontSize: 9, color: C.num, fontFace: FONT, align: "center"
  });
  addPageNum(s, 6);
}

// Slide 7: DLL - Flow Control (패턴 B - flow_control.png, 1.38:1)
{
  let s = pres.addSlide();
  addTitle(s, "DLL - Flow Control");
  s.addText([
    { text: "1비트 에러", options: { bullet: true, breakLine: true, fontSize: 20, color: C.body, paraSpaceAfter: 12 } },
    { text: "Hamming으로 정정하여 정상 데이터로 사용", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 17, color: "444444", paraSpaceAfter: 8 } },
    { text: "2비트 에러 (정정 불가)", options: { bullet: true, breakLine: true, fontSize: 20, color: C.body, paraSpaceAfter: 12 } },
    { text: "해당 프레임을 무효 처리하고 폐기, 이전 값 유지", options: { bullet: true, indentLevel: 1, breakLine: true, fontSize: 17, color: "444444", paraSpaceAfter: 8 } },
    { text: "Implicit Flow Control", options: { bullet: true, breakLine: true, fontSize: 20, color: C.body, paraSpaceAfter: 12 } },
    { text: "명시적 재전송 요청(ARQ/NACK) 없음 — 다음 TDMA 사이클의 갱신 데이터를 기다림", options: { bullet: true, indentLevel: 1, fontSize: 17, color: "444444" } },
  ], { x: 0.6, y: 1.35, w: 4.4, h: 3.25, fontFace: FONT, valign: "top" });

  const bw = 3.5, bh = bw * (424 / 585);
  s.addImage({
    path: D + "flow_control.png",
    x: 5.5, y: 1.5, w: bw, h: bh,
    sizing: { type: "contain", w: bw, h: bh }
  });
  addPageNum(s, 7);
}

pres.writeFile({ fileName: __dirname + "/section2_tdma_protocol.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
