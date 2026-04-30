import 'package:flutter/foundation.dart';

/// Singleton ValueNotifier that holds the current cart item count.
/// Listen to this from any widget to show live cart badges.
class CartNotifier extends ValueNotifier<int> {
  static final CartNotifier instance = CartNotifier._();
  CartNotifier._() : super(0);

  void update(int count) {
    if (value != count) value = count;
  }
}
