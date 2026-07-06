# Requirements Specification — AI-OCR (On-Device, Mobile)

**Feature:** Receipt OCR → Structured Expense Draft  
**Constraint:** Must run **entirely on the phone** — no server round-trip, no self-hosted model server, no cloud AI API  
**Status:** Supersedes both `ocr_task_breakdown.md` (OpenAI Vision) and the previous revision of this document (self-hosted Ollama server)  
**Date:** 2026-07-06

---

## 1. Why This Changes Again

The first revision of this document moved inference from OpenAI's cloud API to a **self-hosted Ollama server** (Qwen2.5-VL-7B) running in Docker. That is still "local" in the sense of "we own the box," but it is **not local to the user's device** — it requires a backend server, a multi-GB model download, and a GPU/CPU budget no phone has.

The actual constraint is **on-device inference**: the feature must work with the phone's own CPU/NPU, offline, with no dependency on any server (ours or a third party's).

**Everything built for the Ollama revision is now dead code for this feature** — the Python `app/routers/ocr.py`, `app/services/ocr_service.py`, and the `ollama` Docker Compose service are no longer part of the OCR pipeline. They are harmless to leave in place (unused endpoint) but should be removed once this on-device implementation ships, to avoid maintaining two parsers. Not addressed in this revision — flagged for cleanup.

**Also no longer needed:** the `.NET` `POST /expenses/scan-bill` upload endpoint and `IAiOcrService`/`HttpAiOcrService` plumbing (`ocr_task_breakdown.md` EPIC 2). Once OCR runs on-device, the phone already has the fully structured, user-confirmed expense data locally — it calls the existing `POST /expenses` endpoint directly, the same way manual expense entry does today (see [trip_workspace_screen.dart](src/Clients/mobile/lib/features/home/presentation/screens/trip_workspace_screen.dart) `_submitExpense`). No image ever needs to leave the device.

---

## 2. Architecture Decision

Two on-device approaches were considered:

| Approach | Verdict |
|---|---|
| On-device VLM (quantized Qwen2-VL-2B / Gemma 3 nano via MLC-LLM or MediaPipe LLM Inference) | Rejected for v1: adds 1.5–2.5 GB to app size, 5–20s inference per receipt, meaningful battery/thermal cost, and the mobile LLM runtimes (MLC-LLM, MediaPipe GenAI) are less mature than desktop equivalents |
| **Native on-device OCR + rule-based parser** | **Chosen.** Uses the OS's built-in text recognizer (already shipped with the platform, zero extra download), then a hand-written Vietnamese-receipt parser turns raw text lines into structured items. Sub-second, no battery/thermal cost, no app size increase from a model |

A hybrid (native OCR first, fall back to on-device VLM when parsing confidence is low) is the natural v2 if the rule-based parser's accuracy proves insufficient — tracked in §8.

---

## 3. Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-1 | User captures or picks a receipt photo entirely within the Flutter app; the image never leaves the device for this feature |
| FR-2 | Recognize all text on the receipt using the platform's on-device text recognizer |
| FR-3 | Parse recognized text into: `description`, `items[]` (`name`, `unitPrice`, `quantity`), `totalAmount`, `currency` |
| FR-4 | Detect currency; default to `VND` |
| FR-5 | Correctly recognize Vietnamese diacritics (ă, â, ê, ô, ơ, ư, đ...) — delegated to the platform recognizer's Latin-script model, which supports Vietnamese |
| FR-6 | Parse Vietnamese numeric conventions: dot-thousands (`1.250.000`), `K` shorthand (`45K` = 45,000), `x` multiplier (`2 x 45.000` or `45.000 x2`) |
| FR-7 | Identify and exclude non-item lines from the item list: VAT/tax lines ("VAT", "thuế"), service charge ("phí phục vụ"), and the total/subtotal line itself ("tổng cộng", "thành tiền", "total") |
| FR-8 | If a total line is found, use it as `totalAmount`; otherwise sum the parsed item lines |
| FR-9 | Surface a **confidence signal**: if the parsed item sum doesn't reconcile with the detected total (± tolerance), flag it so the review screen can visually warn the user — this is the primary accuracy safety net for a rule-based (non-AI-reasoning) parser |
| FR-10 | User reviews and edits the parsed draft (same "human in the loop" screen already scoped in `ocr_task_breakdown.md` OCR-14) before it becomes a real expense |
| FR-11 | Confirm & Save calls the existing expense creation path (`TripExpenses.createExpense` → `POST /expenses`) — no new backend endpoint |

---

## 4. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | Zero network calls for OCR/parsing — verifiable by running the flow in airplane mode |
| NFR-2 | No model weights bundled or downloaded; relies solely on the OS-provided recognizer already present on the device |
| NFR-3 | End-to-end (capture → parsed draft) budget: **≤ 2s** on a mid-range device — this is the entire point of going on-device instead of a network round-trip |
| NFR-4 | No new permissions beyond camera/photo library (already required for `image_picker`) |
| NFR-5 | Feature must work identically online and offline |
| NFR-6 | Since there's no backend call, **Pro-tier gating for this feature must be enforced client-side** (check `AppAuthProvider`/user tier before allowing entry into the scan flow) — there is no server request to gate anymore. This is a deliberate trust boundary shift from the previous server-gated design and should be revisited if tier enforcement needs to be tamper-resistant (a modified client could bypass a client-only gate; low risk for this cosmetic-tier feature, but note it) |

---

## 5. Platform Recognizer Choice

