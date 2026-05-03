# JARVIS Vision Tools

macOS Vision + Accessibility API 기반 UI 스캐닝 도구. 비전 모델 없이 로컬에서 스크린샷과 실행 중인 앱의 UI를 분석.

## 빠른 설치

```bash
git clone https://github.com/graychaos44/ocr-vision.git
cd ocr-vision
chmod +x install.sh
sudo ./install.sh /usr/local/bin
```

## 도구

### ocr_vision — 이미지 스캐너
스크린샷/이미지에서 텍스트, 사각형, 바코드, 색상, 장면 분류를 추출.

```bash
ocr_vision /path/to/image.jpg
```

### ui_scan — 앱 UI 스캐너
실행 중인 앱의 UI 요소를 트리 구조로 읽기.

```bash
ui_scan Finder
ui_scan Safari
ui_scan 1234   # PID
```

### scan_all — 자동 선택 래퍼
입력에 따라 자동으로 ocr_vision 또는 ui_scan 실행.

```bash
scan_all /path/to/screenshot.jpg   # 이미지 → ocr_vision
scan_all Finder                    # 앱 이름 → ui_scan
scan_all 1234                      # PID → ui_scan
```

## 출력 예시

### ocr_vision
```json
{
  "dimensions": { "width": 1920, "height": 1080 },
  "texts": [
    { "text": "버튼이름", "confidence": "0.99", "x": 100, "y": 200, "width": 80, "height": 30 }
  ],
  "rectangles": [
    { "x": 50, "y": 180, "width": 200, "height": 60, "confidence": "0.95" }
  ],
  "barcodes": [],
  "labels": [
    { "label": "screenshot", "confidence": "0.97" }
  ],
  "dominant_color": { "r": 242, "g": 243, "b": 242, "hex": "#F2F3F2" }
}
```

### ui_scan
```json
[
  {
    "role": "AXWindow",
    "title": "MainWindow",
    "x": 100, "y": 200,
    "width": 800, "height": 600,
    "children": [
      { "role": "AXButton", "description": "Save", "x": 50, "y": 10, "width": 80, "height": 30 }
    ]
  }
]
```

## 비전 모델과 비교

| 항목 | 비전 모델 | ocr_vision + ui_scan |
|------|-----------|----------------------|
| 텍스트 인식 | O | O (더 정확) |
| UI 요소 타입 | 대략 | 정확 (AXRole) |
| 좌표 | 대략 | 픽셀 단위 |
| 색상 | X | O |
| 이미지 설명 | O | X |
| RAM | 28GB+ | 0 |
| GPU | 99% | 0% |
| 속도 | 10초+ | 0.7초 |
| 비용 | 유료 | 무료 |

## 권한 설정

1. 시스템 설정 → 개인정보 보호 및 보안
2. 화면 녹화 → 터미널/OpenClaw 허용 (ocr_vision 스크린샷용)
3. 접근성 → 터미널/OpenClaw 허용 (ui_scan용)

## 요구사항

- macOS 14.0+ (Sonoma)
- Xcode Command Line Tools
- 접근성 권한 (ui_scan)
- 화면 녹화 권한 (screencapture)

## 확장 가능

- 얼굴 감지 (VNFaceObservation)
- 바코드 추가 포맷
- 이미지 분류 카테고리 확장
- Accessibility API 자동 클릭/타이핑
- 두 도구 결과를 하나의 JSON으로 병합

## 라이선스

MIT