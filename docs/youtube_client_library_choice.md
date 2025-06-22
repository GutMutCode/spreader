# YouTube Data API Client – Library Choice Rationale

> Last updated: 2025-06-22

This note explains **why Spreader uses the official `google_api_youtube` Hex package** instead of implementing raw HTTP calls for YouTube uploads. It aims to provide transparency for current and future contributors.

---

## Evaluated Options

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **Official `google_api_youtube`** | Auto-generated Elixir client from Google’s `elixir-google-api` monorepo. | * Maintained by **Google** – source of truth.<br>* Releases every 4–6 weeks, keeps pace with API spec changes.<br>* Provides all endpoints & types out-of-the-box.<br>* Standard `Tesla` stack for HTTP, benefiting from retries, timeouts, SSL, etc.<br>* Consistent interface shared with other Google APIs. | * Large compile size, +5–10 s initial build.<br>* Auto-generated docs are terse; developers still consult REST docs.<br>* High-level helpers (resumable uploads, retries) still require our own wrapper. |
| **Custom HTTP wrapper** | Build only the endpoints we need (`videos.insert`, token refresh…) with `Finch`/`Tesla`. | * Minimal footprint, faster compile.<br>* Full control over logging & retries.<br>* No dependency on auto-generated code structure. | * Significant upfront dev time.<br>* Must track API spec changes manually.<br>* Risk of subtle bugs in OAuth, upload protocol.<br>* Harder to extend (e.g., captions, thumbnails) later. |

## Maintenance & Reliability

* The **`google/elixir-google-api`** repo shows >10 releases in the last 12 months.
* Code is auto-regenerated from Google Discovery Specs → rapid alignment with new fields or breaking changes.
* Uses battle-tested `Tesla` + `Hackney` or `Mint` adapters for HTTP.

## Security Considerations

* Source is under the verified **google** GitHub org.
* No runtime code-generation; modules are compiled Elixir code.
* We pin a **minor-version range (`~> 0.37`)** to avoid accidental major bumps.

## Decision

Given our needs (full upload support now, potential future features like captions, playlists and analytics):

> **We adopt `google_api_youtube` with a thin wrapper (`Spreader.YouTube.Client` + `Spreader.YouTube.Uploader`).**
>
> Benefits (lower maintenance, spec coverage) outweigh the modest compile-time cost. Custom HTTP calls would duplicate work and increase long-term risk.

---

## Action Items

1. Keep `mix.exs` dependency pinned to `~> 0.37` until breaking changes require bumping.
2. Re-evaluate if Google ceases maintenance or compile time becomes a bottleneck.
3. Document Refresh Token flow & quotas in `docs/youtube_content_upload.md` (already done).
