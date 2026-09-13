## 0.3.1

- Loading skeleton rebuilt as solid containers in the loaded content's shape (band or header, white cards with the real radius and shadow) with grey lines inside where the content will be; only the lines shimmer. Fixed colours regardless of the host theme.
- Card shadows are no longer clipped below the carousel in the banner style or the skeleton.

## 0.3.0

- `TwistMusicSwimlane(style: TwistSwimlaneStyle.banner)`: a brand gradient band (105°, blue to violet to red) with a red glow travelling on its right, rounded top corners and an oval bottom edge; the white wordmark and lane title on the left, the lane subtitle as the offer text on the right, a white "Download Twist" pill, and the cards overlapping the band by 40 %. `TwistMusicTheme.bannerGradient` overrides the band statically.
- Cards carry a soft shadow; the brand accent is now `#0021A5`.
- The plain header stays the default.
- Fixed: the carousel's neighbours were unscaled for the first frame, so cards touched until the first layout.
- The loading skeleton uses fixed neutral colours regardless of the host theme.

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
