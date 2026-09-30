import 'package:flutter/material.dart';

IconData iconForName(String name) => switch (name) {
  'account_balance' => Icons.account_balance_rounded,
  'account_balance_wallet' => Icons.account_balance_wallet_rounded,
  'restaurant' => Icons.restaurant_rounded,
  'directions_car' => Icons.directions_car_rounded,
  'shopping_bag' => Icons.shopping_bag_rounded,
  'receipt_long' => Icons.receipt_long_rounded,
  'movie' => Icons.movie_rounded,
  'health_and_safety' => Icons.health_and_safety_rounded,
  'sports_esports' => Icons.sports_esports_rounded,
  'payments' => Icons.payments_rounded,
  'stars' => Icons.stars_rounded,
  'work' => Icons.work_rounded,
  'card_giftcard' => Icons.card_giftcard_rounded,
  'label' => Icons.label_rounded,
  'smartphone' => Icons.smartphone_rounded,
  'savings' => Icons.savings_rounded,
  'school' => Icons.school_rounded,
  'family_restroom' => Icons.family_restroom_rounded,
  'person' => Icons.person_rounded,
  'trending_up' => Icons.trending_up_rounded,
  'tune' => Icons.tune_rounded,
  _ => Icons.more_horiz_rounded,
};

/// Account icons are keyed by account type so every type looks different.
IconData accountTypeIcon(String type) => switch (type) {
  'bank' => Icons.account_balance_rounded,
  'ewallet' => Icons.smartphone_rounded,
  'savings' => Icons.savings_rounded,
  'other' => Icons.wallet_rounded,
  _ => Icons.payments_rounded,
};

String accountTypeLabel(String type) => switch (type) {
  'bank' => 'Bank',
  'ewallet' => 'E-wallet',
  'savings' => 'Tabungan',
  'other' => 'Lainnya',
  _ => 'Tunai',
};
