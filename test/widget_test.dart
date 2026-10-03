import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/widgets/bar_status.dart';
import 'package:jak_wypije/widgets/rating_stars.dart';

void main() {
  testWidgets('StatusChip shows the Polish label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: BarStatus.saved)),
      ),
    );
    expect(find.text('Uratowany'), findsOneWidget);
  });

  testWidgets('RatingStars renders half stars', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RatingStars(rating: 3.5)),
      ),
    );
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });
}
