import 'package:intl/intl.dart';

final _intFmt = NumberFormat('#,##0',    'en_US');
final _decFmt = NumberFormat('#,##0.00', 'en_US');

/// Formats a price with thousands separator.
/// 15000   → "15,000"
/// 15000.5 → "15,000.50"
String fmtPrice(double v) =>
    v == v.truncateToDouble() ? _intFmt.format(v) : _decFmt.format(v);
