import 'package:flutter/widgets.dart';

/// A mounted surface that can expand the player in place and present sheets
/// above it. [TwistPlayerHost] implements it; the facade routes
/// `openFullPlayer` and prompts to it when one is attached, and falls back to
/// Navigator routes otherwise.
abstract class TwistPlayerSurface {
  bool get isExpanded;

  Future<void> expand();

  Future<void> collapse();

  /// Presents [builder] as a bottom sheet in the surface's own layer and
  /// resolves with the value passed to `TwistSheetScope.closeWith`.
  Future<T?> showSheet<T>(WidgetBuilder builder);
}
