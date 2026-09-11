import 'package:flutter/widgets.dart';

/// Lets sheet bodies close themselves whether they were presented inside a
/// [TwistPlayerHost] layer or through `showModalBottomSheet`.
class TwistSheetScope extends InheritedWidget {
  const TwistSheetScope({super.key, required this.close, required super.child});

  final void Function(Object? result) close;

  static void closeWith(BuildContext context, Object? result) {
    final scope = context.getInheritedWidgetOfExactType<TwistSheetScope>();
    if (scope != null) {
      scope.close(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  @override
  bool updateShouldNotify(TwistSheetScope oldWidget) => false;
}
