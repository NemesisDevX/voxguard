/// VoxGuard spacing scale — screen padding, card gaps, and section
/// rhythm. Generous vertical space is part of the calm-first feel:
/// screens breathe before they alarm.
abstract final class AppSpacing {
  AppSpacing._();

  /// Edge-to-edge horizontal padding on primary screens.
  static const double screenEdge = 20;

  /// Tight inline gap (icon → label, chip padding).
  static const double xs = 6;

  /// Default inner gap inside rows and compact cards.
  static const double sm = 10;

  /// Card-internal padding and inter-row spacing.
  static const double md = 16;

  /// Between sibling cards on a screen.
  static const double card = 14;

  /// Between major sections — a pause between ideas.
  static const double section = 28;

  /// Above the primary statement/hero region.
  static const double heroTop = 12;
}
