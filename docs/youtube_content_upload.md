# YouTube Data API – Video Upload Prerequisites

> Last updated: 2025-06-22

This document summarises what **Spreader** needs to upload videos to **YouTube** on behalf of users via the **YouTube Data API v3**.

---

## 1. Google Cloud Project & API Enablement

1. Open the **Google Cloud Console** <https://console.cloud.google.com/> and **create a new project** (or choose an existing one).
2. In **APIs & Services → Library** search for **YouTube Data API v3** and **Enable** it.
3. In **APIs & Services → OAuth consent screen**:
   * Choose *External* user type (unless you only need *Internal* within your org).
   * Add the **YouTube Data API** scopes you will request (`https://www.googleapis.com/auth/youtube.upload`).
   * Add application branding and test users until the app is *Published*.
4. In **Credentials → Create Credentials → OAuth 2.0 Client IDs**:
   * Choose **Web application**.
   * Add authorised **Redirect URIs** (e.g. `https://spreader.io/auth/youtube/callback`).
   * Note the generated **Client ID** and **Client Secret**.

## 2. YouTube Channel Requirements

* The Google account must have an active **YouTube channel** (create one if absent).
* The channel must be **verified** and in good standing to upload videos over 15 minutes.
* Daily upload limits depend on account reputation and may vary.

## 3. Environment Variables

Add the following to `.env` (do **NOT** commit secrets):

```dotenv
# YouTube Data API
YT_CLIENT_ID=""
YT_CLIENT_SECRET=""
YT_REDIRECT_URI="https://spreader.io/auth/youtube/callback"

# Populated after OAuth
YT_ACCESS_TOKEN=""
YT_REFRESH_TOKEN=""
YT_SCOPE="https://www.googleapis.com/auth/youtube.upload"
```

## 4. High-level Upload Flow

```text
Browser ──▶ Spreader Backend ──▶ Google OAuth 2 ──▶ Spreader Backend ──▶ YouTube API
   1. user consent        2. code ↦ tokens            3. resumable upload
```

1. **OAuth 2.0 Authorisation Code flow** with scope `youtube.upload`.
2. Exchange the **code** for **access_token + refresh_token** at `POST /oauth2/v4/token`.
3. **Initiate a resumable upload**:

   ```http
   POST https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status
   Authorization: Bearer {access_token}
   Content-Type: application/json; charset=UTF-8

   {
     "snippet": {
       "title": "My demo video",
       "description": "Uploaded via Spreader",
       "tags": ["demo","spreader"],
       "categoryId": "22"   // People & Blogs
     },
     "status": {
       "privacyStatus": "private"
     }
   }
   ```

   The response returns `HTTP 200 OK` with header **`Location:`** – this is the **upload-URL**.

4. **Upload the bytes** in chunks (e.g. 8 MiB) to the received URL using `PUT` with header `Content-Length` & `Content-Range` until `201 Created`.
5. **Check processing status** via `GET https://www.googleapis.com/youtube/v3/videos?part=processingDetails,id&id={videoId}` until `processingDetails.processingStatus == succeeded`.

### Video Constraints (as of 2025-06-22)

* File size ≤ **128 GB** or **12 hours** duration (YouTube hard limit).
* Recommended formats: **MP4** with H.264 video & AAC audio.
* Resolution up to 8K, aspect ratio 16:9 preferred; letterboxing accepted.

## 5. Quota & Rate Limits

* Each `videos.insert` call (upload) costs **1600 quota units**.
* Projects start with **10 000 units/day**. Request more via Google Cloud Console if needed.
* Use the `fields` parameter to fetch only necessary fields and reduce cost elsewhere.

## 6. Non-functional Considerations

* **Resumable Uploads** are strongly recommended; handle `308 Resume Incomplete` to continue.
* **Retry** with exponential back-off on network errors / 5xx according to Google guidelines.
* **Refresh Tokens** usually have no expiry; use them to obtain new access tokens without user interaction.
* **Content ID / Copyright**: Uploads are scanned and may be blocked; handle `youtube.videoAbuseReport` errors.
* **Caption & Thumbnail**: After upload, call `thumbnails.set` or `captions.insert` as needed.

## 7. Useful Links

* API Overview – <https://developers.google.com/youtube/v3>
* Upload Guide – <https://developers.google.com/youtube/v3/guides/uploading_a_video>
* Resumable Protocol – <https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol>
* Quota – <https://developers.google.com/youtube/v3/getting-started#quota>

---

## 8. Next Steps for Implementation

1. Add `YouTubeAuthController` to initiate OAuth and handle callback.
2. Securely store `refresh_token` and channel ID.
3. Implement `YouTube.Client` (Finch/Tesla) to wrap token refresh and resumable uploads.
4. Build `YouTube.Uploader` module with chunked uploads & status polling.
5. Add background worker to monitor processing state (Oban).
6. Add integration tests using a restricted test channel.
