# Using Oban for YouTube Video Upload & Processing

This document helps you decide **whether or not to off-load YouTube video uploads and processing-status polling to an Oban background job**. It summarises when the extra complexity of a queue is worth it and provides a quick checklist.

---

## 1. When Oban Is **Strongly Recommended**

| Scenario | Why a Background Job Helps |
|----------|---------------------------|
| Large uploads (≈100 MB – GB) that take minutes | Keeps web requests fast and prevents timeouts. |
| Many concurrent uploads | Queue concurrency controls protect the BEAM VM from IO spikes. |
| Need "upload in progress / completed" notifications or retries | Jobs can be retried automatically and status can be stored. |
| SPA / mobile clients that require an immediate response | Web layer can return `videoId` instantly while the worker continues. |
| You already operate Oban Web/Pro for monitoring | Upload jobs naturally fit into existing dashboards. |

## 2. Useful, but Not Mandatory

* Typical file sizes 10-50 MB and complete in < 1 min.
* Low upload frequency (internal tool, limited users).
* Simpler infrastructure is a higher priority than robustness **for now**.

In these cases you may start with synchronous uploads and migrate later if growth demands it.

## 3. Probably **Overkill**

* One-off or rare uploads with minimal business impact.
* Small, internal project running on hobby/heroku-free dynos without worker processes.
* No need for detailed monitoring, retries, or post-upload processing.

## 4. Pros & Cons Summary

| ✔︎ Pros | ✗ Cons |
|--------|--------|
| Non-blocking web requests → better UX | Adds Oban dep, tables, supervision tree |
| Automatic retries & scheduling | Requires extra runtime (worker) pods/containers |
| Observability via Oban Web/Pro | More code paths → higher debugging complexity |
| Concurrency & rate-limit control | |

## 5. Decision Checklist

Tick **Yes** or **No** for each question:

- [ ] Are typical video files **≥ 100 MB**?
- [ ] Does a single upload+processing step take **≥ 30 s**?
- [ ] Could **many users** start uploads at the same time?
- [ ] Do we need guaranteed retries / detailed monitoring?
- [ ] Is Oban already in the stack (or planned)?

**Guidance**

* **≥ 3 Yes** → Implement an Oban worker now.
* **1–2 Yes** → Start synchronous; plan migration if usage grows.
* **0 Yes** → Synchronous upload is sufficient.

---

## 6. Implementation Sketch (if you choose Oban)

1. **Job Args**: `%{"user_id" => id, "filepath" => path, "meta" => %{title: "..."}}`
2. **Perform/1**
   * Build `YouTube.Client` connection.
   * Stream file via `Spreader.YouTube.Uploader`.
   * Poll `videos.list` every 15 s until `processingStatus` == `succeeded` or timeout.
   * Persist final status & video ID.
3. **Retries**
   * Oban default exponential back-off, `max_attempts: 5`.
4. **Monitoring**
   * Use Oban Web to track progress (`executing`, `retryable`, `completed`).

Feel free to adapt the polling interval, chunk size, and retry policy to your traffic patterns.
