# Streaming acceptance plan

Written before the streaming implementation. Verify the native UI and real SDK
against a disposable 256-slot single-node cluster; retain JSON receipts and PNGs.

Failures to cover:

- SEND silently drops setting.stream, loses stable clientMsgNo, or accepts an
  unsuccessful SENDACK; legacy dictionary options must remain compatible.
- EVENT is ignored, decoded as a normal message, acknowledged, or loses nested
  data/nulls. Object and JSON-string data must decode; diagnostics stay redacted.
- Parent arrives after events, duplicate/overlapping UTF-8 deltas repeat text,
  gaps corrupt text, finish is filtered by the main lane, or late events reopen
  cancellation/failure. History and live buffering must share one bounded view.
- Partial cancel/error loses text or model cancellation leaves the upstream
  running. SSE delimiters, multi-line events and UTF-8 can cross network writes;
  unexpected EOF, HTTP/SSE errors and size/time bounds must terminate safely.
- Reconnect misses offline output or polls history while online. Read one full
  history page per successful connection; ignore stale recovery generations.
- Old sessions/listeners mutate replacements; leaving/resetting the screen leaks
  tasks, sockets or model keys. No credentials/payloads in logs or saved state.
- Example works only against local sources. After release, resolve the exact
  CocoaPods and SwiftPM versions and rerun native acceptance against the package.

SDK isolation checks precede implementation. Native acceptance covers progressive
text, cancel/error snapshots, offline generation/recovery, overlapping buffered
live events, compatible model SSE, context, upstream cancellation and key secrecy.

## Source validation

On iOS 18.3.1 Simulator with Xcode 16.2, the native acceptance passed 11 checks.
The model fixture recorded one upstream cancellation, three history reads
(initial plus two reconnects), and zero eventsync reads. SDK isolation checks
passed 36 tests; the native projection passed four tests. The literal release
package is verified independently after publication. The local all-platform
CocoaPods lint encountered a missing tvOS simulator; iOS/macOS lint passed.
