/// Formats seconds as `m:ss`. Non-finite or non-positive values read `0:00`.
String formatTrackTime(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return '0:00';
  final whole = seconds.floor();
  final minutes = whole ~/ 60;
  final rest = whole % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