**Apple's Vision framework (`VNRecognizeTextRequest`), called directly via a Flutter platform channel** — no third-party plugin.

App targets iOS only (no `android/` directory in this repo), so there is no cross-platform recognizer plugin to abstract over. Implementation:

- `ios/Runner/AppDelegate.swift` registers a `FlutterMethodChannel` (`miane.app/text_recognizer`) and runs `VNRecognizeTextRequest` (`recognitionLevel = .accurate`, `recognitionLanguages = ["vi-VN", "en-US"]`) directly against the captured image.
- `lib/features/expense/data/services/receipt_text_recognizer.dart` invokes the channel and returns recognized lines.
- Ships with the OS itself — zero bundled model, zero download, zero extra app size.
- Typical recognition latency: 100–500ms on a photo-sized image.

**Why not `google_mlkit_text_recognition`:** it was the first choice (single plugin API wrapping both ML Kit on Android and Vision on iOS), but Google's prebuilt iOS binaries ship without an arm64 Simulator slice. Combined with Apple dropping x86_64 Simulator runtimes on recent Xcode/iOS versions, there is no architecture left that can run it on an Apple Silicon Simulator at all — only real devices worked. Calling Vision directly avoids that dependency entirely and fixes Simulator testing.

---

## 6. Parsing Algorithm (Rule-Based)

Input: `RecognizedText` (list of text blocks/lines with reading order from top to bottom).

1. **Normalize** each line: trim whitespace, collapse repeated spaces.
2. **Classify** each line:
   - **Total line**: contains a total/grand-total keyword (`tổng`, `tổng cộng`, `thành tiền`, `total`, `grand total`) → capture its trailing amount as `totalAmount` candidate.
   - **Excluded line**: contains a tax/service keyword (`vat`, `thuế`, `phí phục vụ`, `service charge`) → dropped, never becomes an item.
   - **Item line**: contains a trailing price token → candidate item.
   - **Noise line**: no recognizable price token → ignored (store name, address, thank-you footer, etc.).
3. **Extract price token** from a line using a Vietnamese-number-aware regex that recognizes: dot-thousands (`1.250.000`), `K` suffix (`45K`), plain digits (`45000`), optionally followed by `đ`/`vnd`/`VND`.
4. **Extract quantity** from a line using `NxM` / `N x M` / trailing `xN` patterns; default `quantity = 1` if absent.
5. **Item name** = the line text with the price/quantity tokens stripped.
6. **Currency** defaults to `VND`; if the receipt shows a recognizable foreign currency symbol/code (`$`, `USD`, `THB`, `¥`), use that instead.
7. **Description** = first non-empty line (typically the store/restaurant name) plus destination context already known from the trip, if available.
8. **Reconciliation check**: compare `sum(item.unitPrice * item.quantity)` against the detected total line. If they diverge beyond a small tolerance (e.g., > 5%, accounting for rounding/VAT folded into total), set a `hasDiscrepancy` flag — the review screen (FR-9/FR-10) shows an amber warning, same UX already scoped for the discrepancy case in `ocr_task_breakdown.md` OCR-14.

This is a heuristic, not an LLM — it will not "understand" unusual receipt layouts the way a VLM would. That accuracy ceiling is the tradeoff accepted in §2, and §8 tracks how to validate/raise it.

---

## 7. Data Flow

```
Flutter (camera/gallery via image_picker)
      │
      ▼
On-device text recognizer (Vision / VNRecognizeTextRequest, via platform channel)
      │  RecognizedText (lines, no network call)
      ▼
VnReceiptParser (pure Dart, rule-based)
      │  ScanBillResult { description, items[], totalAmount, currency, hasDiscrepancy }
      ▼
Review & Edit screen (human-in-the-loop correction)
      │  user-confirmed data
      ▼
Existing TripExpenses.createExpense() → POST /expenses (unchanged backend)
```

No new backend service, no new network endpoint, no image upload.

---

## 8. Test Requirements

Reuse the 8 Vietnamese receipt scenarios from `ocr_task_breakdown.md` OCR-5, but as **Dart unit tests against the parser** (no AI service, fully deterministic, no network/mock server needed):

- [ ] `VnReceiptParser` unit tests with hand-transcribed `RecognizedText`-equivalent input for: printed thermal receipt, handwritten bill, long itemized seafood receipt, VAT/service-charge receipt, bilingual receipt, low-quality/partial OCR output (simulate a recognizer misread).
- [ ] Assert: total amount accuracy, item extraction recall, currency detection, Vietnamese diacritics preserved (not garbled — this is a recognizer concern more than a parser concern, but the parser must not mangle already-correct diacritics).
- [ ] Assert `hasDiscrepancy` triggers correctly on the VAT-inclusive-total scenario.
- [ ] **Baseline accuracy log**: record actual pass rate per scenario. If recall is materially below the AI-based baseline that would be expected from a real VLM, this is the trigger to revisit the hybrid approach from §2 — not a reason to block shipping v1.

---

## 9. Out of Scope / Deferred

- On-device VLM fallback for low-confidence parses (§2 hybrid option) — deferred until §8 data shows the rule-based parser isn't good enough in practice.
- Removal of the now-unused Ollama/Python OCR service and `.NET` scan-bill endpoint — flagged in §1, not performed as part of this revision.
- Any server-side Pro-tier enforcement for this feature (NFR-6) — client-side only for now.
- Non-Vietnamese receipt formats beyond basic foreign-currency detection.
