import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/wallet_controller.dart';
import '../theme/app_theme.dart';
import '../utils/password_validator.dart';
import '../widgets/password_input_section.dart';
import '../widgets/address_autocomplete_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  PasswordValidationResult? _passwordValidation;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Crea la teva identitat",
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Obtén la teva credencial digital verificada.",
              style: GoogleFonts.manrope(color: AppColors.neutral),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nom",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: "Cognoms",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            // Component modular de Contrasenya, Confirmació i Requisits
            PasswordInputSection(
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              onChanged: (result) {
                _passwordValidation = result;
              },
            ),
            const SizedBox(height: 20),
            // Component modular d'Adreça Autocompletada amb OpenStreetMap (Nominatim)
            AddressAutocompleteField(
              addressController: _addressController,
              cityController: _cityController,
              postalCodeController: _postalCodeController,
            ),
            const SizedBox(height: 40),
            MaterialButton(
              onPressed: wallet.isLoading
                  ? null
                  : () async {
                      if (_nameController.text.trim().isEmpty ||
                          _emailController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty ||
                          _confirmPasswordController.text.trim().isEmpty ||
                          _addressController.text.trim().isEmpty ||
                          _cityController.text.trim().isEmpty ||
                          _postalCodeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Si us plau, omple tots els camps"),
                          ),
                        );
                        return;
                      }

                      final passVal = _passwordValidation ??
                          PasswordValidator.validate(
                            _passwordController.text,
                            _confirmPasswordController.text,
                          );

                      if (!passVal.isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              passVal.errorMessage ??
                                  "La contrasenya no compleix els requisits",
                            ),
                          ),
                        );
                        return;
                      }

                      final success = await wallet.register(
                        _nameController.text.trim(),
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        address: _addressController.text.trim(),
                        city: _cityController.text.trim(),
                        postalCode: _postalCodeController.text.trim(),
                      );
                      if (success && context.mounted) {
                        Navigator.pop(context); // Volver al login
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Registre completat! Ja pots iniciar sessió.",
                            ),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error al realitzar el registre"),
                          ),
                        );
                      }
                    },
              height: 60,
              minWidth: double.infinity,
              color: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: wallet.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Registrar-se i obtenir la credencial",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
