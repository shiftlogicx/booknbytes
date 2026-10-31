class FormValidators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegExp = RegExp(r'[a-z]');
  static final RegExp _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\\/\[\]~`]');

  /// Validates email address: must contain '@' and follow valid email pattern
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final email = value.trim();
    if (!email.contains('@')) {
      return 'Email must contain "@" (e.g. name@restaurant.com).';
    }
    if (!_emailRegExp.hasMatch(email)) {
      return 'Please enter a valid business email address.';
    }
    return null;
  }

  /// Validates password: >= 6 chars, uppercase, lowercase, and special characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (!_uppercaseRegExp.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!_lowercaseRegExp.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!_specialCharRegExp.hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%...).';
    }
    return null;
  }

  static bool hasMinLength(String val) => val.length >= 6;
  static bool hasUppercase(String val) => _uppercaseRegExp.hasMatch(val);
  static bool hasLowercase(String val) => _lowercaseRegExp.hasMatch(val);
  static bool hasSpecialChar(String val) => _specialCharRegExp.hasMatch(val);
  static bool isPasswordFullyValid(String val) => validatePassword(val) == null;
  static bool isEmailValid(String val) => validateEmail(val) == null;
}
