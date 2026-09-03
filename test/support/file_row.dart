import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the details of the row named [name] (UC-13 main flow step 1).
///
/// A row opens its file now — a page is read, a video plays — and the details
/// are the button beside it. Tests about the details reach them the way an
/// owner does rather than by calling `FileDetailsView.show` themselves, which
/// would stop proving that there is any way in at all.
Future<void> openDetailsOf(WidgetTester tester, String name) async {
  final row = find
      .ancestor(of: find.text(name).first, matching: find.byType(ListTile))
      .first;

  await tester.tap(
    find.descendant(of: row, matching: find.byType(FileDetailsButton)).first,
  );
  await tester.pumpAndSettle();
}
