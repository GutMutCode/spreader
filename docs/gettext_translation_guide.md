# 국제화(i18n) & Gettext 번역 가이드

Spreader Phoenix 프로젝트에서 **번역 문자열을 추가·수정**하는 방법을 단계별로 정리했습니다. Gettext 경험이 없어도 그대로 따르면 됩니다.

---

## 1. 용어 정리
| 용어 | 설명 |
|------|---------|
| *msgid* | 원본 문자열(보통 영어). |
| *msgstr* | 특정 언어로 번역된 문자열. |
| *.pot*  | 소스 코드를 스캔해 자동 생성되는 템플릿 파일. |
| *.po*   | 각 언어별 번역 파일(예: `ko`, `en`). |

---

## 2. 프로젝트 구조
```
priv/
└── gettext/
    ├── default.pot                     # Auto-generated template
    └── ko/                             # Locale directory (ko = Korean)
        └── LC_MESSAGES/
            ├── default.po              # Our translations live here
            └── errors.po               # Phoenix standard error messages
```

> 다른 언어를 추가하려면 `ko` 대신 원하는 언어 코드(예: `en`, `ja`)로 디렉터리를 생성하세요.

---

## 3. 번역 대상 문자열 추가
1. 1. 템플릿·코드에서 `gettext/1`, `ngettext/3` 등을 사용해 문자열을 작성합니다. 예시(HEEx):
   ```elixir
   <%= gettext("Terms of Service") %>
   ```
2. 2. 해당 템플릿을 포함하는 모듈이 Gettext 백엔드를 import 했는지 확인합니다:
   ```elixir
   defmodule SpreaderWeb.TermsHTML do
     use SpreaderWeb, :html
     import SpreaderWeb.Gettext     # <-- required
     embed_templates "terms_html/*"
   end
   ```

---

## 4. POT/PO 파일 추출·병합
프로젝트 루트에서 실행:
```bash
mix gettext.extract                       # ❶ scan code → priv/gettext/default.pot
mix gettext.merge priv/gettext --locale ko # ❷ update ko translations
```
노트:
* 새로운 `gettext/…` 문자열을 추가할 때마다 **`mix gettext.extract`** 를 실행합니다.
* 지원하는 각 언어마다 **`mix gettext.merge … --locale <lang>`** 명령을 실행합니다.

---

## 5. 번역 파일(.po) 수정
다음 명령으로 번역 파일을 엽니다.
```bash
vim priv/gettext/ko/LC_MESSAGES/default.po
```
다음과 같은 항목을 찾습니다:
```
msgid "Terms of Service"
msgstr ""
```
`msgstr` 에 번역을 입력합니다:
```
msgstr "서비스 이용약관"
```
파일을 저장합니다.

### 빠른 팁
* `#:` 로 시작하는 줄은 해당 문자열의 **출처(파일:라인)** 를 보여줍니다.
* `msgstr ""` 를 비워두면 *미번역* 으로 간주되어 화면에 `msgid` 가 그대로 표시됩니다.
* 번역이 확실하지 않으면 `#, fuzzy` 태그를 추가할 수 있습니다.

---

## 6. 컴파일 및 확인
```bash
mix compile      # ❸ recompile project + PO files
```
원하는 로케일로 페이지를 열어 확인합니다. 예:
```
/gmc/terms/ko     # internal dev route
```
번역된 문자열이 표시되어야 합니다.

---

## 7. 새 언어 추가
1. **로케일 디렉터리와 PO 파일 생성**:
   ```bash
   mix gettext.merge priv/gettext --locale en
   ```
2. 새로 생성된 `priv/gettext/en/LC_MESSAGES/*.po` 파일을 편집합니다.
3. `mix compile` 후 `/gmc/terms/en` 등으로 확인합니다.

---

## 8. 자주 발생하는 문제
| 증상 | 해결책 |
|---------|-----|
| 템플릿에서 `undefined function gettext/1` 오류 | 뷰 모듈(예: `TermsHTML`)에 `import SpreaderWeb.Gettext` 가 있는지 확인합니다. |
| .pot 에 문자열이 보이지 않음 | 문자열을 추가한 뒤 `mix gettext.extract` 를 실행했는지 확인합니다. |
| 런타임에서 변경 사항이 반영되지 않음 | `mix compile` 을 다시 실행하거나 `iex -S mix phx.server` 를 재시작합니다. |

---

## 9. 자동화 아이디어
아래 **mix alias** 를 `mix.exs` 에 추가하면 추출·병합 과정을 간소화할 수 있습니다:
```elixir
aliases: [
  "i18n.update": [
    "gettext.extract --merge",
    "gettext.merge priv/gettext --locale ko",
    "gettext.merge priv/gettext --locale en"
  ]
]
```
이후 문자열이 변경될 때마다 `mix i18n.update` 한 번으로 처리할 수 있습니다.

---

## 10. 추가 자료
* [Gettext HexDocs](https://hexdocs.pm/gettext)
* [Phoenix i18n Guide](https://hexdocs.pm/phoenix/i18n.html)

즐거운 번역 되세요!
