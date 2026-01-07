import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/client.dart' as domain;
import '../../providers/client_repository_provider.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController(); // Internal notes

  String _selectedUF = 'SP';
  final List<String> _ufs = [
    'SP',
    'RJ',
    'MG',
    'RS',
    'PR',
    'SC',
    'BA',
  ]; // Add more as needed

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (_formKey.currentState?.validate() ?? false) {
      final repository = ref.read(clientRepositoryProvider);

      final now = DateTime.now();
      
      // Build address
      final addressParts = <String>[];
      if (_streetController.text.isNotEmpty) {
        addressParts.add(_streetController.text);
      }
      if (_cityController.text.isNotEmpty) {
        addressParts.add(_cityController.text);
      }
      if (_selectedUF.isNotEmpty) {
        addressParts.add(_selectedUF);
      }
      final address = addressParts.isNotEmpty ? addressParts.join(', ') : null;

      // Create domain client
      final domainClient = domain.Client(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: address,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        state: _selectedUF.isNotEmpty ? _selectedUF : null,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createClient(domainClient);

      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error!.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client added successfully'),
            backgroundColor: Colors.green,
        ),
      );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors based on HTML design mapping
    final bgLight = const Color(0xFFF6F6F8);
    final bgDark = const Color(0xFF121121);
    final surfaceLight = Colors.white;
    final surfaceDark = const Color(0xFF1E1E2D);
    final textMain = isDark ? Colors.white : const Color(0xFF121117);
    final textSub = isDark ? Colors.grey[400]! : const Color(0xFF656487);
    final borderLight = Colors.grey[200]!;
    final borderDark = Colors.grey[800]!;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? bgDark : bgLight).withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? borderDark : borderLight.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSub,
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Adicionar Cliente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Placeholder Right (Hidden Save)
                  const Opacity(
                    opacity: 0,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Salvar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  32,
                  20,
                  120,
                ), // Extra bottom padding for floating footer
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Photo Picker
                      Column(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: isDark ? surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle
                                    .none, // Dashed simulated usually, but explicit dashed needs custom painter. Using standard for now or solid.
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            // Dashed effect is hard with standard Container, using solid for MVP or CustomPaint if strictly needed.
                            // Let's stick to standard cleanly for now.
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 36,
                                  color: Colors.grey[400],
                                ),
                                // Edit Badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? bgDark : bgLight,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Toque para adicionar foto',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Contact Info Section
                      _buildSectionHeader('Dados de Contato', textSub),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? surfaceDark : surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? borderDark : Colors.grey[100]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Nome Completo',
                              controller: _nameController,
                              placeholder: 'Ex: Maria Silva',
                              icon: Icons.check_circle,
                              iconColor: AppColors.success,
                              textMain: textMain,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              placeholder: 'cliente@email.com',
                              keyboardType: TextInputType.emailAddress,
                              // errorText: 'Por favor, insira um endereço de email válido.', // Toggle based on validation
                              textMain: textMain,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Telefone',
                              controller: _phoneController,
                              placeholder: '(00) 00000-0000',
                              keyboardType: TextInputType.phone,
                              icon: Icons.call,
                              iconColor: Colors.grey[400]!,
                              textMain: textMain,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address Section
                      _buildSectionHeader('Endereço', textSub),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? surfaceDark : surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? borderDark : Colors.grey[100]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    label: 'CEP',
                                    controller: _cepController,
                                    placeholder: '00000-000',
                                    // errorText: 'Incompleto',
                                    textMain: textMain,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 26,
                                    ), // Align with input
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.search,
                                          size: 20,
                                        ),
                                        label: const Text('Buscar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Rua',
                              controller: _streetController,
                              placeholder: 'Rua das Flores, 123',
                              textMain: textMain,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    label: 'Cidade',
                                    controller: _cityController,
                                    placeholder: 'São Paulo',
                                    textMain: textMain,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UF',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? bgDark.withOpacity(0.5)
                                              : bgLight,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.primary.withOpacity(
                                                    0.5,
                                                  )
                                                : AppColors.primary.withOpacity(
                                                    0.5,
                                                  ),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedUF,
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.expand_more,
                                              color: AppColors.success,
                                            ),
                                            style: TextStyle(
                                              color: textMain,
                                              fontSize: 16,
                                            ),
                                            dropdownColor: isDark
                                                ? surfaceDark
                                                : surfaceLight,
                                            items: _ufs.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                _selectedUF = newValue!;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(
                            'Informações Adicionais',
                            textSub,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? surfaceDark : surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? borderDark : Colors.grey[100]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notas Internas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[300] : textMain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 4,
                              style: TextStyle(color: textMain, fontSize: 16),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? bgDark.withOpacity(0.5)
                                    : bgLight,
                                hintText:
                                    'Adicione observações sobre este cliente...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: 24),
        decoration: BoxDecoration(
          color: isDark ? surfaceDark : surfaceLight,
          border: Border(
            top: BorderSide(color: isDark ? borderDark : borderLight),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveClient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check, size: 24),
                SizedBox(width: 8),
                Text(
                  'Salvar Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required Color textMain,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    Color? iconColor,
    String? errorText,
  }) {
    final bgLight = const Color(0xFFF6F6F8);
    final bgDark = const Color(0xFF121121);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : textMain,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(color: textMain, fontSize: 16),
              validator: (value) {
                if (label == 'Nome Completo' &&
                    (value == null || value.isEmpty)) {
                  return 'Campo obrigatório';
                }
                return null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? bgDark.withOpacity(0.5) : bgLight,
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.only(
                  left: 16,
                  right: 48,
                  top: 16,
                  bottom: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? AppColors.error.withOpacity(0.5)
                        : (isDark
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.primary.withOpacity(0.5)),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? AppColors.error.withOpacity(0.5)
                        : (isDark
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.primary.withOpacity(0.5)),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? AppColors.error
                        : AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            if (icon != null)
              Positioned(
                right: 12,
                child: Icon(icon, color: iconColor, size: 20),
              ),
            if (errorText != null) // Error Icon
              const Positioned(
                right: 12,
                child: Icon(Icons.error, color: AppColors.error, size: 20),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.close, color: AppColors.error, size: 10),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
