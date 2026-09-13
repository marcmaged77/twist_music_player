## 0.2.0

- Swimlane header: the subtitle is now a tappable promo chip that opens the download link and logs `twist_music_download_clicked` with source `swimlane_header`; the logo sits on the title's line.

## 0.1.3

- README describes the package on its own terms.

## 0.1.2

- Source now public at github.com/marcmaged77/twist_music_player; `repository` and `issue_tracker` set.

## 0.1.1

- pub.dev screenshots of the swimlane, full player, mini player and download prompt.
- Example shows the manual `TwistMiniPlayer` placement next to the docked host ("Manual bar").

## 0.1.0

- Initial release: swimlane, mini player, full player with Up Next queue, download prompt, lock-screen and notification controls via `audio_service`, `just_audio` playback, `audio_session` focus handling.
- Lane loading through `TwistLaneSource` (`HttpTwistLaneSource` default).
- Analytics and error reporting through plain callbacks.
- English and Arabic strings with an English fallback when the delegate is not registered.
