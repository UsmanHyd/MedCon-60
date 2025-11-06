import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:medcon30/theme/theme_provider.dart';

class StressModulesScreen extends ConsumerStatefulWidget {
  const StressModulesScreen({super.key});

  @override
  ConsumerState<StressModulesScreen> createState() => _StressModulesScreenState();
}

class _StressModulesScreenState extends ConsumerState<StressModulesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = provider_pkg.Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFE0F7FA);

    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          '',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
