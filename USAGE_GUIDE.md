# 사용 가이드 - JARVIS Vision Tools

이 가이드는 JARVIS Vision Tools를 실제로 사용하는 방법을 단계별로 설명합니다.

## 목차

1. [설치](#설치)
2. [권한 설정](#권한-설정)
3. [기본 사용법](#기본-사용법)
4. [고급 사용법](#고급-사용법)
5. [트러블슈팅](#트러블슈팅)
6. [실전 예제](#실전-예제)

---

## 설치

### 1. 소스 코드 다운로드

```bash
git clone https://github.com/graychaos44/ocr-vision.git
cd ocr-vision
```

### 2. 자동 설치 (권장)

```bash
chmod +x install.sh
sudo ./install.sh /usr/local/bin
```

이 명령은 다음을 수행합니다:
- Swift 소스 코드 컴파일
- 바이너리를 `/usr/local/bin`에 설치
- 심볼릭 링크 생성

### 3. 수동 설치

자동 설치가 실패하면 수동으로 설치하세요:

```bash
# ocr_vision 컴파일
swiftc -O -o /usr/local/bin/ocr_vision ocr_vision.swift

# ui_scan 컴파일
swiftc -o /usr/local/bin/ui_scan ui_scan.swift -framework ApplicationServices -framework AppKit

# scan_all 복사
cp scan_all /usr/local/bin/
chmod +x /usr/local/bin/scan_all
```

### 4. 설치 확인

```bash
ocr_vision --version
ui_scan --version
```

---

## 권한 설정

### 1. 화면 녹화 권한 (ocr_vision용)

**목적:** 스크린샷 캡처 허용

**설정 방법:**
1. 시스템 설정 열기
2. 개인정보 보호 및 보안 → 화면 녹화
3. 터미널 또는 OpenClaw 체크박스 활성화
4. 변경 사항 적용을 위해 터미널 재시작

**확인:**
```bash
screencapture -x /tmp/test.png
ls /tmp/test.png
```

### 2. 접근성 권한 (ui_scan용)

**목적:** 실행 중인 앱의 UI 요소 읽기 허용

**설정 방법:**
1. 시스템 설정 열기
2. 개인정보 보호 및 보안 → 접근성
3. 터미널 또는 OpenClaw 체크박스 활성화
4. 변경 사항 적용을 위해 터미널 재시작

**확인:**
```bash
ui_scan Finder
```

---

## 기본 사용법

### ocr_vision - 이미지 스캔

#### 1. 스크린샷 캡처

```bash
# 전체 화면
screencapture -x /tmp/screenshot.png

# 특정 영역
screencapture -R 100,100,800,600 -x /tmp/region.png
```

#### 2. OCR 실행

```bash
ocr_vision /tmp/screenshot.png
```

#### 3. 결과 파싱 (jq 사용)

```bash
# 텍스트만 추출
ocr_vision /tmp/screenshot.png | jq '.texts[].text'

# 신뢰도 0.9 이상만 추출
ocr_vision /tmp/screenshot.png | jq '.texts[] | select(.confidence | tonumber > 0.9)'

# 특정 좌표 근처 텍스트 찾기
ocr_vision /tmp/screenshot.png | jq '.texts[] | select(.x > 100 and .x < 200)'
```

### ui_scan - 앱 UI 스캔

#### 1. 실행 중인 앱 목록 확인

```bash
ps aux | grep -i safari
```

#### 2. 앱 이름으로 스캔

```bash
ui_scan Safari
```

#### 3. PID로 스캔

```bash
# PID 찾기
pgrep Safari

# PID로 스캔
ui_scan 1234
```

#### 4. 결과 파싱

```bash
# 버튼만 추출
ui_scan Safari | jq '.[] | select(.role == "AXButton")'

# 입력창만 추출
ui_scan Safari | jq '.[] | select(.role == "AXTextField")'

# 특정 텍스트가 포함된 요소 찾기
ui_scan Safari | jq '.[] | select(.description | contains("Save"))'
```

### scan_all - 자동 선택

```bash
# 이미지 → ocr_vision 자동 실행
scan_all /tmp/screenshot.png

# 앱 이름 → ui_scan 자동 실행
scan_all Safari

# PID → ui_scan 자동 실행
scan_all 1234
```

---

## 고급 사용법

### 1. 스크립트와 결합

#### 스크린샷에서 특정 텍스트 찾기

```bash
#!/bin/bash
IMAGE=$1
TEXT=$2

ocr_vision "$IMAGE" | jq --arg text "$TEXT" '.texts[] | select(.text == $text)'
```

사용:
```bash
./find_text.sh /tmp/screenshot.png "버튼이름"
```

#### 앱에서 특정 버튼 찾기

```bash
#!/bin/bash
APP=$1
BUTTON=$2

ui_scan "$APP" | jq --arg button "$BUTTON" '.[] | select(.description == $button)'
```

사용:
```bash
./find_button.sh Safari "Save"
```

### 2. 주기적 모니터링

#### 30초마다 스크린샷 스캔

```bash
#!/bin/bash
while true; do
    screencapture -x /tmp/monitor.png
    ocr_vision /tmp/monitor.png > /tmp/result.json
    sleep 30
done
```

#### 앱 UI 변경 감지

```bash
#!/bin/bash
APP=$1
LAST_HASH=""

while true; do
    CURRENT_HASH=$(ui_scan "$APP" | md5)
    if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
        echo "UI 변경 감지!"
        LAST_HASH=$CURRENT_HASH
    fi
    sleep 5
done
```

### 3. LLM과 통합

#### OpenClaw에서 사용

```python
import subprocess
import json

def scan_image(image_path):
    result = subprocess.run(['ocr_vision', image_path], capture_output=True, text=True)
    return json.loads(result.stdout)

def scan_app(app_name):
    result = subprocess.run(['ui_scan', app_name], capture_output=True, text=True)
    return json.loads(result.stdout)

# 사용 예시
image_data = scan_image('/tmp/screenshot.png')
texts = [t['text'] for t in image_data['texts']]
print(f"발견된 텍스트: {texts}")
```

---

## 트러블슈팅

### 1. "ERROR: Cannot load image"

**원인:** 이미지 파일이 없거나 읽을 수 없음

**해결:**
```bash
# 파일 존재 확인
ls -la /tmp/screenshot.png

# 파일 권한 확인
chmod 644 /tmp/screenshot.png
```

### 2. "[]" (빈 결과)

**원인:** 권한 문제 또는 앱이 실행 중이 아님

**해결:**
```bash
# 권한 확인
# 시스템 설정 → 개인정보 보호 및 보안 → 접근성

# 앱 실행 확인
ps aux | grep -i safari
```

### 3. "Permission denied"

**원인:** 바이너리 실행 권한 없음

**해결:**
```bash
chmod +x /usr/local/bin/ocr_vision
chmod +x /usr/local/bin/ui_scan
chmod +x /usr/local/bin/scan_all
```

### 4. 속도가 너무 느림

**원인:** 큰 이미지 처리

**해결:**
```bash
# 이미지 리사이즈
sips -Z 1920 /tmp/large.png --out /tmp/small.png

# 리사이즈된 이미지 스캔
ocr_vision /tmp/small.png
```

---

## 실전 예제

### 예제 1: 웹사이트에서 텍스트 추출

```bash
# 1. 스크린샷 캡처
screencapture -x /tmp/website.png

# 2. OCR 실행
ocr_vision /tmp/website.png > /tmp/website.json

# 3. 텍스트만 추출
jq '.texts[].text' /tmp/website.json > /tmp/texts.txt

# 4. 결과 확인
cat /tmp/texts.txt
```

### 예제 2: 앱에서 버튼 위치 찾기

```bash
# 1. 앱 스캔
ui_scan Safari > /tmp/safari.json

# 2. 버튼만 추출
jq '.[] | select(.role == "AXButton")' /tmp/safari.json > /tmp/buttons.json

# 3. 결과 확인
cat /tmp/buttons.json
```

### 예제 3: QR 코드 스캔

```bash
# 1. QR 코드 이미지 스캔
ocr_vision /tmp/qrcode.png > /tmp/qrcode.json

# 2. QR 코드 값 추출
jq '.barcodes[].value' /tmp/qrcode.json
```

### 예제 4: 이미지에서 주요 색상 추출

```bash
# 1. 이미지 스캔
ocr_vision /tmp/image.png > /tmp/image.json

# 2. 주요 색상 추출
jq '.dominant_color' /tmp/image.json
```

### 예제 5: 여러 앱 동시 스캔

```bash
#!/bin/bash
APPS=("Safari" "Chrome" "Finder")

for app in "${APPS[@]}"; do
    echo "Scanning $app..."
    ui_scan "$app" > "/tmp/${app}.json"
done
```

---

## 팁

1. **속도 최적화:** 작은 이미지를 사용하면 더 빠릅니다
2. **정확도 향상:** 고해상도 이미지에서 더 정확한 결과
3. **메모리 관리:** 큰 이미지는 리사이즈 후 처리
4. **권한 확인:** 문제 발생 시 항상 권한 먼저 확인
5. **결과 저장:** JSON 형식으로 저장하면 나중에 분석 가능

---

## 추가 리소스

- [README.md](README.md) - 프로젝트 개요
- [MANUAL.md](MANUAL.md) - 상세 기술 문서
- [UPGRADE_MANUAL.md](UPGRADE_MANUAL.md) - 업그레이드 가이드
- [GitHub Issues](https://github.com/graychaos44/ocr-vision/issues) - 버그 리포트

---

## 도움말

문제가 있으면 GitHub Issues에 등록해주세요:
https://github.com/graychaos44/ocr-vision/issues