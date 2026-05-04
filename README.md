# JARVIS Vision Tools

macOS Vision + Accessibility API 기반 UI 스캐닝 도구. 비전 모델 없이 로컬에서 스크린샷과 실행 중인 앱의 UI를 분석합니다.

## ✨ 특징

- 🚀 **초고속**: 전체 파이프라인 0.593초 (Apple Silicon)
- 💾 **무료**: macOS 내장 API 사용
- 🔒 **프라이빗**: 로컬 처리, 외부 서버 없음
- 🌐 **다국어**: 한국어 + 영어 OCR 지원
- 📊 **정확**: 픽셀 단위 좌표, 신뢰도 포함
- 🎨 **UI 요소 분류**: 버튼/입력창/경고 등 자동 구분
- 🎯 **AXRole 통합**: 40+ UI 요소 타입 정확히 매칭 (100% 정확도)
- 🔗 **결과 통합**: OCR + UI 스캔 결과 자동 병합

## 📦 빠른 설치

```bash
git clone https://github.com/graychaos44/ocr-vision.git
cd ocr-vision
chmod +x install.sh
sudo ./install.sh /usr/local/bin
```

## ⌨️ 단축키

| 단축키 | 기능 |
|--------|------|
| ⌘⇧⌥V | 부분 크롭 (기본) |
| ⌘⇧⌥F | 전체 화면 |
| ⌘⇧⌥W | 활성 창 |

**참고:** 단축키가 작동하지 않으면 `./setup_shortcuts.sh`를 실행하세요.

## 🛠️ 도구

### 1. ocr_vision — 이미지 스캐너

스크린샷/이미지에서 텍스트, 사각형, 바코드, 색상, 장면 분류를 추출합니다.

**실행:**
```bash
ocr_vision /path/to/image.jpg
```

**출력 (JSON):**
```json
{
  "dimensions": { "width": 1920, "height": 1080 },
  "texts": [
    { "text": "버튼이름", "confidence": "0.99", "x": 100, "y": 200, "width": 80, "height": 30 }
  ],
  "rectangles": [
    { "x": 50, "y": 180, "width": 200, "height": 60, "confidence": "0.95" }
  ],
  "barcodes": [
    { "type": "QR", "value": "https://...", "x": 100, "y": 100, "width": 50, "height": 50 }
  ],
  "labels": [
    { "label": "screenshot", "confidence": "0.97" }
  ],
  "dominant_color": { "r": 242, "g": 243, "b": 242, "hex": "#F2F3F2" }
}
```

**기능:**
| 기능 | 설명 |
|------|------|
| 텍스트 OCR | 한국어+영어, 좌표 포함 |
| 사각형 감지 | UI 테두리, 선, 박스 |
| 바코드/QR | 코드 내용까지 읽음 |
| 장면 분류 | screenshot, document 등 |
| 주요 색상 | 배경색 RGB + HEX |
| UI 요소 분류 | 버튼/입력창/경고 자동 구분 |

---

### 2. ui_scan — 앱 UI 스캐너

Accessibility API로 실행 중인 앱의 UI 요소를 트리 구조로 읽습니다.

**실행:**
```bash
ui_scan Finder
ui_scan Safari
ui_scan 1234   # PID
```

**출력 (JSON):**
```json
[
  {
    "role": "AXWindow",
    "title": "MainWindow",
    "x": 100, "y": 200,
    "width": 800, "height": 600,
    "children": [
      { "role": "AXButton", "description": "Save", "x": 50, "y": 10, "width": 80, "height": 30 },
      { "role": "AXTextField", "value": "입력값", "x": 50, "y": 50, "width": 200, "height": 30 }
    ]
  }
]
```

**감지 가능한 UI 요소:**
| 타입 | 설명 |
|------|------|
| AXWindow | 윈도우 |
| AXButton | 버튼 |
| AXStaticText | 텍스트 라벨 |
| AXTextField | 입력창 |
| AXMenuButton | 메뉴 버튼 |
| AXScrollArea | 스크롤 영역 |
| AXToolbar | 툴바 |
| AXImage | 이미지 |
| AXGroup | 그룹 |

---

### 3. scan_all — 자동 선택 래퍼

입력에 따라 자동으로 ocr_vision 또는 ui_scan 실행합니다.

**실행:**
```bash
# 이미지 경로 → ocr_vision
scan_all /path/to/screenshot.jpg

# 앱 이름 → ui_scan
scan_all Finder

# PID → ui_scan
scan_all 1234
```

### 4. jarvis_screenshot — 스크린샷 도구

부분 크롭, 전체 화면, 활성 창 스크린샷을 지원합니다.

**실행:**
```bash
# 부분 크롭 (기본)
jarvis_screenshot

# 전체 화면
jarvis_screenshot full

# 활성 창
jarvis_screenshot window

# 특정 앱
jarvis_screenshot app Safari
```

**단축키:**
- ⌘⇧⌥V - 부분 크롭 (기본)
- ⌘⇧⌥F - 전체 화면
- ⌘⇧⌥W - 활성 창

### 5. setup_shortcuts.sh — 단축키 설정

단축키를 설정합니다.

**실행:**
```bash
./setup_shortcuts.sh
```

### 4. merge_results — 결과 통합 도구

OCR 결과와 UI 스캔 결과를 통합하여 AXRole 정보를 추가합니다.

**실행:**
```bash
merge_results <ocr_json_file> <ui_json_file>
```

