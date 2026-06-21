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
const mkHdr = (t) => ({
  text: t, options: { bold: true, fill: { color: C.tblHdr }, color: "FFFFFF", fontSize: 14, fontFace: FONT }
});

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

// Slide 2: 멀티 슬롯 시뮬레이션 구조
{
  let s = pres.addSlide();
  addTitle(s, "멀티 슬롯 시뮬레이션 구조");
  addBulletSlide(s, [
    { text: "별도의 \"슬레이브 ID\" 식별 시스템은 없음 — 슬롯 위치 번호(0~7)가 식별자 역할을 대신함" },
    { text: "i_CFG_ACTIVE_SLOT[7:0] 비트마스크로 슬롯별 활성/비활성 결정" },
    { text: "슬롯별 payload 출처가 분리됨", level: 0 },
    { text: "슬롯 0~5: AXI 레지스터, 슬롯 6~7: 외부 PL 버스", level: 1 },
    { text: "슬롯 인덱스가 프레임에 {slot_id, payload} 형태로 직접 포함됨" },
  ]);
  addPageNum(s, 2);
}

// Slide 3: 슬롯 순회 타이밍과 한계
{
  let s = pres.addSlide();
  addTitle(s, "슬롯 순회 타이밍과 한계");
  addBulletSlide(s, [
    { text: "sync_pulse를 기준으로 8개 슬롯의 절대 타겟 틱을 계산 (slave_timing_scheduler)" },
    { text: "시퀀서 FSM이 슬롯 0→7 순서로 순회하며, 각 슬롯의 타겟 시각에 도달하면 TX 발행" },
    { text: "3비트 slot_id 필드 폭의 구조적 한계로 최대 8개로 고정 — 파라미터로 늘릴 수 없음" },
    { text: "합성 가능한 실제 RTL로 구현되어 있으며, 테스트벤치 전용 코드가 아님" },
  ]);
  addPageNum(s, 3);
}

