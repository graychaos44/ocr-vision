# OCR Vision Tool Upgrade - 작업 메뉴얼

## 📋 프로젝트 개요

### 목표
현재 ocr_vision의 UI 요소 구분 기능을 개선하여 스크린샷/화면 스캔에서 UI 요소를 더 정확하게 구분

### 제약 조건
- AI 모델 사용 ❌
- 유료 서비스 ❌
- 오픈소스 ✅
- 가볍고 빠름 ✅
- 스크린샷/화면 스캔 전용 ✅

## 🎯 업그레이드 범위

### 현재 기능
- 텍스트 OCR (VNRecognizeTextRequest)
- 사각형 감지 (VNDetectRectanglesRequest)
- 바코드/QR 감지 (VNDetectBarcodesRequest)
- 이미지 분류 (VNClassifyImageRequest)
- 색상 추출 (CIFilter)

### 개선 필요 기능
- UI 요소 타입 구분 (버튼/입력창/메뉴 등)
- 텍스트와 UI 요소 결합
- UI 요소 그룹화/레이아웃 파악

## 🚀 업그레이드 방안

### 1단계: VNDetectRectanglesRequest 튜닝

#### 목표
사각형 감지 파라미터 최적화로 UI 요소 비율 기반 분류

#### 구현 내용
```swift
// 파라미터 최적화
rectRequest.minimumAspectRatio = 0.5  // 버튼 비율
rectRequest.maximumAspectRatio = 3.0  // 입력창 비율
rectRequest.minimumSize = 0.01        // 작은 요소 필터링
rectRequest.quadratureTolerance = 0.2  // 정확도 향상
```

#### 예상 결과
- 버튼/입력창 비율 기반 구분
- 작은 노이즈 필터링
- 감지 정확도 10-15% 향상

### 2단계: 색상 기반 UI 요소 분류

#### 목표
UI 요소별 색상 패턴 학습 및 자동 분류

#### 구현 내용
```swift
// 색상 기반 분류
// 버튼: 파란색(#007AFF), 초록색(#34C759), 회색(#8E8E93)
// 입력창: 흰색(#FFFFFF), 회색(#F2F2F7)
// 경고: 빨간색(#FF3B30), 노란색(#FFCC00)
```

#### 예상 결과
- 색상 기반 UI 요소 타입 추정
- 버튼/입력창/경고 구분
- 분류 정확도 60-70%

### 3단계: 텍스트 + 사각형 결합 분석

#### 목표
텍스트 위치와 사각형 매칭으로 UI 요소 패턴 인식

#### 구현 내용
```swift
// 텍스트가 사각형 안에 있는지 확인
// 버튼 패턴: [사각형 + 텍스트 + 특정 색상]
// 입력창 패턴: [사각형 + 텍스트 입력 가능 + 흰색]
```

#### 예상 결과
- 텍스트와 UI 요소 결합
- 버튼 텍스트 vs 라벨 텍스트 구분
- 패턴 인식 정확도 70-80%

### 4단계: ui_scan과 결합

#### 목표
AXRole 정보 활용으로 더 정확한 UI 요소 타입 파악

#### 구현 내용
```swift
// ui_scan의 AXRole 정보와 결합
// AXButton → 버튼
// AXTextField → 입력창
// AXStaticText → 라벨
```

#### 예상 결과
- 접근성 API 기반 정확한 타입 파악
- ocr_vision과 ui_scan 결과 통합
- 최종 정확도 80-90%

## 📊 예상 성능

### 속도
- 현재: ~0.7초
- 목표: ~1초 이내

### 리소스
- RAM: 0 (시스템 프레임워크)
- GPU: 0% (하드웨어 가속)

### 정확도
- 현재: 기본적 사각형 감지
- 목표: UI 요소 구분 70-80% 개선

### 비용
- 완전 무료 (오픈소스)

## 🔧 구현 순서

1. **VNDetectRectanglesRequest 파라미터 튜닝**
   - ocr_vision.swift 수정
   - 파라미터 최적화
   - 테스트 및 검증

2. **색상 기반 UI 요소 분류**
   - 색상 분류 함수 추가
   - UI 요소별 색상 패턴 정의
   - 테스트 및 검증

3. **텍스트 + 사각형 결합 분석**
   - 텍스트-사각형 매칭 로직
   - UI 요소 패턴 인식
   - 테스트 및 검증

4. **ui_scan과 결합**
   - 두 결과 통합 함수
   - AXRole 정보 활용
   - 최종 테스트 및 검증

## 📝 작업 로그

### 2026-05-03
- 작업 메뉴얼 작성 완료
- 이슈 생성 완료 (#1)
- 작업 시작 대기

## 🔗 관련 링크

- GitHub: https://github.com/graychaos44/ocr-vision
- Issue: https://github.com/graychaos44/ocr-vision/issues/1
- Apple Vision Framework: https://developer.apple.com/documentation/vision

## 📄 라이선스

MIT