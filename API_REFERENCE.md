# API 레퍼런스 - JARVIS Vision Tools

이 문서는 JARVIS Vision Tools의 API와 출력 형식을 상세하게 설명합니다.

## 목차

1. [ocr_vision API](#ocr_vision-api)
2. [ui_scan API](#ui_scan-api)
3. [scan_all API](#scan_all-api)
4. [config.yml 설정](#configyml-설정)
5. [에러 코드](#에러-코드)

---

## ocr_vision API

### 사용법

```bash
ocr_vision <이미지_경로>
```

### 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| 이미지_경로 | string | O | 스캔할 이미지 파일 경로 (PNG, JPG, JPEG 지원) |

### 지원 이미지 형식

- PNG (.png)
- JPEG (.jpg, .jpeg)
- TIFF (.tiff, .tif)
- BMP (.bmp)
- GIF (.gif)

### 출력 형식

```json
{
  "dimensions": {
    "width": 1920,
    "height": 1080
  },
  "texts": [
    {
      "text": "버튼이름",
      "confidence": "0.99",
      "x": 100,
      "y": 200,
      "width": 80,
      "height": 30
    }
  ],
  "rectangles": [
    {
      "x": 50,
      "y": 180,
      "width": 200,
      "height": 60,
      "confidence": "0.95"
    }
  ],
  "barcodes": [
    {
      "type": "QR",
      "value": "https://example.com",
      "x": 100,
      "y": 100,
      "width": 50,
      "height": 50
    }
  ],
  "labels": [
    {
      "label": "screenshot",
      "confidence": "0.97"
    }
  ],
  "dominant_color": {
    "r": 242,
    "g": 243,
    "b": 242,
    "hex": "#F2F3F2"
  }
}
```

### 필드 설명

#### dimensions

이미지 크기 정보

| 필드 | 타입 | 설명 |
|------|------|------|
| width | integer | 이미지 너비 (픽셀) |
| height | integer | 이미지 높이 (픽셀) |

#### texts

감지된 텍스트 목록

| 필드 | 타입 | 설명 |
|------|------|------|
| text | string | 감지된 텍스트 내용 |
| confidence | string | 신뢰도 (0.0 ~ 1.0) |
| x | integer | 텍스트 시작 X 좌표 (픽셀) |
| y | integer | 텍스트 시작 Y 좌표 (픽셀) |
| width | integer | 텍스트 너비 (픽셀) |
| height | integer | 텍스트 높이 (픽셀) |

**참고:** 좌표계는 왼쪽 상단이 (0, 0)입니다.

#### rectangles

감지된 사각형 목록

| 필드 | 타입 | 설명 |
|------|------|------|
| x | integer | 사각형 시작 X 좌표 (픽셀) |
| y | integer | 사각형 시작 Y 좌표 (픽셀) |
| width | integer | 사각형 너비 (픽셀) |
| height | integer | 사각형 높이 (픽셀) |
| confidence | string | 신뢰도 (0.0 ~ 1.0) |

#### barcodes

감지된 바코드/QR 코드 목록

| 필드 | 타입 | 설명 |
|------|------|------|
| type | string | 바코드 타입 (QR, EAN13, Code128 등) |
| value | string | 바코드/QR 코드 내용 |
| x | integer | 바코드 시작 X 좌표 (픽셀) |
| y | integer | 바코드 시작 Y 좌표 (픽셀) |
| width | integer | 바코드 너비 (픽셀) |
| height | integer | 바코드 높이 (픽셀) |

#### labels

이미지 분류 라벨

| 필드 | 타입 | 설명 |
|------|------|------|
| label | string | 분류 라벨 (screenshot, document 등) |
| confidence | string | 신뢰도 (0.0 ~ 1.0) |

**일반적인 라벨:**
- `screenshot` - 스크린샷
- `document` - 문서
- `photo` - 사진
- `drawing` - 도면

#### dominant_color

이미지의 주요 색상

| 필드 | 타입 | 설명 |
|------|------|------|
| r | integer | 빨간색 채널 (0 ~ 255) |
| g | integer | 초록색 채널 (0 ~ 255) |
| b | integer | 파란색 채널 (0 ~ 255) |
| hex | string | HEX 색상 코드 (#RRGGBB) |

### 예제

```bash
# 기본 사용
ocr_vision /tmp/screenshot.png

# 결과 파싱 (jq)
ocr_vision /tmp/screenshot.png | jq '.texts[]'

# 신뢰도 0.9 이상만 추출
ocr_vision /tmp/screenshot.png | jq '.texts[] | select(.confidence | tonumber > 0.9)'

# 특정 좌표 근처 텍스트 찾기
ocr_vision /tmp/screenshot.png | jq '.texts[] | select(.x > 100 and .x < 200 and .y > 100 and .y < 200)'
```

---

## ui_scan API

### 사용법

```bash
ui_scan <앱_이름_또는_PID>
```

### 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| 앱_이름_또는_PID | string | O | 앱 이름 또는 프로세스 ID |

### 출력 형식

```json
[
  {
    "role": "AXWindow",
    "title": "MainWindow",
    "x": 100,
    "y": 200,
    "width": 800,
    "height": 600,
    "children": [
      {
        "role": "AXButton",
        "description": "Save",
        "x": 50,
        "y": 10,
        "width": 80,
        "height": 30
      },
      {
        "role": "AXTextField",
        "value": "입력값",
        "x": 50,
        "y": 50,
        "width": 200,
        "height": 30
      }
    ]
  }
]
```

### 필드 설명

#### 공통 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| role | string | UI 요소 타입 (AXRole) |
| x | integer | 요소 시작 X 좌표 (픽셀) |
| y | integer | 요소 시작 Y 좌표 (픽셀) |
| width | integer | 요소 너비 (픽셀) |
| height | integer | 요소 높이 (픽셀) |

#### 선택적 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| title | string | 윈도우/요소 제목 |
| value | string | 입력창/텍스트 필드 값 |
| description | string | 요소 설명 (버튼 텍스트 등) |
| children | array | 자식 요소 목록 |

#### UI 요소 타입 (AXRole)

| 타입 | 설명 |
|------|------|
| AXWindow | 윈도우 |
| AXButton | 버튼 |
| AXStaticText | 정적 텍스트 라벨 |
| AXTextField | 텍스트 입력창 |
| AXTextArea | 텍스트 영역 |
| AXMenuButton | 메뉴 버튼 |
| AXScrollArea | 스크롤 영역 |
| AXToolbar | 툴바 |
| AXImage | 이미지 |
| AXGroup | 그룹 |
| AXTable | 테이블 |
| AXRow | 테이블 행 |
| AXColumn | 테이블 열 |
| AXCell | 테이블 셀 |
| AXCheckBox | 체크박스 |
| AXRadioButton | 라디오 버튼 |
| AXSlider | 슬라이더 |
| AXProgressIndicator | 진행 표시기 |
| AXSplitGroup | 분할 그룹 |
| AXTabGroup | 탭 그룹 |
| AXOutline | 아웃라인 뷰 |

### 예제

```bash
# 기본 사용
ui_scan Safari

# PID로 스캔
ui_scan 1234

# 버튼만 추출
ui_scan Safari | jq '.[] | select(.role == "AXButton")'

# 입력창만 추출
ui_scan Safari | jq '.[] | select(.role == "AXTextField")'

# 특정 텍스트가 포함된 요소 찾기
ui_scan Safari | jq '.[] | select(.description | contains("Save"))'

# 모든 텍스트 추출
ui_scan Safari | jq '.. | .value? // .description? // .title? // empty' | grep -v null
```

---

## scan_all API

### 사용법

```bash
scan_all <입력>
```

### 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| 입력 | string | 이미지 경로, 앱 이름, 또는 PID |

### 동작 로직

1. 입력이 파일 경로이면 → `ocr_vision` 실행
2. 입력이 숫자이면 → `ui_scan` 실행 (PID로 처리)
3. 입력이 문자열이면 → `ui_scan` 실행 (앱 이름으로 처리)

### 예제

```bash
# 이미지 → ocr_vision
scan_all /tmp/screenshot.png

# 앱 이름 → ui_scan
scan_all Safari

# PID → ui_scan
scan_all 1234
```

---

## config.yml 설정

### 구조

```yaml
# 스캔 모드
scan_mode: restricted  # "restricted" 또는 "full"

# 허용된 앱 목록 (restricted 모드)
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

# 허용된 경로 (restricted 모드)
allowed_paths:
  - /tmp/
  - /Users/gray/.openclaw/media/
  - /Users/gray/Desktop/
  - /Users/gray/Downloads/
  - /Users/gray/screenshots/

# 금지된 경로 (모든 모드)
denied_paths:
  - /Users/gray/.ssh/
  - /Users/gray/.gnupg/
  - /Users/gray/.passwords/
  - /Users/gray/Private/

# 전체 화면 스캔 허용
full_screen: true  # true 또는 false
```

### 설정 필드 설명

#### scan_mode

| 값 | 설명 |
|----|------|
| restricted | 제한 모드 - 허용된 앱/경로만 스캔 |
| full | 전체 모드 - 모든 앱/경로 스캔 가능 |

#### allowed_apps

`restricted` 모드에서 `ui_scan`으로 스캔할 수 있는 앱 목록

#### allowed_paths

`restricted` 모드에서 `ocr_vision`으로 스캔할 수 있는 경로 목록

#### denied_paths

모든 모드에서 스캔이 금지된 경로 목록 (보안상 중요)

#### full_screen

전체 화면 캡처 허용 여부

| 값 | 설명 |
|----|------|
| true | `screencapture`로 전체 화면 캡처 가능 |
| false | 스크린샷 파일만 스캔 가능 |

---

## 에러 코드

### ocr_vision 에러

| 에러 메시지 | 원인 | 해결 |
|-------------|------|------|
| ERROR: Cannot load image | 이미지 파일을 읽을 수 없음 | 파일 경로 확인, 권한 확인 |
| ERROR: Image format not supported | 지원하지 않는 이미지 형식 | PNG/JPEG로 변환 |
| ERROR: Screen capture permission denied | 화면 녹화 권한 없음 | 시스템 설정에서 권한 허용 |

### ui_scan 에러

| 에러 메시지 | 원인 | 해결 |
|-------------|------|------|
| [] | 앱을 찾을 수 없음 | 앱 이름/PID 확인 |
| ERROR: Accessibility permission denied | 접근성 권한 없음 | 시스템 설정에서 권한 허용 |
| ERROR: App not running | 앱이 실행 중이 아님 | 앱 실행 후 다시 시도 |

### scan_all 에러

| 에러 메시지 | 원인 | 해결 |
|-------------|------|------|
| ERROR: Invalid input | 잘못된 입력 | 파일 경로/앱 이름/PID 확인 |
| ERROR: Permission denied | 권한 문제 | config.yml 설정 확인 |

---

## 성능 특성

### ocr_vision

| 항목 | 값 |
|------|-----|
| 처리 속도 | ~0.7초 (Apple Silicon) |
| 지원 이미지 크기 | 최대 8K (7680×4320) |
| 메모리 사용 | ~50MB |
| 지원 언어 | 한국어, 영어 |

### ui_scan

| 항목 | 값 |
|------|-----|
| 처리 속도 | ~0.3초 |
| 지원 앱 수 | 제한 없음 |
| 메모리 사용 | ~30MB |
| 스캔 깊이 | 최대 2레벨 (children) |

---

## 추가 리소스

- [README.md](README.md) - 프로젝트 개요
- [USAGE_GUIDE.md](USAGE_GUIDE.md) - 사용 가이드
- [MANUAL.md](MANUAL.md) - 상세 기술 문서
- [UPGRADE_MANUAL.md](UPGRADE_MANUAL.md) - 업그레이드 가이드
- [GitHub Issues](https://github.com/graychaos44/ocr-vision/issues) - 버그 리포트

---

## 도움말

문제가 있으면 GitHub Issues에 등록해주세요:
https://github.com/graychaos44/ocr-vision/issues