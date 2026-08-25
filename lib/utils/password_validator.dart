class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigits;
  final bool hasSpecialChar;
  final bool passwordsMatch;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigits,
    required this.hasSpecialChar,
    required this.passwordsMatch,
  });

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigits &&
      hasSpecialChar &&
      passwordsMatch;

  String? get errorMessage {
    if (!hasMinLength) return "La contrasenya ha de tenir almenys 8 caràcters.";
    if (!hasUppercase) return "La contrasenya ha d'incloure almenys una majúscula (A-Z).";
    if (!hasLowercase) return "La contrasenya ha d'incloure almenys una minúscula (a-z).";
    if (!hasDigits) return "La contrasenya ha d'incloure almenys un número (0-9).";
    if (!hasSpecialChar) return "La contrasenya ha d'incloure almenys un caràcter especial (!@#\$%...).";
    if (!passwordsMatch) return "Les contrasenyes no coincideixen.";
    return null;
  }
}

class PasswordValidator {
  static PasswordValidationResult validate(String password, String confirmPassword) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigits: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar: RegExp(r'[!@#$%^&*(),.?":{}|<>\_\-\+\=\/\\]').hasMatch(password),
      passwordsMatch: password.isNotEmpty && password == confirmPassword,
    );
  }
}
