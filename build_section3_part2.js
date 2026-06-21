const pptxgen = require("pptxgenjs");

const FONT = "Noto Sans CJK KR";
const C = {
  title: "111111", body: "222222", sub: "666666",
  num: "999999", secBg: "F2F2F2", tblHdr: "2D2D2D"
};
const D = __dirname + "/diagrams/section3/zoom/";

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
function addBulletSlide(s, items) {
  s.addText(items.map((it, i) => ({
    text: it.text,
    options: {
      bullet: true,
      indentLevel: it.level || 0,
      breakLine: i < items.length - 1,
      fontSize: it.level ? 17 : 20,
      color: it.level ? "444444" : C.body,
      paraSpaceAfter: it.level ? 8 : 12
    }
  })), { x: 0.6, y: 1.35, w: 8.8, h: 3.25, fontFace: FONT, valign: "top" });
}
const mkHdr = (t) => ({
  text: t, options: { bold: true, fill: { color: C.tblHdr }, color: "FFFFFF", fontSize: 14, fontFace: FONT }
});

// 텍스트(좌, 짧게) + 이미지(우, 세로로 긴 흐름도) 레이아웃
function addTallFlowSlide(s, bullets, imgPath, ratio) {
  s.addText(bullets.map((t, i) => ({
    text: t,
    options: {
      bullet: true, breakLine: i < bullets.length - 1,
      fontSize: 16, color: C.body, paraSpaceAfter: 8
    }
  })), { x: 0.6, y: 1.35, w: 3.7, h: 3.25, fontFace: FONT, valign: "top" });

  const boxH = 3.5;
  const h = boxH, w = boxH * ratio;
  const x = 4.7 + (4.7 - w) / 2;
  const y = 1.2;
  s.addImage({ path: imgPath, x, y, w, h, sizing: { type: "contain", w, h } });
}

let pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "Master / Slave 내부 동작 검증";

// Slide 1: 섹션 구분
{
  let s = pres.addSlide();
  s.background = { color: C.secBg };
  s.addText("3-2. 내부 동작 검증", {
    x: 0.6, y: 2.0, w: 8.8, h: 1.5,
    fontSize: 40, bold: true, fontFace: FONT,
    color: C.title, align: "left", valign: "middle"
  });
  s.addText("실제 소스코드 기반으로 다중 슬롯·페이로드·동기화·고장처리 동작을 확인한다", {
    x: 0.6, y: 3.4, w: 8.8, h: 0.5,
    fontSize: 18, fontFace: FONT, color: C.sub, align: "left"
  });
  addPageNum(s, 1);
}

// Slide 2: Slave의 멀티 슬롯 시뮬레이션
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 멀티 슬롯 시뮬레이션");
  addBulletSlide(s, [
    { text: "통신 시연에서는 하나의 물리 시퀀서가 8개의 슬롯(슬롯 인덱스 0~7)을 순차 처리 — 슬롯 위치가 식별자 역할을 함" },
    { text: "각 슬롯은 자신의 타임슬롯에서 자신의 payload를 전송 (슬롯별 절대 타겟 틱을 기준으로 순회)" },
    { text: "슬롯 0~5는 AXI 레지스터, 슬롯 6~7은 외부 PL 버스에서 payload를 가져옴" },
    { text: "시연에서는 버튼으로 payload 값을 바꾸고, 변경된 값이 Master에서 정확히 수신되는지 확인" },
  ]);
  addPageNum(s, 2);
}

// Slide 3: Slave의 payload (표)
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 payload");
  s.addText([
    { text: "payload 레지스터는 리셋 시 0으로 초기화", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 10 } },
    { text: "버튼의 디바운스된 단발 펄스마다 슬롯별로 정해진 값만큼 증가", options: { bullet: true, fontSize: 18, color: C.body } },
  ], { x: 0.6, y: 1.3, w: 8.8, h: 0.95, fontFace: FONT, valign: "top" });

  s.addTable([
    [mkHdr("슬롯"), mkHdr("0"), mkHdr("1"), mkHdr("2"), mkHdr("3"), mkHdr("4"), mkHdr("5"), mkHdr("6"), mkHdr("7")],
    ["증가량", "+1", "+2", "+4", "+8", "+16", "+32", "+64", "+128"],
  ], {
    x: 0.6, y: 2.45, w: 8.8,
    fontFace: FONT, fontSize: 14, color: C.body,
    border: { pt: 0.5, color: "CCCCCC" },
    rowH: 0.5,
    align: "center",
  });

  s.addText(
    "32비트 payload는 프레임 내부에서 {slot_id(3bit) + payload(32bit)}로 결합된 뒤 Hamming 인코딩되어 50비트 프레임으로 전송됨",
    { x: 0.6, y: 3.7, w: 8.8, h: 0.7, fontSize: 16, color: "444444", fontFace: FONT, valign: "top" }
  );
  addPageNum(s, 3);
}

