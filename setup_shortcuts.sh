#!/bin/bash
# JARVIS Vision Tools - 단축키 설정 스크립트

TOOL_DIR="$(dirname "$0")"
SHORTCUT_PLIST="$HOME/Library/Services/jarvis-screenshot.workflow"

echo "JARVIS Vision Tools - 단축키 설정"
echo ""

# 기존 단축키 삭제
echo "기존 단축키 삭제 중..."
defaults delete com.apple.services "jarvis-screenshot" 2>/dev/null
echo "완료"
echo ""

# 새로운 단축키 설정
echo "새로운 단축키 설정 중..."

# Automator 워크플로우 생성
WORKFLOW_DIR="$HOME/Library/Services"
mkdir -p "$WORKFLOW_DIR"

# 부분 크롭 워크플로우
cat > "$WORKFLOW_DIR/jarvis-partial.workflow/Contents/document.wflow" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>jarvis-partial</string>
            </dict>
            <key>NSKeyEquivalent</key>
            <dict>
                <key>default</key>
                <string>~@v</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "단축키 설정 완료!"
echo ""
echo "설정된 단축키:"
echo "  ⌘⇧⌥V  - 부분 크롭 (기본)"
echo "  ⌘⇧⌥F  - 전체 화면"
echo "  ⌘⇧⌥W  - 활성 창"
echo ""
echo "단축키가 작동하지 않으면 다음을 확인하세요:"
echo "1. 시스템 설정 → 키보드 → 단축키 → 서비스"
echo "2. 'JARVIS Vision Tools' 항목 확인"
echo "3. 단축키가 겹치지 않는지 확인"
echo ""
echo "설정을 적용하려면 로그아웃 후 다시 로그인하세요."