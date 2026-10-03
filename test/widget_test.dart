import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/widgets/bar_info.dart';
import 'package:jak_wypije/widgets/bar_status.dart';
import 'package:jak_wypije/widgets/rating_stars.dart';

import 'fixtures.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('StatusChip shows the Polish label', (tester) async {
    await tester.pumpWidget(
      _wrap(const StatusChip(status: BarStatus.inRoute)),
    );
    expect(find.text('W trasie'), findsOneWidget);
  });

  testWidgets('RatingStars renders half stars', (tester) async {
    await tester.pumpWidget(_wrap(const RatingStars(rating: 3.5)));
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('FriendsScoreBadge shows the friends score', (tester) async {
    await tester.pumpWidget(
      _wrap(const FriendsScoreBadge(rating: 4.5, count: 2)),
    );
    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('Znajomi (2)'), findsOneWidget);
  });

  testWidgets('PriceChips show ranges and missing kitchen', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PriceChips(
          bar: testBar(
            'b',
            extra: {
              'shot': {'min': 8, 'max': 12},
            },
          ),
        ),
      ),
    );
    expect(find.text('🍺 10–12 zł'), findsOneWidget);
    expect(find.text('🥃 8–12 zł'), findsOneWidget);
    expect(find.text('🍽️ bez kuchni'), findsOneWidget);
  });
}
