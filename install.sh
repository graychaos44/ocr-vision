#!/bin/bash
# JARVIS Vision Tools - 통합 설치 스크립트
# ocr_vision + ui_scan + scan_all

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-/usr/local/bin}"

echo "=== JARVIS Vision Tools 설치 ==="
echo "설치 경로: $INSTALL_DIR"
echo ""

# 사전 요구사항 체크
echo "[0/4] 사전 요구사항 체크..."

if ! command -v swiftc &>/dev/null; then
    echo "ERROR: Swift 컴파일러가 없습니다. Xcode Command Line Tools를 설치하세요:"
    echo "  xcode-select --install"
    exit 1
fi
SWIFT_VER=$(swiftc --version 2>&1 | head -1)
echo "  Swift: $SWIFT_VER ✅"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERROR: macOS만 지원합니다."
    exit 1
fi
echo "  macOS ✅"

echo ""
echo "[1/4] ocr_vision 컴파일 중..."
swiftc -O -o "$INSTALL_DIR/ocr_vision" "$SCRIPT_DIR/ocr_vision.swift"

echo "[2/4] ui_scan 컴파일 중..."
swiftc -o "$INSTALL_DIR/ui_scan" "$SCRIPT_DIR/ui_scan.swift" -framework ApplicationServices -framework AppKit

echo "[3/4] scan_all 스크립트 설치 중..."
cat > "$INSTALL_DIR/scan_all" << 'SCRIPT'
#!/bin/bash
# JARVIS Vision Tools - 자동 선택 래퍼 (보안 체크 포함)
# 이미지 파일 → ocr_vision, 앱 이름/PID → ui_scan
# --full: 전체 화면 스캔 (config.yml에서 full_screen: true 필요)

TOOL_DIR="$(dirname "$0")"
CONFIG="$TOOL_DIR/config.yml"
SCREENSHOT_PATH="/tmp/jarvis_screenshot_$(date +%s).png"

get_config() {
    local key="$1"
    local value=$(grep "^$key:" "$CONFIG" 2>/dev/null | awk '{print $2}')
    echo "$value"
}

if [ -z "$1" ]; then
    echo "JARVIS Vision Tools"
    echo ""
    echo "Usage: scan_all <image_path|app_name|pid>"
    echo "       scan_all --full              # 전체 화면 캡처 후 스캔"
    echo "       scan_all --full <app_name>   # 전체 화면 + 앱 UI 스캔"
    echo ""
    echo "Examples:"
    echo "  scan_all screenshot.jpg           # 이미지 OCR"
    echo "  scan_all Finder                  # 앱 UI 스캔"
    echo "  scan_all --full                  # 전체 화면 + OCR"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: config.yml not found. Scan blocked."
    exit 1
fi

SCAN_MODE=$(get_config "scan_mode")
FULL_SCREEN=$(get_config "full_screen")
INPUT="$1"

if [ "$INPUT" = "--full" ]; then
    if [ "$FULL_SCREEN" != "true" ]; then
        echo "ERROR: Full screen scan is disabled in config.yml."
        echo "Set full_screen: true to enable."
        exit 1
    fi
    screencapture -x "$SCREENSHOT_PATH" 2>/dev/null
    if [ ! -f "$SCREENSHOT_PATH" ]; then
        echo "ERROR: Screen capture failed. Check screen recording permission."
        exit 1
    fi
    
    RESULT=$("$TOOL_DIR/ocr_vision" "$SCREENSHOT_PATH" 2>&1)
    
    if [ -n "$2" ]; then
        APP_NAME="$2"
        if [ "$SCAN_MODE" = "restricted" ]; then
            if ! grep -q "^  - $APP_NAME$" "$CONFIG"; then
                echo "ERROR: App '$APP_NAME' not in allowed list."
                rm -f "$SCREENSHOT_PATH"
                exit 1
            fi
        fi
        UI_RESULT=$("$TOOL_DIR/ui_scan" "$APP_NAME" 2>&1)
        echo "=== SCREENSHOT OCR ==="
        echo "$RESULT"
        echo ""
        echo "=== APP UI: $APP_NAME ==="
        echo "$UI_RESULT"
    else
        echo "$RESULT"
    fi
    
    rm -f "$SCREENSHOT_PATH"
    exit 0
fi

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    APP_NAME=$(ps -p "$INPUT" -o comm= 2>/dev/null | xargs basename 2>/dev/null)
    if [ -z "$APP_NAME" ]; then
        echo "ERROR: PID $INPUT not found."
        exit 1
    fi
    if [ "$SCAN_MODE" = "restricted" ]; then
        if ! grep -q "^  - $APP_NAME$" "$CONFIG"; then
            echo "ERROR: App '$APP_NAME' (PID $INPUT) not in allowed list."
            exit 1
        fi
    fi
    exec "$TOOL_DIR/ui_scan" "$INPUT"
fi

if [ -f "$INPUT" ]; then
    REAL_PATH=$(realpath "$INPUT")
    
    while IFS= read -r denied; do
        denied=$(echo "$denied" | sed 's/^[[:space:]]*- //')
        if [[ "$REAL_PATH" == "$denied"* ]]; then
            echo "ERROR: Path in denied list."
            exit 1
        fi
    done < <(grep -A100 "denied_paths:" "$CONFIG" | grep "^  -")
    
    if [ "$SCAN_MODE" = "restricted" ]; then
        ALLOWED=false
        while IFS= read -r allowed; do
            allowed=$(echo "$allowed" | sed 's/^[[:space:]]*- //')
            if [[ "$REAL_PATH" == "$allowed"* ]]; then
                ALLOWED=true
                break
            fi
        done < <(grep -A100 "allowed_paths:" "$CONFIG" | grep "^  -")
        
        if [ "$ALLOWED" = false ]; then
            echo "ERROR: Path not in allowed list."
            exit 1
        fi
    fi
    
    exec "$TOOL_DIR/ocr_vision" "$INPUT"
fi

if [ "$SCAN_MODE" = "restricted" ]; then
    if ! grep -q "^  - $INPUT$" "$CONFIG"; then
        echo "ERROR: App '$INPUT' not in allowed list."
        exit 1
    fi
fi
exec "$TOOL_DIR/ui_scan" "$INPUT"
SCRIPT
chmod +x "$INSTALL_DIR/scan_all"

echo "[4/4] 권한 설정 가이드..."
echo ""
echo "=== 설치 완료 ==="
echo "ocr_vision: $INSTALL_DIR/ocr_vision"
echo "ui_scan:    $INSTALL_DIR/ui_scan"
echo "scan_all:   $INSTALL_DIR/scan_all"
echo "config:     $INSTALL_DIR/config.yml"
echo ""
echo "⚠️  권한 설정 필요:"
echo "  1. 시스템 설정 → 개인정보 보호 및 보안"
echo "  2. 화면 녹화 → 터미널/OpenClaw 허용 (ocr_vision용)"
echo "  3. 손쉬운 사용 → 접근성 → 터미널/OpenClaw 허용 (ui_scan용)"
echo ""
echo "GitHub: https://github.com/graychaos44/ocr-vision"