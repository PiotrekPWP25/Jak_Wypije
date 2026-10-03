/// Price range in PLN, shown like Google Maps: `12–16 zł`.
class PriceRange {
  const PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }

  final double min;
  final double max;

  double get mid => (min + max) / 2;

  /// `12–16 zł` (or `12 zł` when both ends are equal).
  String get label =>
      min == max ? '${_format(min)} zł' : '${_format(min)}–${_format(max)} zł';

  /// Whether this range has any price inside `[low, high]`.
  bool overlaps(double low, double high) => max >= low && min <= high;

  PriceRange operator *(num factor) =>
      PriceRange(min: min * factor, max: max * factor);

  PriceRange operator +(PriceRange other) =>
      PriceRange(min: min + other.min, max: max + other.max);

  static const PriceRange zero = PriceRange(min: 0, max: 0);

  static String _format(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2).replaceAll('.', ',');

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}
