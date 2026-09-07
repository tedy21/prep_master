/// Maps phone numbers to Firebase Email/Password credentials.
///
/// Firebase has no native "phone + password" provider. We store accounts as
/// `{digits}@phone.prepmaster.local` and keep the real number in Firestore.
abstract final class PhoneAuthMapper {
  static const _domain = 'phone.prepmaster.local';

  /// Normalize to digits only, defaulting Ethiopian numbers to country code 251.
  static String normalize(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return digits;

    if (digits.startsWith('251')) return digits;
    if (digits.startsWith('0') && digits.length >= 10) {
      return '251${digits.substring(1)}';
    }
    if (digits.length == 9) return '251$digits';
    return digits;
  }

  static String toAuthEmail(String phone) {
    final normalized = normalize(phone);
    return '$normalized@$_domain';
  }

  static String toDisplayPhone(String phone) {
    final normalized = normalize(phone);
    if (normalized.startsWith('251') && normalized.length >= 12) {
      return '+$normalized';
    }
    return '+$normalized';
  }

  static String? fromAuthEmail(String? email) {
    if (email == null || !email.endsWith('@$_domain')) return null;
    final digits = email.split('@').first;
    if (digits.isEmpty) return null;
    return '+$digits';
  }

  static String? validate(String input) {
    final normalized = normalize(input);
    if (normalized.length < 10) {
      return 'Enter a valid phone number';
    }
    if (!RegExp(r'^251\d{9}$').hasMatch(normalized) &&
        !RegExp(r'^\d{10,15}$').hasMatch(normalized)) {
      return 'Use format 09XX XXX XXXX or +2519XXXXXXXX';
    }
    return null;
  }
}
