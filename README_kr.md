|              言語選択              |                 언어선택                 |
| :--------------------------------: | :--------------------------------------: |
| 🇯🇵 [日本語 (README.md)](README.md) | 🇰🇷 [한국어 (README_kr.md)](README_kr.md) |

# smart_kintai

Flutter + Supabase 기반 근무관리(출퇴근) 앱

## 프로젝트 목적

- 이 프로젝트는 바이브코딩(Vibe Coding)을 체험하기 위해 만들어졌습니다.
- AI를 활용함으로써 코딩 자체에 드는 시간은 단축되었습니다.
- 한편, AI에게 적절한 컨텍스트를 제공하는 시간이나, 기대만큼의 코드가 생성되지 않을 때 추가로 작업을 해야 하는 경우도 새롭게 생겼습니다.
- 프로젝트의 규모(코드량, 고려해야 할 도메인)가 커질수록 위와 같은 과정 때문에 바이브코딩 방식이 기존보다 시간이 더 소요될 수 있다고 느꼈습니다.

## 소개

**smart_kintai**는 Flutter와 Supabase를 활용하여 출근/퇴근 기록을 관리하는 간단한 근무관리 앱입니다.  
로그인/회원가입, 출근/퇴근 기록, ID 저장, 세션 만료 처리 등 기본적인 기능을 제공합니다.

## 주요 기능

- **회원가입/로그인**: Supabase 인증을 이용한 이메일 기반 회원가입 및 로그인
- **ID 저장**: 로그인 시 이메일(ID) 저장 기능 (SharedPreferences 사용)
- **출근/퇴근 기록**: 버튼 클릭으로 출근/퇴근 기록을 Supabase DB에 저장
- **오늘의 출근상태 조회**: 앱 실행 시 오늘의 마지막 출근/퇴근 상태 자동 조회
- **세션 만료/로그아웃**: 세션 만료 시 안내 및 재로그인 유도, 로그아웃 기능 제공
- **Flutter Cupertino 스타일 UI**: iOS 스타일의 깔끔한 UI 적용(일부 shadcn 사용)

## 사용 기술

- Flutter 3.32.6
- Supabase (인증, DB)
- shadcn_flutter (UI 컴포넌트)
- shared_preferences (로컬 저장)
- flutter_dotenv (환경변수 관리)

## 실행 방법

1. `.env` 파일에 Supabase 프로젝트의 URL과 anon key를 입력합니다.
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
2. 패키지 설치
   ```
   flutter pub get
   ```
3. 앱 실행
   ```
   flutter run
   ```

## 주요 화면

- **로그인/회원가입**

  - 이메일, 비밀번호 입력
  - ID 저장 스위치
  - 로그인/회원가입 버튼

- **메인(근무관리)**
  - 출근/퇴근 버튼 (상태에 따라 변경)
  - 상단 로그아웃 버튼

## 테이블 구조 예시 (Supabase)

- `kintai_start_end`
  - `id`: PK
  - `uid`: 유저 ID (auth의 user.id)
  - `is_start`: bool (true: 출근, false: 퇴근)
  - `created_at`: timestamp

## 참고

- Flutter, Supabase 공식 문서 참고
- shadcn_flutter: https://pub.dev/packages/shadcn_flutter

## 라이선스

MIT
