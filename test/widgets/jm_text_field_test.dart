import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/validators.dart';
import 'package:jeevamitra/presentation/widgets/common/jm_text_field.dart';

void main() {
  group('JmTextField', () {
    testWidgets('renders label and hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JmTextField(label: 'Mobile Number', hint: '9876543210'),
          ),
        ),
      );
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('typed text reaches the controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JmTextField(label: 'Name', controller: controller),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Ravi Kumar');
      expect(controller.text, 'Ravi Kumar');
    });

    testWidgets('shows validator error text on invalid phone', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: JmTextField(
                label: 'Mobile Number',
                validator: (v) => Validators.phone(v),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '123');
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Enter valid 10-digit mobile number'), findsOneWidget);
    });

    testWidgets('passes validation for a well-formed phone number', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: JmTextField(
                label: 'Mobile Number',
                validator: (v) => Validators.phone(v),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '9876543210');
      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
      expect(find.text('Enter valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('shows a mic button when onVoiceTap is provided and fires callback',
        (tester) async {
      var voiceTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JmTextField(
              label: 'Name',
              onVoiceTap: () => voiceTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      expect(voiceTapped, isTrue);
    });

    testWidgets('disabled field does not accept input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JmTextField(label: 'Name', enabled: false),
          ),
        ),
      );
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });
  });
}
