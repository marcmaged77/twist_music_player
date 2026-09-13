## 0.1.1

- pub.dev screenshots of the swimlane, full player, mini player and download prompt.
- Example shows the manual `TwistMiniPlayer` placement next to the docked host ("Manual bar").

## 0.1.0

- Initial release: swimlane, mini player, full player with Up Next queue, download prompt, lock-screen and notification controls via `audio_service`, `just_audio` playback, `audio_session` focus handling.
- Lane loading through `TwistLaneSource` (`HttpTwistLaneSource` default).
- Analytics and error reporting through plain callbacks.
- English and Arabic strings with an English fallback when the delegate is not registered.