// Slide 4: 버튼 기반 Payload 생성 (표)
{
  let s = pres.addSlide();
  addTitle(s, "버튼 기반 Payload 생성");
  s.addText([
    { text: "버튼을 20ms 주기로 샘플링, HIGH→LOW 디바운스 펄스를 검출했을 때만 1회 증가", options: { bullet: true, breakLine: true, fontSize: 18, color: C.body, paraSpaceAfter: 10 } },
    { text: "슬롯별 증가량은 정확히 2^slot_id — 8개의 독립된 32비트 레지스터", options: { bullet: true, fontSize: 18, color: C.body } },
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
  addPageNum(s, 4);
}

// Slide 5: Master 수신 및 검증
{
  let s = pres.addSlide();
  addTitle(s, "Master 수신 및 검증");
  addBulletSlide(s, [
    { text: "디코딩된 payload가 슬롯별로 slot_out0~7 레지스터에 저장됨" },
    { text: "DIP 스위치로 원하는 슬롯을 선택해 7-세그먼트에 표시" },
    { text: "테스트벤치(tb_btn_payload_ctrl.v, tb_btn_slave_master_comm.v)로 검증" },
    { text: "버튼→슬레이브→마스터 전체 경로에서 n_press × {1,2,4,...,128}이 정확히 일치함을 확인", level: 1 },
  ]);
  addPageNum(s, 5);
}

// Slide 6: 클럭 분리와 분주비
{
  let s = pres.addSlide();
  addTitle(s, "클럭 분리와 분주비");
  addBulletSlide(s, [
    { text: "Master·Slave는 클럭선을 공유하지 않음 — 데이터선(TX/RX 1비트)만 연결, 각자 로컬 클럭에서 분주" },
    { text: "분주비 DIV는 AXI 레지스터로 런타임에 소프트웨어가 설정 (하드코딩된 기본값 없음)" },
    { text: "Master·Slave 양쪽에 동일한 DIV 값으로 설정한다고 가정" },
    { text: "1비트 구간 = DIV + 1 클럭" },
  ]);
  addPageNum(s, 6);
}

// Slide 7: 비트 샘플링과 한계
{
  let s = pres.addSlide();
  addTitle(s, "비트 샘플링과 한계");
  addBulletSlide(s, [
    { text: "매 비트 구간의 중간 지점에서 정확히 1회만 샘플링 — 오버샘플링·다수결 방식이 아님" },
    { text: "에지 검출은 프레임 시작(프리앰블)에만 사용되어 동기를 재정렬" },
    { text: "이후 비트들은 순수 카운터 기반으로 진행 — 비트마다 재동기하지 않음" },
    { text: "한계: guard_ticks는 슬롯 경계 여유 파라미터일 뿐, 비트 단위 클럭 드리프트 허용치를 정량화·보장하는 코드는 없음", level: 0 },
  ]);
  addPageNum(s, 7);
}

// Slide 8: 고장 진단 모델과 Master 고장 유형 (표)
{
  let s = pres.addSlide();
  addTitle(s, "Master의 고장 진단과 처리");
  s.addText(
    "\"FSM이 진단한다\"는 표현과 달리, 실제로는 슬롯별 4개의 임계값 카운터(preamble_err_cnt, slot_timeout_cnt, hamming_err_cnt, silent_cnt)와 조합논리로 동작함",
    { x: 0.6, y: 1.3, w: 8.8, h: 0.55, fontSize: 16, color: "444444", fontFace: FONT, valign: "top" }
  );

  s.addTable([
    [mkHdr("고장 유형"), mkHdr("처리")],
    ["프리앰블 불일치", "preamble_err_cnt +6"],
    ["심각한 타이밍 오류 (데이터 윈도우 중 수신/슬롯 불일치)", "slot_timeout_cnt 즉시 255로 saturate"],
    ["약한 타이밍 오류 (가드 경계 수신)", "slot_timeout_cnt +6 (없으면 매 사이클 -1로 감쇠)"],
    ["Hamming 1비트 정정 가능 오류", "데이터는 정정 수용, hamming_err_cnt +4"],
    ["Hamming 2비트 정정 불가 오류", "프레임 폐기(이전 값 유지), hamming_err_cnt +8"],
    ["무응답 (silent)", "silent_cnt +6 — 표시만 하고 halt_cmd 판정에는 미포함"],
  ], {
    x: 0.6, y: 1.95, w: 8.8,
    fontFace: FONT, fontSize: 13, color: C.body,
    border: { pt: 0.5, color: "CCCCCC" },
    rowH: 0.36,
  });
  addPageNum(s, 8);
}

// Slide 9: 종합 판정과 halt_cmd
{
  let s = pres.addSlide();
  addTitle(s, "종합 판정과 halt_cmd");
  addBulletSlide(s, [
    { text: "(preamble_err_cnt + slot_timeout_cnt + hamming_err_cnt) > FAULT_TH 이면 해당 슬롯 halt_cmd = 1" },
    { text: "silent_cnt는 이 종합 판정에서 제외됨" },
    { text: "halt_cmd = 1이 된 슬롯은 이후 카운터가 동결됨" },
    { text: "Master가 브로드캐스트 프레임에 halt_cmd를 실어 모든 Slave에 전송" },
  ]);
  addPageNum(s, 9);
}

// Slide 10: Slave 측 처리와 Master/Slave 모델 차이
{
  let s = pres.addSlide();
  addTitle(s, "Slave 측 처리와 모델 차이");
  addBulletSlide(s, [
    { text: "halt_cmd 수신 시 해당 슬롯을 active_slot에서 제외 — 그 슬롯의 TX 자체가 발행되지 않음" },
    { text: "자체 감지 고장: tx_overlap, slot_timing_invalid, pl_payload6/7_invalid, rx_ham_2bit", level: 0 },
    { text: "처리: sticky W1C 플래그 설정 + PS에 인터럽트(o_irq) — PS가 직접 클리어해야 함", level: 1 },
    { text: "자체 감지 고장은 보고만 하고 자동 셧다운하지 않음 — 능동적 송신 중단은 halt_cmd 수신 시뿐", level: 1 },
    { text: "Master(누적-임계치 err_cnt/FAULT_TH 모델) ↔ Slave(상태없는 sticky 이벤트 플래그 모델) — 공유되는 건 halt_cmd/broadcast_halt_mask 8비트뿐" },
  ]);
  addPageNum(s, 10);
}

pres.writeFile({ fileName: __dirname + "/section3_part2_internals.pptx" })
  .then(() => console.log("done"))
  .catch(e => console.error(e));
