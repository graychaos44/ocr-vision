#!/bin/bash
# JARVIS Vision Tools - 통합 설치 스크립트
# ocr_vision + ui_scan + scan_all

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-/usr/local/bin}"

echo "=== JARVIS Vision Tools 설치 ==="
echo "설치 경로: $INSTALL_DIR"

# Swift 컴파일
echo "[1/3] ocr_vision 컴파일 중..."
swiftc -O -o "$INSTALL_DIR/ocr_vision" "$SCRIPT_DIR/ocr_vision.swift"

echo "[2/3] ui_scan 컴파일 중..."
swiftc -o "$INSTALL_DIR/ui_scan" "$SCRIPT_DIR/ui_scan.swift" -framework ApplicationServices -framework AppKit

echo "[3/3] scan_all 스크립트 설치 중..."
cat > "$INSTALL_DIR/scan_all" << 'SCRIPT'
#!/bin/bash
# JARVIS Vision Tools - 자동 선택 래퍼
# 이미지 파일 → ocr_vision, 앱 이름/PID → ui_scan

TOOL_DIR="$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: scan_all <image_path|app_name|pid>"
    echo ""
    echo "이미지 파일 경로를 주면 ocr_vision 실행"
    echo "앱 이름이나 PID를 주면 ui_scan 실행"
    echo ""
    echo "Examples:"
    echo "  scan_all /path/to/screenshot.jpg   # 이미지 OCR"
    echo "  scan_all Finder                     # 앱 UI 스캔"
    echo "  scan_all 1234                       # PID로 스캔"
    exit 1
fi

INPUT="$1"

# 숫자면 PID로 간주
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    exec "$TOOL_DIR/ui_scan" "$INPUT"
fi

# 파일이 존재하면 이미지로 간주
if [ -f "$INPUT" ]; then
    exec "$TOOL_DIR/ocr_vision" "$INPUT"
fi

# 그 외는 앱 이름으로 간주
exec "$TOOL_DIR/ui_scan" "$INPUT"
SCRIPT
chmod +x "$INSTALL_DIR/scan_all"

echo ""
echo "=== 설치 완료 ==="
echo "ocr_vision: $INSTALL_DIR/ocr_vision"
echo "ui_scan:    $INSTALL_DIR/ui_scan"
echo "scan_all:   $INSTALL_DIR/scan_all"
echo ""
echo "권한 설정 필요:"
echo "  시스템 설정 → 개인정보 보호 및 보안 →"
echo "  화면 녹화 + 접근성 → 터미널/OpenClaw 허용"