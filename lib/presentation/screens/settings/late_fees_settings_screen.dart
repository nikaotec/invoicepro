import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_screen.dart';

// Late fees settings provider
final lateFeesSettingsProvider = StateProvider<LateFeesSettings>((ref) {
  return const LateFeesSettings(
    enabled: false,
    rate: 0.0,
    gracePeriodDays: 0,
  );
});

class LateFeesSettings {
  final bool enabled;
  final double rate; // Percentage
  final int gracePeriodDays;

  const LateFeesSettings({
    this.enabled = false,
    this.rate = 0.0,
    this.gracePeriodDays = 0,
  });

  LateFeesSettings copyWith({
    bool? enabled,
    double? rate,
    int? gracePeriodDays,
  }) {
    return LateFeesSettings(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
    );
  }
}

class LateFeesSettingsScreen extends ConsumerStatefulWidget {
  const LateFeesSettingsScreen({super.key});

  @override
  ConsumerState<LateFeesSettingsScreen> createState() =>
      _LateFeesSettingsScreenState();
}

class _LateFeesSettingsScreenState
    extends ConsumerState<LateFeesSettingsScreen> {
  final _rateController = TextEditingController();
  final _gracePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(lateFeesSettingsProvider);
    _rateController.text = settings.rate.toStringAsFixed(2);
    _gracePeriodController.text = settings.gracePeriodDays.toString();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(lateFeesSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Late Fees',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enable/Disable Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Late Fees',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Charge late fees on overdue invoices',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: settings.enabled,
                      onChanged: (value) {
                        ref.read(lateFeesSettingsProvider.notifier).state =
                            settings.copyWith(enabled: value);
                      },
                      activeColor: const Color(0xFF135BEC),
                    ),
                  ],
                ),
              ),

              if (settings.enabled) ...[
                const SizedBox(height: 24),

                // Late Fee Rate
                Text(
                  'Late Fee Rate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Rate (%)',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) {
                      final rate = double.tryParse(value) ?? 0.0;
                      ref.read(lateFeesSettingsProvider.notifier).state =
                          settings.copyWith(rate: rate);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Grace Period
                Text(
                  'Grace Period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: _gracePeriodController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Days before late fee applies',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      suffixText: 'days',
                      suffixStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) {
                      final days = int.tryParse(value) ?? 0;
                      ref.read(lateFeesSettingsProvider.notifier).state =
                          settings.copyWith(gracePeriodDays: days);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Update late fees enabled provider
                    ref.read(lateFeesEnabledProvider.notifier).state =
                        settings.enabled;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Late fees settings saved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

