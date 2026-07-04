import 'package:flutter/material.dart';

class AppTheme {
  static const Color defaultSeed = Color(0xFF1A237E);
  static final seedNotifier = ValueNotifier<Color>(defaultSeed);

  static const Color pending = Color(0xFFE65100);
  static const Color approved = Color(0xFF2E7D32);
  static const Color completed = Color(0xFF1565C0);
  static const Color rejected = Color(0xFFC62828);
  static const Color hold = Color(0xFF757575);
  static const Color urgent = Color(0xFFBF360C);
  static const Color medium = Color(0xFFE65100);
  static const Color low = Color(0xFF2E7D32);

  static const _ink = Color(0xFF1A1410);
  static const _warmPaper = Color(0xFFFDFBF7);

  static ThemeData light({Color seed = defaultSeed}) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: seed,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD4D8F0),
      onPrimaryContainer: Color(0xFF0A0F3E),
      secondary: Color(0xFFBF360C),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFBE9E7),
      onSecondaryContainer: Color(0xFF3E0A00),
      tertiary: Color(0xFF65558F),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEDE0FF),
      onTertiaryContainer: Color(0xFF201049),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: _warmPaper,
      onSurface: _ink,
      surfaceContainerLow: Color(0xFFF8F3EE),
      surfaceContainer: Color(0xFFF2EDE8),
      surfaceContainerHigh: Color(0xFFEDE7E2),
      surfaceContainerHighest: Color(0xFFE7E2DC),
      outline: Color(0xFF8C817A),
      outlineVariant: Color(0xFFDAD1C9),
      onSurfaceVariant: Color(0xFF53463E),
      inverseSurface: Color(0xFF2F302F),
      onInverseSurface: Color(0xFFF2F0EE),
      inversePrimary: Color(0xFFB0B5F0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _warmPaper,
        foregroundColor: _ink,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        color: scheme.surface,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
    );
  }

  static ThemeData dark({Color seed = defaultSeed}) => light(seed: seed);

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return pending;
      case 'approved':
        return approved;
      case 'completed':
        return completed;
      case 'rejected':
        return rejected;
      case 'hold':
        return hold;
      default:
        return hold;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'completed':
        return 'تم';
      case 'rejected':
        return 'مرفوض';
      case 'hold':
        return 'معلق';
      default:
        return status;
    }
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return urgent;
      case 'medium':
        return medium;
      case 'low':
        return low;
      default:
        return hold;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'عاجل';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return priority;
    }
  }
}

class DecorativeDivider extends StatelessWidget {
  final Color? color;
  const DecorativeDivider({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: i == 2 ? 8 : 4),
          child: Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }),
    );
  }
}
