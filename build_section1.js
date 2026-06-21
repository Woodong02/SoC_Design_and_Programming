const pptxgen = require("pptxgenjs");

const FONT = "Noto Sans CJK KR";
const C = {
  title: "111111", body: "222222", sub: "666666",
  num: "999999", secBg: "F2F2F2", tblHdr: "2D2D2D"
};

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

let pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "TDMA 기반 Master-Slave 통신 SoC 구현";

// Slide 1: 타이틀
{
  let s = pres.addSlide();
  s.addText("TDMA 기반 Master-Slave 통신 SoC 구현", {
    x: 0.6, y: 1.7, w: 8.8, h: 1.3,
    fontSize: 40, bold: true, fontFace: FONT, color: C.title, align: "left", valign: "top"
  });
  s.addText("Safety-Critical 통신을 위한 결정론적 시간 분할 접근", {
    x: 0.6, y: 3.05, w: 8.8, h: 0.65,
    fontSize: 20, fontFace: FONT, color: C.sub, align: "left"
  });
  s.addText("9조 (정신수, 우동엽)", {
    x: 0.6, y: 4.07, w: 8.8, h: 0.65,
    fontSize: 20, fontFace: FONT, color: C.sub, align: "left"
  });
  addPageNum(s, 1);
}

// Slide 2: 왜 결정론적 통신이 필요한가
{
  let s = pres.addSlide();
  addTitle(s, "왜 결정론적 통신이 필요한가");
  addBulletSlide(s, [
    { text: "RT·안전-critical 통신 시스템의 요구사항" },
    { text: "예측 가능성(Predictability) — 시스템의 시간적 동작이 사전에 보장되어야 함", level: 1 },
    { text: "결정성(Determinism) — 메시지 수신 시점이 미리 알려져 있어야 함", level: 1 },
    { text: "사건 기반(Event-Triggered) 통신의 한계" },
    { text: "충돌과 재전송으로 지연이 랜덤하게 변동 → 예측 불가", level: 1 },
    { text: "자동차·산업용 네트워크에서는 이 불확실성이 곧 안전 문제로 직결", level: 1 },
  ]);
  addPageNum(s, 2);
}

// Slide 3: 해법: 시간을 나누어 전송한다
{
  let s = pres.addSlide();
  addTitle(s, "해법: 시간을 나누어 전송한다");
  addBulletSlide(s, [
    { text: "시간 슬롯 사전 할당" },
    { text: "각 노드에 전용 시간 구간을 미리 배정 → 충돌이 원천적으로 발생하지 않음", level: 1 },
    { text: "메시지 지연이 통신 전에 이미 결정됨 (Bounded Latency)", level: 1 },
    { text: "TDMA (Time Division Multiple Access)" },
    { text: "이러한 시간 분할 통신 방식을 지칭하는 용어", level: 1 },
  ]);
  addPageNum(s, 3);
}

// Slide 4: 본 프로젝트의 목표
{
  let s = pres.addSlide();
  addTitle(s, "본 프로젝트의 목표");
  addBulletSlide(s, [
    { text: "TDMA 원리를 SoC 레벨에서 직접 구현" },
    { text: "Master-Slave 구조로 시간 슬롯 동기화 및 통신 회로를 하드웨어로 설계", level: 1 },
    { text: "실제 하드웨어 타이밍 제약 하에서 동작 검증 및 시연" },
    { text: "이론상의 결정론적 통신이 실제 회로에서도 성립함을 확인", level: 1 },
  ]);
  addPageNum(s, 4);
}

pres.writeFile({ fileName: __dirname + "/section1_intro.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