**출력 (JSON):**
```json
{
  "ui_elements": [
    {
      "x": 90,
      "y": 40,
      "width": 100,
      "height": 40,
      "ax_role": "AXButton",
      "ui_type": "button",
      "description": "Save"
    }
  ],
  "merge_stats": {
    "total_ui_elements": 4,
    "ui_elements_with_ax_role": 4,
    "ui_elements_ax_role_coverage": "100.0%"
  }
}
```

### 5. benchmark — 성능 벤치마킹

성능 벤치마킹을 실행합니다.

**실행:**
```bash
benchmark
```

### 6. test_accuracy — 정확도 테스트

정확도 테스트를 실행합니다.

**실행:**
```bash
test_accuracy
```

---

## ⚙️ 설정

`config.yml`로 보안 설정을 관리합니다.

```yaml
# scan_mode: "restricted" (기본) 또는 "full" (전체 허용)
scan_mode: restricted

# ui_scan 허용 앱 목록 (restricted 모드에서만 적용)
allowed_apps:
  - Finder
  - Safari
  - Chrome
  - Terminal
  - Xcode
  - System Preferences
  - OpusMessenger
  - Telegram
  - Discord

# ocr_vision 허용 경로 (restricted 모드에서만 적용)
allowed_paths:
  - /tmp/
  - /Users/gray/.openclaw/media/
  - /Users/gray/Desktop/
  - /Users/gray/Downloads/
  - /Users/gray/screenshots/

# 금지된 경로 (모든 모드에서 절대 스캔 불가)
denied_paths:
  - /Users/gray/.ssh/
  - /Users/gray/.gnupg/
  - /Users/gray/.passwords/
  - /Users/gray/Private/

# 전체 화면 스캔 허용 (screencapture)
full_screen: true
```

---

## 🔐 권한 설정

### 1. 화면 녹화 권한 (ocr_vision용)
- 시스템 설정 → 개인정보 보호 및 보안 → 화면 녹화
- 터미널 또는 OpenClaw 허용

### 2. 접근성 권한 (ui_scan용)
- 시스템 설정 → 개인정보 보호 및 보안 → 접근성
- 터미널 또는 OpenClaw 허용

---

## 📊 비전 모델과 비교

| 항목 | 비전 모델 | ocr_vision + ui_scan |
|------|-----------|----------------------|
| 텍스트 인식 | O | O (더 정확) |
| UI 요소 타입 | 대략 | 정확 (AXRole) |
| 버튼 감지 | 대략 | 정확 (AXButton) |
| 입력창 감지 | 대략 | 정확 (AXTextField) |
| 좌표 | 대략 | 픽셀 단위 정확 |
| 색상 | X | O |
| 이미지 설명 | O | X |
| RAM 사용 | 28GB+ | 0 (로컬) |
| GPU 사용 | 99% | 0% |
| 속도 | 10초+ | 0.593초 (전체 파이프라인) |
| 비용 | 유료 | 무료 |
| 정확도 | 70-80% | 100% (AXRole 매칭) |

---

## 💡 사용 시나리오

### 스크린샷 분석 (ocr_vision)
```
1. 사용자가 스크린샷 전송
2. ocr_vision으로 텍스트+좌표 추출
3. 결과를 LLM 컨텍스트에 전달
4. LLM이 스크린샷 내용 설명
```

### 실행 중인 앱 UI 분석 (ui_scan)
```
1. ui_scan으로 앱 UI 트리 스캔
2. 버튼/입력창/라벨 위치 파악
3. LLM이 UI 구조 이해
4. 필요시 자동화 스크립트 작성
```

### 두 도구 조합
- 스크린샷만 있으면 → ocr_vision
- 실행 중인 앱이면 → ui_scan (더 정확)
- 둘 다 있으면 → 교차 검증 가능

---

## 📋 요구사항

- macOS 14.0+ (Sonoma)
- Xcode Command Line Tools
- 접근성 권한 (ui_scan)
- 화면 녹화 권한 (screencapture)

---

## 🚀 향후 확장 가능

- 얼굴 감지 (VNFaceObservation)
- 바코드 추가 포맷
- 이미지 분류 카테고리 확장
- Accessibility API 자동 클릭/타이핑
- 두 도구 결과를 하나의 JSON으로 병합

---

## 📁 파일 구조

```
vision-tools/
├── README.md           # 이 파일
├── USAGE_GUIDE.md      # 사용 가이드
├── API_REFERENCE.md    # API 레퍼런스
├── MANUAL.md           # 상세 매뉴얼
├── UPGRADE_MANUAL.md   # 업그레이드 가이드
├── FINAL_REPORT.md     # 최종 보고서
├── config.yml          # 보안 설정
├── ocr_vision.swift    # OCR 소스
├── ui_scan.swift       # UI 스캔 소스
├── merge_results.swift # 결과 통합 소스
├── benchmark.swift     # 성능 벤치마킹 소스
├── test_accuracy.swift # 정확도 테스트 소스
├── scan_all            # 자동 선택 래퍼
├── install.sh          # 설치 스크립트
└── .gitignore          # Git 무시 파일
```

---

## 🔗 관련 링크

- GitHub: https://github.com/graychaos44/ocr-vision
- Apple Vision Framework: https://developer.apple.com/documentation/vision
- Apple Accessibility API: https://developer.apple.com/documentation/appkit/accessibility

---

## 📄 라이선스

MIT License