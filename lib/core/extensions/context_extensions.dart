import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  bool get isSmallScreen => screenWidth < 360;
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
      ),
    );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();

  Future<T?> showAppBottomSheet<T>(Widget child, {bool isDismissible = true}) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      isScrollControlled: true,
      builder: (_) => child,
    );
  }

  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Theme.of(this).colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
