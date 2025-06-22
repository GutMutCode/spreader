# Instagram Graph API – Content Publishing Prerequisites

> Last updated: 2025-06-20

This guide summarises everything **Spreader** must have in place to upload photos or videos to Instagram programmatically via the **Instagram Graph API** (part of Meta / Facebook).

---

## 1. App Creation & Product Setup (Meta for Developers)

1. Go to the **Meta for Developers** portal <https://developers.facebook.com/> and *Create App* (`Business` app type is recommended).
2. Add the **Instagram Graph API** product to the app dashboard.
3. Note the following credentials (store securely):
   * **App ID**
   * **App Secret**
4. In *App Review → Permissions & Features* request the following:
   * `instagram_basic`
   * `instagram_content_publish`
   * `pages_show_list` (to list connected Pages)
   * `ads_management` (only if you plan to boost posts)
5. Provide the required screencast / screengrabs for Meta review.
6. Under *Basic Settings* add **Valid OAuth Redirect URIs** (e.g. `https://spreader.io/auth/instagram/callback`).

## 2. Instagram Account & Facebook Page Requirements

* An **Instagram Business** or **Creator** account.
* A **Facebook Page** that is linked to the Instagram account in Page *Settings → Linked Accounts*.
* The user performing OAuth must have the `ADMIN` role on the Page.

## 3. Environment Variables

Add the following keys to `.env` (do **NOT** commit real values):

```dotenv
# Instagram / Facebook Graph
FACEBOOK_APP_ID=""
FACEBOOK_APP_SECRET=""
INSTAGRAM_REDIRECT_URI="https://spreader.io/auth/instagram/callback"

# Will be populated after OAuth
IG_USER_ID=""          # Numeric Instagram Business Account ID
FACEBOOK_PAGE_ID=""    # Connected Page ID
IG_ACCESS_TOKEN=""     # Long-Lived User Token (can be refreshed)
```

## 4. Content Publishing Flow (Photo / Video)

1. **OAuth Login** – User authorises with scopes `instagram_basic, instagram_content_publish, pages_show_list`.
2. **Long-Lived Token** – Exchange short-lived token for long-lived (valid ~60 days) via `GET /oauth/access_token`.
3. **Get IG User ID** – `GET /{page-id}?fields=instagram_business_account`.
4. **Create Media Container**
   * **Photos:** `POST /{ig-user-id}/media` with `image_url`, `caption` (optional) and `is_carousel_item` (optional).
   * **Videos:** Two step upload –
     1. `POST /{ig-user-id}/media` with `video_url`, `caption` and `media_type=VIDEO` → returns *container ID*.
     2. Poll `GET /{container-id}` until `status_code == FINISHED`.
5. **Publish Media** – `POST /{ig-user-id}/media_publish` with `creation_id={container-id}`.
6. **Inspect Result** – response returns the new *Media ID*; fetch insights or comments via `/media_id?fields=…`.

### Rate Limits & Constraints

| Type      | Limit |
|-----------|-------|
| Photo size | ≤ 8 MB, JPEG preferred |
| Video size | ≤ 100 MB, ≤ 60 sec, MP4 (H.264/AAC) |
| Publish frequency | 25 single-media posts within a rolling 24 h window per IG Business Account |
| Captions | ≤ 2,200 characters |

## 5. Webhooks (Optional)

Subscribe to *Instagram* Webhooks for `comments`, `mentions`, etc. via the **Webhook** product; set callback URL and verify token.

## 6. Non-functional Notes

* **Token Refresh** – Use `GET /oauth/access_token?grant_type=fb_exchange_token` to extend tokens; or generate System User Token if desired.
* **Sandbox Mode** – New apps start in *Development* mode; only listed testers can publish until the app goes *Live*.
* **Error Handling** – Handle `190` (token), `4` (rate limit) and `10` (permission) error codes.
* **Compliance** – Follow Instagram Platform Policy, especially content / brand usage rules.

## 7. Useful Links

* Product Docs – <https://developers.facebook.com/docs/instagram-api>
* Content Publishing – <https://developers.facebook.com/docs/instagram-api/guides/content-publishing>
* Media Upload – <https://developers.facebook.com/docs/instagram-api/guides/publishing-media>
* Permissions – <https://developers.facebook.com/docs/instagram-api/reference/user#permissions>

---

## 8. Next Steps for Implementation

1. Add `InstagramAuthController` to start OAuth and handle callback.
2. Store long-lived tokens and account IDs securely.
3. Build `Instagram.Client` wrapper (HTTP) using `Finch`/`Tesla`.
4. Implement `Instagram.Uploader` module (photo, video, carousel).
5. Add background job support for video polling (Oban).
6. Write integration tests using Sandbox mode accounts.
