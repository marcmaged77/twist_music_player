# twist_music_player example

A small host app showing the two ways to show the player:

- **Docked bar** (default): `MaterialApp.builder` wraps the app in `TwistPlayerHost`, which docks the mini bar and expands the full player in place.
- **Manual bar**: tap "Manual bar" in the app bar. The host is removed and `TwistMiniPlayer` sits in `Scaffold.bottomNavigationBar`; a tap on it pushes the full player route.

The lane loads from the endpoint you pass at build time:

```bash
flutter run --dart-define=TWIST_TRACKS_URL=https://<your-lane-endpoint>/tracks --dart-define=TWIST_STORE_URL=https://<your-store-page>
```
