# Startup Order and Fallbacks

**Version:** 1.0  
**Date:** 2026-04-12

## 1. Startup order
Recommended startup sequence:

1. Start the local model server with a pinned known-good model.
2. Confirm the local HTTP endpoint is reachable.
3. Launch the direct terminal router (`oroute`).
4. Verify command logging to the communication bus.
5. Re-attach secondary ingress layers such as clipboard and notification routing.

## 2. Why this order matters
This order prevents phantom states caused by multiple watchers competing before the primary control plane is stable.

## 3. Local-first rule
The system should attempt local inference first whenever the local backend is healthy.

## 4. Gemini fallback rule
Gemini remains integrated and available, but fallback should occur only when:
- the local backend returns a hard failure,
- the local backend returns empty output, or
- the local backend is unavailable.

## 5. Logging rule
Every command and result should be logged with:
- timestamp
- route
- source (`local` or `gemini`)
- result preview

## 6. Secondary layers
Clipboard and notification routing are valid secondary ingress surfaces, but they should be treated as extensions of the control plane, not replacements for it.

## 7. Anti-drift rule
Do not treat concurrent watchers as proof of system health. Prefer one stable command surface and one verified backend before expanding the observer layer.

## 8. Recovery rule
If the system becomes noisy or ambiguous:
- stop secondary watchers,
- verify the local server,
- verify the direct terminal route,
- confirm logging,
- then re-enable the secondary layers one by one.
