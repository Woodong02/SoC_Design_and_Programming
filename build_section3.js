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

// 텍스트(상) + 이미지(하, 가로로 넓은 흐름도) 레이아웃
function addBottomFlowSlide(s, bullets, imgPath, ratio) {
  s.addText(bullets.map((t, i) => ({
    text: t,
    options: {
      bullet: true, breakLine: i < bullets.length - 1,
      fontSize: 16, color: C.body, paraSpaceAfter: 6
    }
  })), { x: 0.6, y: 1.3, w: 8.8, h: 0.75, fontFace: FONT, valign: "top" });

  const boxW = 8.8, boxH = 2.9, boxRatio = boxW / boxH;
  let w, h;
  if (ratio >= boxRatio) { w = boxW; h = boxW / ratio; }
  else { h = boxH; w = boxH * ratio; }
  const x = 0.6 + (boxW - w) / 2;
  const y = 2.1 + (boxH - h) / 2;
  s.addImage({ path: imgPath, x, y, w, h, sizing: { type: "contain", w, h } });
}

// 텍스트(상) + 이미지(하, 가로 폭 위주) 레이아웃 — 가로로 넓은 다이어그램용
function addBottomImageSlide(s, bullets, imgPath, ratio) {
  s.addText(bullets.map((t, i) => ({
    text: t,
    options: {
      bullet: true, breakLine: i < bullets.length - 1,
      fontSize: 17, color: C.body, paraSpaceAfter: 6
    }
  })), { x: 0.6, y: 1.3, w: 8.8, h: 0.65, fontFace: FONT, valign: "top" });

  const boxW = 8.8, boxH = 3.0, boxRatio = boxW / boxH;
  let w, h;
  if (ratio >= boxRatio) { w = boxW; h = boxW / ratio; }
  else { h = boxH; w = boxH * ratio; }
  const x = 0.6 + (boxW - w) / 2;
  const y = 1.95 + (boxH - h) / 2;
  s.addImage({ path: imgPath, x, y, w, h, sizing: { type: "contain", w, h } });
}

// 텍스트(좌) + 이미지(우) 레이아웃 — 가로세로 비율이 완만한 다이어그램용
function addSideImageSlide(s, bullets, imgPath, ratio) {
  s.addText(bullets.map((t, i) => ({
    text: t,
    options: {
      bullet: true, breakLine: i < bullets.length - 1,
      fontSize: 18, color: C.body, paraSpaceAfter: 10
    }
  })), { x: 0.6, y: 1.35, w: 4.4, h: 3.25, fontFace: FONT, valign: "top" });

  const boxW = 4.1, boxH = 3.25;
  const w = boxW, h = boxW / ratio;
  const x = 5.3;
  const y = 1.35 + (boxH - h) / 2;
  s.addImage({ path: imgPath, x, y, w, h, sizing: { type: "contain", w, h } });
}

let pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "Master / Slave 블록도";

// Slide 1: 섹션 구분
{
  let s = pres.addSlide();
  s.background = { color: C.secBg };
  s.addText("3. Master / Slave 구현 사항", {
    x: 0.6, y: 2.0, w: 8.8, h: 1.5,
    fontSize: 40, bold: true, fontFace: FONT,
    color: C.title, align: "left", valign: "middle"
  });
  s.addText("하드웨어 블록 구성부터 고장 처리 로직까지 구현 세부사항을 짚는다", {
    x: 0.6, y: 3.4, w: 8.8, h: 0.5,
    fontSize: 20, fontFace: FONT, color: C.sub, align: "left"
  });
  addPageNum(s, 1);
}

// Slide 2: Master 전체 구조
{
  let s = pres.addSlide();
  addTitle(s, "Master 전체 구조");
  addBottomImageSlide(s, [
    "테스트 장치 · PS · PL(Master IP 포함) · GPIO 네 영역으로 구성",
    "GPIO를 통해 Slave와 TX/RX 시리얼로 연결 — 이후 슬라이드에서 블록을 하나씩 확대",
  ], D + "master_overview.png", 1568 / 426);
  addPageNum(s, 2);
}

// Slide 3: Master - GPIO 확대
{
  let s = pres.addSlide();
  addTitle(s, "Master - GPIO 확대");
  addSideImageSlide(s, [
    "GND / RX 포트 / TX 포트로 구성",
    "TX·RX는 PL(Master IP)과 Slave 사이를 잇는 물리 연결 — 외부 장치-PS-PL 경로와는 분리된 통신 채널",
  ], D + "m_gpio.png", 1568 / 672);
  addPageNum(s, 3);
}

// Slide 4: Master - PS 확대
{
  let s = pres.addSlide();
  addTitle(s, "Master - PS 확대");
  addBottomImageSlide(s, [
    "외부 테스트 장치에서 초깃값을 입력받아 Master를 초기 구동",
    "구동 중인 Master 값을 레지스터로 읽고, Master가 발생시키는 인터럽트를 수신",
  ], D + "m_ps.png", 1568 / 620);
  addPageNum(s, 4);
}

// Slide 5: Master - PL 확대
{
  let s = pres.addSlide();
  addTitle(s, "Master - PL 확대");
  addSideImageSlide(s, [
    "LED · 푸시버튼 · DIP 스위치 · 7-seg와 Master IP로 보드 자체의 입출력 구성",
    "LED는 RX/TX 이진 신호를 그대로 받아 통신 상태를 표시",
    "DIP 스위치·7-seg는 슬롯별 통신 상태와 수신 데이터를 출력 — Master IP가 이들을 조율",
  ], D + "m_pl.png", 1568 / 892);
  addPageNum(s, 5);
}

