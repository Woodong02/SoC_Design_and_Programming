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
  s.addText("3. Master / Slave 블록도", {
    x: 0.6, y: 2.0, w: 8.8, h: 1.5,
    fontSize: 40, bold: true, fontFace: FONT,
    color: C.title, align: "left", valign: "middle"
  });
  s.addText("보드 내부 구조를 단계적으로 확대해서 살펴본다", {
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
    "구동 중인 Master 값을 주기적으로 읽고, Master가 발생시키는 인터럽트를 수신",
  ], D + "m_ps.png", 1568 / 562);
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
  ], D + "m_masterip.png", 1568 / 416);
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

pres.writeFile({ fileName: __dirname + "/section3_block_diagrams.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
