import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Pulling the notification shade down, or switching apps, makes Android
/// close the keyboard, and the field being typed in loses its focus. This
/// gives it back (keyboard included) when the app comes back.
class KeepTyping {
  KeepTyping() {
    _lifecycle = AppLifecycleListener(onInactive: _remember, onResume: _restore);
  }

  late final AppLifecycleListener _lifecycle;
  FocusNode? _field;

  /// A text field or a note's editor, not a button.
  static bool _isField(FocusNode? node) {
    final context = node?.context;
    if (context == null) return false;
    return context.findAncestorWidgetOfExactType<EditableText>() != null ||
        context.findAncestorWidgetOfExactType<QuillRawEditor>() != null;
  }

  void _remember() {
    final focus = FocusManager.instance.primaryFocus;
    _field = _isField(focus) ? focus : null;
  }

  void _restore() {
    final field = _field;
    _field = null;
    if (field == null || field.context == null || !field.canRequestFocus) return;
    if (field.hasPrimaryFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      field.requestFocus();
    }
  }

  void dispose() => _lifecycle.dispose();
}
