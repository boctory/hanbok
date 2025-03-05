# 한복 AI - Hanbok AI Application

한복 AI는 한국 전통 의상인 한복의 아름다움을 알리고, 사용자가 한복을 입은 모습을 AI로 생성할 수 있는 애플리케이션입니다.

## 주요 기능

- 사용자 사진 업로드 (카메라 또는 갤러리에서 선택)
- 다양한 한복 모델 중 선택
- AI를 통한 한복 이미지 생성 (경복궁 배경)
- 생성된 이미지 저장 및 공유
- 개인 갤러리에서 생성된 이미지 관리

## 기술 스택

- Flutter 프레임워크
- Dart 언어
- Kling AI API 연동
- 반응형 디자인 (모바일, 태블릿, 웹 지원)

## 설치 방법

1. Flutter 개발 환경 설정
   ```
   https://flutter.dev/docs/get-started/install
   ```

2. 프로젝트 클론
   ```
   git clone https://github.com/yourusername/hanbok_app.git
   cd hanbok_app
   ```

3. 의존성 패키지 설치
   ```
   flutter pub get
   ```

4. `.env` 파일 설정
   ```
   API_BASE_URL=https://api.klingai.com/v1
   API_KEY=your_kling_ai_api_key_here
   STORAGE_URL=https://storage.klingai.com
   ```

5. 애플리케이션 실행
   ```
   flutter run
   ```

## 프로젝트 구조

```
lib/
  ├── constants/       # 앱 상수 및 테마 정의
  ├── models/          # 데이터 모델 클래스
  ├── screens/         # 화면 UI 구현
  ├── services/        # API 및 저장소 서비스
  ├── utils/           # 유틸리티 함수
  ├── widgets/         # 재사용 가능한 위젯
  └── main.dart        # 앱 진입점
```

## 스크린샷

(스크린샷 이미지 추가 예정)

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 LICENSE 파일을 참조하세요.

## 기여 방법

1. 이 저장소를 포크합니다.
2. 새 기능 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`).
3. 변경 사항을 커밋합니다 (`git commit -m 'Add some amazing feature'`).
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`).
5. Pull Request를 생성합니다.

## 연락처

프로젝트 관리자 - [@yourusername](https://github.com/yourusername) - email@example.com

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
