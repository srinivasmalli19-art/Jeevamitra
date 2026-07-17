import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/widgets/common/jm_button.dart';

void main() {
  group('JmButton', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JmButton(label: 'Send OTP', onPressed: () {}),
        ),
      );
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: JmButton(label: 'Tap me', onPressed: () => tapped = true),
        ),
      );
      await tester.tap(find.byType(JmButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('does not call onPressed when null (disabled)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JmButton(label: 'Disabled', onPressed: null),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a spinner and suppresses taps while isLoading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: JmButton(
            label: 'Loading',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);

      await tester.tap(find.byType(JmButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('outline variant renders an OutlinedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JmButton(
            label: 'Outline',
            variant: JmButtonVariant.outline,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders leading and trailing icons when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JmButton(
            label: 'Icons',
            leadingIcon: Icons.send_rounded,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });
}