// Slide 4: 클럭 동기의 어려움
{
  let s = pres.addSlide();
  addTitle(s, "클럭 동기의 어려움");
  addBulletSlide(s, [
    { text: "Master·Slave는 클럭을 공유하지 않음 — 클럭 오차가 통신에 치명적인 방해 요인" },
    { text: "DIV 값을 AXI 레지스터로 설정해 클럭을 분주, Master·Slave 양쪽에 동일한 DIV 값을 쓴다고 가정" },
    { text: "분주된 비트 구간은 Master가 DIV 클럭, Slave가 (DIV+1) 클럭으로 1클럭만큼 비대칭 — 동일 DIV를 가정해도 실제 주파수는 정확히 같지 않음" },
    { text: "수신 샘플링은 비트 구간의 중간 지점에서 1회만 수행" },
  ]);
  addPageNum(s, 4);
}

// Slide 5: Master의 고장 처리
{
  let s = pres.addSlide();
  addTitle(s, "Master의 고장 처리");
  addBulletSlide(s, [
    { text: "슬롯별 4가지 카운터(preamble_err_cnt, slot_timeout_cnt, hamming_err_cnt, silent_cnt)로 임계치 기반 고장 판정" },
    { text: "slot_timeout_cnt는 심각한 타이밍/주소 불일치 시 즉시 255로 saturate, 약한 가드 경계 오류 시 +6" },
    { text: "판정 임곗값(FAULT_TH, SILENT_TH)은 PS가 AXI 레지스터로 설정" },
    { text: "(preamble_err_cnt + slot_timeout_cnt + hamming_err_cnt) > FAULT_TH 이면 halt_cmd=1 → 동기 프레임에 실어 전송 (silent_cnt는 표시용으로 합산에서 제외)" },
  ]);
  addPageNum(s, 5);
}

// Slide 6: Master 고장 처리 흐름도
{
  let s = pres.addSlide();
  addTitle(s, "Master 고장 처리 흐름도");
  addTallFlowSlide(s, [
    "슬롯마다 프리앰블 → 타이밍 → Hamming 순으로 검사",
    "각 단계의 오류는 해당 카운터를 증가시킴",
    "누적합이 FAULT_TH를 넘으면 halt_cmd=1, 이후 카운터는 동결됨",
    "halt_cmd는 리셋 전까지 유지되며, 취소 경로는 없음",
  ], D + "master_fault_flow.png", 1568 / 4162);
  addPageNum(s, 6);
}

// Slide 7: Slave의 고장 처리
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 고장 처리");
  addBulletSlide(s, [
    { text: "Master broadcast 프레임의 halt_cmd(halt_mask) 필드를 수신하면 해당 슬롯을 active_slot에서 제외 → 그 슬롯의 TX가 발행되지 않음" },
    { text: "Master가 다음 broadcast에서 해당 비트를 0으로 보내면 다음 사이클부터 자동으로 재개 — Slave 쪽에서 재시작을 요청하는 로직은 없음" },
    { text: "Slave 자체 감지 고장(tx_overlap, slot_timing_invalid, pl_payload6/7_invalid, rx_ham_2bit)은 sticky 플래그로 누적되어 PS에 인터럽트만 발생, 자동 셧다운은 하지 않음" },
  ]);
  addPageNum(s, 7);
}

// Slide 8: Slave halt 흐름도
{
  let s = pres.addSlide();
  addTitle(s, "Slave halt 흐름도");
  addTallFlowSlide(s, [
    "Master broadcast에서 halt_mask 추출",
    "슬롯 시퀀서가 active_slot에서 halt된 슬롯을 제외",
    "해당 슬롯은 TX를 발행하지 않음",
    "Master가 비트를 다시 0으로 보내면 자동 재개",
  ], D + "slave_halt_flow.png", 1050 / 3832);
  addPageNum(s, 8);
}

pres.writeFile({ fileName: __dirname + "/section3_part2_internals.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
