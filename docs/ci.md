# Spreader CI / CD 가이드

> 최신 GitHub Actions 워크플로·Fly 배포 파이프라인 기준 (2025-06)

## 1. GitHub Actions 워크플로 개요

| 파일 | Job | 기능 |
|------|-----|------|
| `.github/workflows/ci.yml` | **test** | OTP 26 / Elixir 1.16.2 환경에서 `mix test` 수행 (Postgres 15 서비스 포함) |
| | **lint** | `mix lint`(Credo + Dialyzer) 실행. Credo Design(D) 카테고리는 무시하므로 정합성 문제만 실패 처리 |
| `.github/workflows/fly-deploy.yml` | **deploy** | `main` 브랜치 푸시/태그 시 Docker 이미지를 빌드, `/app/bin/migrate` 실행 후 Fly.io 배포 |

### 주요 설정 포인트

1. **Postgres Health-check**
   ```yaml
   options: >-
     --health-cmd="pg_isready -U postgres"
     --health-interval 10s
     --health-timeout 5s
     --health-retries 5
   ```
   `--health-cmd` 전체를 따옴표로 감싸야 `-U` 플래그 파싱 오류를 방지합니다.

2. **OTP / Elixir 설치** – `erlef/setup-beam@v1` 사용. 기본 이미지(ubuntu-latest)에서도 문제없음.

3. **의존성 캐시**
   ```yaml
   actions/cache@v3
   key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
   paths: |
     deps
     _build
   ```

4. **Fly 배포**
   * `fly.toml` →
     ```toml
     [build]
       dockerfile = "Dockerfile"
     release_command = "/app/bin/migrate"
     ```
   * 필수 GitHub Secret: `FLY_API_TOKEN`
   * 앱 Secret은 `fly pg attach` 로 자동 세팅 (`DATABASE_URL`)

## 2. 로컬 CI 시뮬레이션 (act)

```bash
brew install act
act -j test \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04
```

`act-22.04`(large) 이미지에는 OTP/Elixir가 포함되어 있어 별도 설정이 필요 없습니다.

## 3. Fly Postgres 운영

* 클러스터: `spreader-db`
* 앱에 연결
  ```bash
  fly pg attach spreader-db -a spreader --database-name spreader
  ```
* DB가 없으면 위 명령이 자동 생성. 수동 생성은:
  ```bash
  fly pg connect -a spreader-db -c 'CREATE DATABASE spreader;'
  ```

## 4. 문제 해결 Quick Reference

| 증상 | 조치 |
|------|------|
| Docker health-check 실패 | `pg_isready` 문자열 전체가 인용부호로 감싸졌는지 확인 |
| 배포 중 `invalid_catalog_name` | `DATABASE_URL` 이 `/spreader` 로 끝나는지 및 DB 존재 여부 확인 |
| `No buildpacks configured` | `fly.toml` 의 `[build] dockerfile` 설정 확인 |
| act 러너에서 Elixir 없음 | `act-22.04` 이미지 사용 또는 커스텀 이미지 준비 |
| Credo Design 경고로 CI 실패 | 이미 무시 설정됨 – `mix lint` alias 참고 |

## 5. 버전 업데이트 절차

1. `.tool-versions` 수정(로컬 개발용)
2. `ci.yml` 의 두 `setup-beam` 블록 `otp-version` / `elixir-version` 동기화
3. PR → CI 통과 확인 후 병합

---

이 문서는 `docs/ci.md` 에 위치하며, 변경 시 팀에 공유해주세요.
