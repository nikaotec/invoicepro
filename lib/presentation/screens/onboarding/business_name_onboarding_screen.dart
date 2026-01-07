import 'package:flutter/material.dart';

class BusinessNameOnboardingScreen extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const BusinessNameOnboardingScreen({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<BusinessNameOnboardingScreen> createState() =>
      _BusinessNameOnboardingScreenState();
}

class _BusinessNameOnboardingScreenState
    extends State<BusinessNameOnboardingScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Headline
          Text(
            'First, tell us about your business',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Body Text
          Text(
            'This name will appear on the invoices you send to your clients. You can always change this later in your settings.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Text Field
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _hasFocus = hasFocus;
              });
            },
            child: Stack(
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onNext();
                    }
                  },
                  maxLength: 50,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., Acme Design Studio',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF135BEC),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF135BEC),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF135BEC),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    widget.onChanged(value);
                  },
                ),
                Positioned(
                  left: 16,
                  top: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
                    child: Text(
                      'Business Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF135BEC),
                      ),
                    ),
                  ),
                ),
                if (_hasFocus)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        Icons.edit_outlined,
                        color: const Color(0xFF135BEC),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Character count
          Text(
            'Maximum 50 characters',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),

          const SizedBox(height: 48),

          // Visual element
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[800]!,
                          Colors.grey[800]!.withOpacity(0.5),
                        ]
                      : [
                          const Color(0xFFDBEAFE),
                          const Color(0xFFE0E7FF),
                        ],
                ),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 64,
                color: const Color(0xFF135BEC).withOpacity(0.4),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _controller.text.trim().isNotEmpty
                  ? () {
                      widget.onChanged(_controller.text.trim());
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor:
                    const Color(0xFF135BEC).withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

