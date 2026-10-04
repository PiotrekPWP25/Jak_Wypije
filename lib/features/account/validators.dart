/// Form validators – return a Polish message or `null` when valid.
abstract final class Validators {
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Podaj adres e-mail';
    if (!_email.hasMatch(text)) return 'Nieprawidłowy adres e-mail';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Podaj hasło';
    if (text.length < minPasswordLength) {
      return 'Hasło musi mieć co najmniej $minPasswordLength znaków';
    }
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Podaj imię lub pseudonim';
    if (text.length > 24) return 'Maksymalnie 24 znaki';
    return null;
  }
}
