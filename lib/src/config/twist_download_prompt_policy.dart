import 'dart:math' as math;

/// Cadence of the "download Twist" prompt.
///
/// Backend-driven through the lane's `downloadPrompt` object; every missing
/// field falls back to the value in [fallback].
class TwistDownloadPromptPolicy {
  const TwistDownloadPromptPolicy({
    this.isEnabled = true,
    this.maxCount = 1,
    this.intervalSeconds = 30,
  });

  /// Client default until the backend supplies a policy: once per session,
  /// around the end of the first 30-second preview.
  static const TwistDownloadPromptPolicy fallback = TwistDownloadPromptPolicy();

  final bool isEnabled;

  /// Maximum prompts per process lifetime.
  final int maxCount;

  /// Seconds into a track after which the prompt becomes due.
  final int intervalSeconds;

  bool get isActive => isEnabled && maxCount > 0;

  /// Parses the wire object; a null or non-map value yields [fallback].
  factory TwistDownloadPromptPolicy.fromJson(
    Object? json, {
    TwistDownloadPromptPolicy fallback = TwistDownloadPromptPolicy.fallback,
  }) {
    if (json is! Map) return fallback;
    final enabled = json['enabled'];
    final maxCount = json['maxCount'];
    final interval = json['intervalSeconds'];
    final parsedInterval = interval is num ? interval.toInt() : null;
    return TwistDownloadPromptPolicy(
      isEnabled: enabled is bool ? enabled : fallback.isEnabled,
      maxCount: maxCount is num ? math.max(0, maxCount.toInt()) : fallback.maxCount,
      intervalSeconds: parsedInterval != null && parsedInterval > 0
          ? parsedInterval
          : fallback.intervalSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TwistDownloadPromptPolicy &&
      other.isEnabled == isEnabled &&
      other.maxCount == maxCount &&
      other.intervalSeconds == intervalSeconds;

  @override
  int get hashCode => Object.hash(isEnabled, maxCount, intervalSeconds);

  @override
  String toString() =>
      'TwistDownloadPromptPolicy(enabled: $isEnabled, max: $maxCount, every: ${intervalSeconds}s)';
}
