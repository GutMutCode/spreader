# Spreader 배포 가이드 (Fly.io + asdf)

이 문서는 **Spreader** Phoenix 애플리케이션을 Fly.io 에 배포하기 위해 실제로 수행한 전체 절차를 기록합니다. 처음부터 재현하거나 팀원 ‧ CI/CD 환경에 적용할 때 참고하세요.

---

## 1. 사전 요구 사항

| 항목 | 버전 / 비고 |
|------|--------------|
| macOS/Linux 셸 | `zsh` 또는 `bash` |
| [asdf](https://asdf-vm.com/) | 0.13 이상 (버전 관리) |
| Erlang/OTP | 26.2.2 |
| Elixir | 1.16.2-otp-26 |
| Fly CLI | `flyctl v0.2xx` 이상 |
| GitHub 저장소 | Actions 사용 가능 |

```bash
# asdf 설치 후 전역 설치 & 플러그인 추가
brew install asdf
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
```

---

## 2. 로컬 환경 설정

1. 프로젝트 루트에 **`.tool-versions`** 작성
   ```
   erlang 26.2.2
   elixir 1.16.2-otp-26
   ```
2. 원하는 버전 설치
   ```bash
   asdf install
   asdf local erlang 26.2.2
   asdf local elixir 1.16.2-otp-26
   ```
3. 셸 PATH 우선순위 확인
   ```bash
   echo '. "$(brew --prefix asdf)/libexec/asdf.sh"' >> ~/.zshrc
   export PATH="$HOME/.asdf/shims:$PATH"
   exec $SHELL -l
   elixir -v  # → 1.16.2
   ```

---

## 3. Fly 조직 및 앱 초기화

### 3-1. 조직 확인
```bash
fly orgs list            # Personal / Spreader 확인
```

### 3-2. 새 Phoenix 앱 생성 (Spreader 조직)
```bash
fly apps create spreader -o spreader
```

### 3-3. Dockerfile & fly.toml 생성
```bash
fly launch --no-deploy -o spreader --name spreader --region nrt
```
* `--no-deploy` 로 초기 파일만 생성하고 배포는 건너뜀
* `fly.toml` 의 `primary_region` / `PHX_HOST` 등을 확인

---

## 4. Postgres 클러스터 생성 & 연결

```bash
fly postgres create \
  --name spreader-db \
  --org spreader \
  --region nrt \
  --vm-size shared-cpu-1x \
  --volume-size 10 \
  --initial-cluster-size 1 \
  --password postgres

# 애플리케이션에 DATABASE_URL 시크릿 자동 주입
fly pg attach --app spreader spreader-db
```

> `fly pg attach` 는 DB 사용자/비밀번호·DB명까지 자동 생성해 `DATABASE_URL` 시크릿으로 저장합니다.

---

## 5. 애플리케이션 시크릿 추가

```bash
fly secrets set \ 
  GOOGLE_CLIENT_ID="<ID>" \ 
  GOOGLE_CLIENT_SECRET="<SECRET>" \ 
  SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -a spreader
```

---

## 6. 첫 배포

```bash
fly deploy --remote-only -a spreader
```
* 원격 빌더에서 Docker 이미지 빌드 → 릴리스 생성 → 머신 배포
* 배포 후 `https://spreader.fly.dev` 접속하여 기본 Phoenix 페이지 및 Google OAuth 링크 정상 동작 확인

---

## 7. CI/CD 구성 (GitHub Actions)

* **`.github/workflows/ci.yml`** – 모든 PR/푸시에서 Elixir 1.16 + Postgres 서비스 컨테이너로 `mix test` 실행
* **`.github/workflows/fly-deploy.yml`** – `main` 브랜치 merge 시 `fly deploy --remote-only` 자동 실행 (필요 시 수정)
* **필수 GitHub 시크릿**
  * `FLY_API_TOKEN` – `fly auth token` 으로 발급 후 저장

---

## 8. 조직 이동 & 재배포(선택)

* **Postgres 클러스터는 `apps move` 불가** → 새 클러스터 생성 후 dump/import 필요
* 앱은 `fly apps move <app> -o <org>` 로 이동 가능하지만, 이번 가이드에서는 **처음부터 Spreader 조직으로 배포**해 불필요

---

## 9. 정리 및 참고 링크

* Fly Docs – https://fly.io/docs/ 
* Phoenix Guides – https://hexdocs.pm/phoenix 
* asdf – https://asdf-vm.com/

> 질문이나 오류가 있으면 `fly logs -a spreader`, `mix phx.server` 로컬 실행, 또는 Fly 커뮤니티를 참고하세요.
