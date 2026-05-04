# 📻 레트로 라디오

> MADCAMP Week 2 — Flutter × NestJS × pgvector

---

## 프로젝트 개요

레트로 라디오 컨셉의 Flutter 앱으로, 회원가입 · 로그인 · 오늘의 위로 메시지 기능을 제공합니다.

---
## 👥 Team

| Role | Name | Role |
| :--- | :--- | :--- |
| **Frontend Developer** | **이준엽** | "School of Technology Management, Korea Advanced Institute of Science and Technology" |
| **Backend Developer** | **임유진** | "Dept. of Computer Science & Engineering, POSTECH" |

---

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| **Frontend** | Flutter (Dart) |
| **Backend** | NestJS (TypeScript) |
| **ORM** | Prisma |
| **Embedding Service** | Python (FastAPI) |
| **AI 모델** | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` |
| **Database** | PostgreSQL 16 + pgvector |
| **Infra** | Docker, Docker Compose |

---

## 시스템 아키텍처

```
Flutter App
    │
    ▼ HTTP
NestJS Backend (:3000)
    │                   │
    ▼ SQL+vector        ▼ HTTP
PostgreSQL+pgvector   Embedding Service (:8000)
(:5433)               paraphrase-multilingual-MiniLM-L12-v2
```

Docker Compose로 구성된 4개 서비스:

| 서비스 | 포트 | 설명 |
|--------|------|------|
| `db` | 5433 | PostgreSQL 16 + pgvector |
| `backend` | 3000 | NestJS API 서버 |
| `embedding-service` | 8000 | 문장 임베딩 마이크로서비스 |
| `studio` | 5555 | Prisma Studio (DB GUI) |

---

## 주요 기능

### 인증
- 회원가입 (Sign Up)
- 로그인 (Login)

### 오늘의 위로 메시지
- 저장된 위로 중 하나의 위로를 사용자에게 하루에 한 개로 한정하여 표시

### 임베딩 기반 유사도 검색
- `paraphrase-multilingual-MiniLM-L12-v2` 모델로 텍스트를 벡터로 변환
- PostgreSQL pgvector 확장을 통해 벡터 유사도 검색 수행
- 본인이 작성한 사연과 유사한 내용을 기반으로 표시

---

## 실행 방법

### 사전 요구사항
- Docker & Docker Compose
- Flutter SDK
- Node.js 18+

### 1. 환경변수 설정

```bash
cp backend/.env.example backend/.env
# .env 파일 내 DB 정보 및 시크릿 키 입력
```

### 2. 백엔드 서비스 실행

```bash
docker compose up --build
```

### 3. DB 마이그레이션

```bash
cd backend
npx prisma migrate dev
```

### 4. Flutter 앱 실행

```bash
cd frontend
flutter pub get
flutter run
```

> **참고 — Flutter 재실행 방식**
> - Hot reload (`r`): UI · 로직 업데이트, 상태 유지
> - Hot restart (`R`): 상태 초기화, 네이티브 코드 제외
> - Full rebuild: `pubspec.yaml`에 에셋 추가 후 `flutter pub get` 후 Hot restart 필요

### 앱 아이콘 변경

```bash
# assets/icon/app_icon.png 교체 후
flutter pub get
dart run flutter_launcher_icons
```

---

## 프로젝트 구조

```
MADCAMP_WK2/
├── frontend/           # Flutter 앱 (Dart)
├── backend/            # NestJS API 서버 (TypeScript) + Prisma
├── embedding_service/  # 임베딩 마이크로서비스 (Python)
└── docker-compose.yml  # 전체 서비스 오케스트레이션
```

---
