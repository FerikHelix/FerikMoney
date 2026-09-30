import 'package:flutter/material.dart';

/// Bottom-navigation destinations, in display order. Use these instead of raw
/// indexes so reordering tabs cannot break navigation.
enum MainTab {
  home('Beranda', Icons.home_outlined, Icons.home_rounded),
  history('Transaksi', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  reports('Laporan', Icons.donut_large_outlined, Icons.donut_large_rounded),
  more('Lainnya', Icons.grid_view_outlined, Icons.grid_view_rounded);

  const MainTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
