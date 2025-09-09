// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MusiConnect';

  @override
  String get home => 'Home';

  @override
  String get jobs => 'Jobs';

  @override
  String get group => 'Group';

  @override
  String get artist => 'Artist';

  @override
  String get chat => 'Chat';

  @override
  String get authUsernameUserTypeRequired =>
      'Please enter username and select user type.';

  @override
  String get authEmailForPasswordReset =>
      'Please enter your email to reset password.';

  @override
  String get authPasswordResetLinkSent =>
      'Password reset link sent to your email.';

  @override
  String get authErrorSendingPasswordReset =>
      'An error occurred while sending the reset email.';

  @override
  String get authLogin => 'Login';

  @override
  String get authRegister => 'Register';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsername => 'Username';

  @override
  String get authUserType => 'User Type';

  @override
  String get authUserTypeMusician => 'Musician';

  @override
  String get authUserTypeBand => 'Band';

  @override
  String get authEnter => 'Enter';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authCreateNewAccount => 'Create new account';

  @override
  String get authAlreadyHaveAccount => 'Already have an account';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authUnexpectedError => 'An unexpected error occurred.';
}
