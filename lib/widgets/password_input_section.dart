import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/password_validator.dart';

class PasswordInputSection extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<PasswordValidationResult>? onChanged;

  const PasswordInputSection({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    this.onChanged,
  });

  @override
  State<PasswordInputSection> createState() => _PasswordInputSectionState();
}

class _PasswordInputSectionState extends State<PasswordInputSection> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordValidationResult? _result;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_validate);
    widget.confirmPasswordController.addListener(_validate);
    _validate();
  }

  void _validate() {
    final result = PasswordValidator.validate(
      widget.passwordController.text,
      widget.confirmPasswordController.text,
    );
    setState(() {
      _result = result;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = _result ?? PasswordValidator.validate('', '');
    final showCriteria = widget.passwordController.text.isNotEmpty || widget.confirmPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Contrasenya",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: widget.confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: "Confirmar contrasenya",
            prefixIcon: const Icon(Icons.lock_reset),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        if (showCriteria) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Requisits de la contrasenya:",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildCriterionItem("Almenys 8 caràcters", res.hasMinLength),
                _buildCriterionItem("Almenys una majúscula (A-Z)", res.hasUppercase),
                _buildCriterionItem("Almenys una minúscula (a-z)", res.hasLowercase),
                _buildCriterionItem("Almenys un número (0-9)", res.hasDigits),
                _buildCriterionItem("Almenys un caràcter especial (!@#\$%...)", res.hasSpecialChar),
                _buildCriterionItem("Les contrasenyes coincideixen", res.passwordsMatch),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCriterionItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: isMet ? Colors.green.shade800 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
