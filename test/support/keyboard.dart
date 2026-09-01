import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pressing Return in a field, the way the desktop does it.
///
/// A single-line field never sees Return as a key event: the text input
/// connection consumes it and sends back the action the field asked for,
/// which is why a field configured `TextInputAction.next` moved the focus
/// instead of submitting. So this reads the field's **own** action off the
/// widget and performs that — a field that would move the focus and a field
/// that would submit each get exactly what the platform would send them.
///
/// That is what makes a test written on it a test of the behaviour rather
/// than of the fix: naming `TextInputAction.done` here would pass against a
/// form still configured to do something else with the key.
extension ReturnKey on WidgetTester {
  /// Focuses [field] and presses Return in it.
  ///
  /// `showKeyboard` rather than a tap: focus is all this needs, and a tap
  /// has to land — a field low in a dialog that has scrolled is a tap on the
  /// barrier, which dismisses the dialog and answers nothing. That failure
  /// looks exactly like the form ignoring the key, which is the thing under
  /// test here.
  Future<void> pressReturnIn(Finder field) async {
    await showKeyboard(field);
    await pump();
    await testTextInput.receiveAction(_actionOf(widget<TextField>(field)));
    await pumpAndSettle();
  }

  /// The action a field performs on Return — `EditableText`'s own rule for a
  /// field that names none, rather than an assumption about the default.
  TextInputAction _actionOf(TextField field) =>
      field.textInputAction ??
      (field.keyboardType == TextInputType.multiline
          ? TextInputAction.newline
          : TextInputAction.done);
}
