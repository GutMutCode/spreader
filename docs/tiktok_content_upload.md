# TikTok Content Posting API – Prerequisites

> Last updated: 2025-06-20

This document captures everything that **Spreader** needs to have in place **before** we start wiring code to upload videos directly to TikTok using the Content Posting API.

---

## 1. Register & Configure a TikTok App

1. Sign-in at the TikTok **Developer Center** (https://developers.tiktok.com/).  
2. **Create a new App** under *My Apps*.
3. Record the following credentials and keep them secret:
   * **Client Key**  (a.k.a. *App ID*)
   * **Client Secret**
4. Under **Products → Content Posting API** request **activation** (approval may take up to a few days).
5. Add your **OAuth Redirect URI** (e.g. `https://spreader.io/auth/tiktok/callback`).  This must exactly match what we pass during the OAuth handshake.
6. After approval, enable the required **permissions / scopes**:
   * `content.upload`
   * `video.upload`
   * `post.publish` (aka *direct_post*)
   * Any additional scopes your use case needs (e.g. `user.info.basic`).

## 2. TikTok Account Requirements

* A **TikTok Business Account** (Personal accounts are not allowed).
* The account must be linked to the App (App → Users tab → *Generate URL* to invite the account owner to authorise).
* The account’s age / region must meet TikTok’s minimums.

## 3. Environment Variables

Create / update `.env` with the following keys so that they are available at runtime (do **NOT** commit actual secrets):

```dotenv
# TikTok Content Posting API
TIKTOK_CLIENT_KEY=""
TIKTOK_CLIENT_SECRET=""
TIKTOK_REDIRECT_URI="https://spreader.io/auth/tiktok/callback"

# Populated after OAuth
TIKTOK_ACCESS_TOKEN=""
TIKTOK_REFRESH_TOKEN=""
TIKTOK_SCOPE="content.upload,video.upload,post.publish"
```

⚠️  Never hard-code these in Git — keep them in Vault / CI secret store.

## 4. High-level Flow

```text
┌────────────┐      1. Authorisation Code Grant       ┌────────────┐
│  Browser    │  ───────────────────────────────────▶ │   TikTok   │
└────────────┘ ◀───────────────────────────────────   └────────────┘
        │                        │
        ▼                        │
┌───────────────────┐            │
│ Spreader Backend  │────────────┘
└───────────────────┘
        │ 2. exchange code→access_token
        ▼
┌────────────┐
│   TikTok   │
└────────────┘
        │
        ▼ 3. Upload media via multipart (init/part/complete)
┌────────────┐
│   TikTok   │
└────────────┘
        │
        ▼ 4. Create post (direct or scheduled)
┌────────────┐
│   TikTok   │
└────────────┘
```

### End-points Used

| Purpose               | HTTP Method & Path                                   |
|-----------------------|------------------------------------------------------|
| Obtain access token   | `POST /oauth/access_token`                           |
| Init upload session   | `POST /video/upload/init/`                           |
| Upload part(s)        | `POST /video/upload/part/` (repeat per chunk)        |
| Complete upload       | `POST /video/upload/complete/`                       |
| Direct post           | `POST /post/publish/direct/`                         |

*(Exact paths may include version prefixes such as `/v2/` – check latest docs.)*

### Video Constraints (as of 2025-06-20)

* Size ≤ **1 GB**  (better < 500 MB for reliability)
* Duration ≤ **60 sec**
* Formats: **.mp4** or **.mov**
* H.264/AAC, 16:9 or 9:16 recommended.

## 5. Non-functional Considerations

* **Rate limits**:  100 uploads / day / app by default.
* **Sandbox**: A *sandbox* environment is available; use it for automated tests.
* **Retry logic**:  Implement exponential back-off on `500`, `429`, or network errors.
* **Webhooks**:  Optionally receive status updates via `POST /webhook/…` (must be enabled in App settings).
* **GDPR & Data Location**:  Ensure user data processing complies with TikTok’s policies.

## 6. Useful Links

* Getting Started – <https://developers.tiktok.com/doc/content-posting-api-get-started>
* Upload Content – <https://developers.tiktok.com/doc/content-posting-api-get-started-upload-content>
* Media Transfer Guide – <https://developers.tiktok.com/doc/content-posting-api-media-transfer-guide>
* Direct Post Reference – <https://developers.tiktok.com/doc/content-posting-api-reference-direct-post>

---

## 7. Next Steps for Implementation

1. Create OAuth controller (`TikTokAuthController`) to initiate login & handle callback.
2. Persist `access_token` / `refresh_token` in DB or encrypted store.
3. Wrap HTTP calls in service module `TikTok.Client` (use `Finch` or `Tesla`).
4. Build an `Uploader` module that follows *init → part → complete → publish*.
5. Add background job retry (Oban / Exq) for long uploads.
6. Add integration tests against TikTok Sandbox.