// Slide 6: Master - Master IP 확대
{
  let s = pres.addSlide();
  addTitle(s, "Master - Master IP 확대");
  addBottomImageSlide(s, [
    "PS에서 설정값을 받아 동기 메시지를 송신, 각 Slave의 응답을 수신",
    "에러·데이터 전송 여부·형식·슬롯 침범 여부를 확인해 내부에서 고장 처리 후 PS에 보고",
  ], D + "m_masterip.png", 1568 / 358);
  addPageNum(s, 6);
}

// Slide 7: Slave 전체 구조
{
  let s = pres.addSlide();
  addTitle(s, "Slave 전체 구조");
  addBottomImageSlide(s, [
    "GPIO · PL(Slave IP 포함) 두 영역으로 구성",
    "GPIO를 통해 Master와 TX/RX 시리얼로 연결",
  ], D + "slave_overview.png", 1142 / 398);
  addPageNum(s, 7);
}

// Slide 8: Slave - GPIO 확대
{
  let s = pres.addSlide();
  addTitle(s, "Slave - GPIO 확대");
  addSideImageSlide(s, [
    "GND / RX 포트 / TX 포트로 구성",
    "RX·TX는 LED에 직결되어 통신 상태를 표시 (Master와 표현 통일)",
  ], D + "s_gpio.png", 1568 / 922);
  addPageNum(s, 8);
}

// Slide 9: Slave - PL 확대
{
  let s = pres.addSlide();
  addTitle(s, "Slave - PL 확대");
  addSideImageSlide(s, [
    "LED와 Slave IP로 구성",
    "구조는 단순하지만 일관성을 위해 동일하게 확대해서 표시",
  ], D + "s_pl.png", 904 / 596);
  addPageNum(s, 9);
}

// Slide 10: Slave - Slave IP 확대
{
  let s = pres.addSlide();
  addTitle(s, "Slave - Slave IP 확대");
  addBottomImageSlide(s, [
    "Master의 동기 메시지를 받으면 자신의 슬롯 시간대를 계산해 적시에 메시지를 전송",
    "Master가 송신 중단을 명령하면 송신을 중지하는 등 고장 처리를 수행",
  ], D + "s_slaveip.png", 1568 / 562);
  addPageNum(s, 10);
}

// Slide 11: Slave의 멀티 슬롯 시뮬레이션
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 멀티 슬롯 시뮬레이션");
  addBulletSlide(s, [
    { text: "통신 시연에서는 하나의 물리 시퀀서가 8개의 슬롯(슬롯 인덱스 0~7)을 순차 처리 — 슬롯 위치가 식별자 역할을 함" },
    { text: "각 슬롯은 자신의 타임슬롯에서 자신의 payload를 전송 (슬롯별 절대 타겟 틱을 기준으로 순회)" },
    { text: "슬롯 0~5는 AXI 레지스터, 슬롯 6~7은 외부 PL 버스에서 payload를 가져옴" },
    { text: "시연에서는 버튼으로 payload 값을 바꾸고, 변경된 값이 Master에서 정확히 수신되는지 확인" },
  ]);
  addPageNum(s, 11);
}

// Slide 12: Slave의 payload (표)
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 payload");
  s.addText([
    { text: "payload 레지스터는 리셋 시 0으로 초기화", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 10 } },
    { text: "버튼을 누를 때마다 슬롯별로 정해진 값만큼 증가", options: { bullet: true, fontSize: 18, color: C.body } },
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

  addPageNum(s, 12);
}

// Slide 13: Master의 고장 처리
{
  let s = pres.addSlide();
  addTitle(s, "Master의 고장 처리");
  addBulletSlide(s, [
    { text: "슬롯별 4가지 카운터(preamble_err_cnt, slot_timeout_cnt, hamming_err_cnt, silent_cnt)로 임계치 기반 고장 판정" },
    { text: "slot_timeout_cnt는 심각한 타이밍/주소 불일치 시 즉시 255로 saturate, 약한 가드 경계 오류 시 +6" },
    { text: "판정 임곗값(FAULT_TH, SILENT_TH)은 PS가 AXI 레지스터로 설정" },
    { text: "(preamble_err_cnt + slot_timeout_cnt + hamming_err_cnt) > FAULT_TH 이면 halt_cmd=1 → 동기 프레임에 실어 전송 (silent_cnt는 표시용으로 합산에서 제외)" },
  ]);
  addPageNum(s, 13);
}

// Slide 14: Master의 고장 처리 흐름도
{
  let s = pres.addSlide();
  addTitle(s, "Master의 고장 처리 흐름도");
  addBottomFlowSlide(s, [
    "슬롯마다 프리앰블 → Hamming → 타이밍(clk_cnt/slot 비교) 순으로 검사",
    "각 단계의 오류는 해당 카운터를 증가시킴",
    "누적합이 FAULT_TH를 넘으면 halt_cmd=1, 이후 카운터는 동결됨",
    "halt_cmd는 리셋 전까지 유지되며, 취소 경로는 없음",
  ], D + "master_fault_flow.png", 1568 / 594);
  addPageNum(s, 14);
}

// Slide 15: Slave의 고장 처리
{
  let s = pres.addSlide();
  addTitle(s, "Slave의 고장 처리");
  addBulletSlide(s, [
    { text: "Master broadcast 프레임의 halt_cmd 필드를 수신하면 해당 슬롯은 송신 중단" },
    { text: "Master가 다음 broadcast에서 해당 비트를 0으로 보내면 다음 사이클부터 자동으로 재개" },
    { text: "Slave 자체 감지 고장(tx_overlap, slot_timing_invalid, pl_payload6/7_invalid, rx_ham_2bit)은 플래그로 누적되어 인터럽트 신호만 발생, 별도 조치는 없음" },
  ]);
  addPageNum(s, 15);
}

pres.writeFile({ fileName: __dirname + "/section3_block_diagrams.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
