// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Alexandria';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get coreUnavailableTitle =>
      'O núcleo do Alexandria não está disponível';

  @override
  String get loginTitle => 'Entrar no Alexandria';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginPasswordLabel => 'Senha';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginEmailMissing => 'Informe seu endereço de e-mail.';

  @override
  String get loginEmailMalformed => 'Isso não parece um endereço de e-mail.';

  @override
  String get loginPasswordMissing => 'Informe sua senha.';

  @override
  String get loginRejected =>
      'Esse e-mail e essa senha não correspondem a uma conta.';

  @override
  String get loginNoAccount =>
      'Ainda não há uma conta configurada neste computador.';

  @override
  String get signUpTitle => 'Crie sua conta do Alexandria';

  @override
  String get signUpIntro =>
      'Esta é a única conta. A senha dela não pode ser recuperada, então escolha uma que você não vá perder.';

  @override
  String get signUpPasswordConfirmationLabel => 'Repita a senha';

  @override
  String get signUpSubmit => 'Criar conta';

  @override
  String get signUpPasswordConfirmationMissing => 'Repita sua senha.';

  @override
  String get signUpPasswordMismatch => 'As duas senhas não coincidem.';

  @override
  String get signUpRejected =>
      'O Alexandria não aceitou essas credenciais. Tente uma senha mais longa e menos previsível, que não seja seu endereço de e-mail.';

  @override
  String get signUpAccountExists =>
      'Já existe uma conta neste computador. Entre com ela.';

  @override
  String get signUpGoToLogin => 'Ir para o login';

  @override
  String get loginGoToSignUp => 'Criar uma conta';

  @override
  String get loginSessionEndedTitle => 'Sua sessão foi encerrada';

  @override
  String get catalogLockedTitle => 'Confirme seu endereço de e-mail';

  @override
  String catalogLockedBody(String email) {
    return 'O Alexandria permanece bloqueado até que o endereço $email seja confirmado.';
  }

  @override
  String failureCoreLibraryNotLoaded(String path) {
    return 'Não foi possível carregar o núcleo do Alexandria a partir de $path.';
  }

  @override
  String failureApplicationDirectoryUnavailable(String path) {
    return 'Não foi possível criar a pasta do aplicativo $path.';
  }

  @override
  String get failureCoreInitializationFailed =>
      'O núcleo do Alexandria não conseguiu abrir o catálogo.';

  @override
  String get failureCoreUnhealthy =>
      'O núcleo do Alexandria informou que não está saudável.';

  @override
  String failureCoreVersionUnsupported(String found, String required) {
    return 'Esta versão do Alexandria precisa de um núcleo compatível com $required, mas encontrou $found.';
  }

  @override
  String get failurePreferencesUnreadable =>
      'Não foi possível ler suas preferências, então o tema e o idioma do sistema estão sendo usados.';

  @override
  String get failureInvalidInput =>
      'O Alexandria recusou esse valor como inválido.';

  @override
  String get failureUnauthorized => 'Sua sessão terminou. Entre novamente.';

  @override
  String get failureNotInitialized =>
      'O Alexandria ainda não está pronto. Reinicie o aplicativo.';

  @override
  String get failureNotFound => 'Esse item não existe mais.';

  @override
  String get failureInvalidState =>
      'Isso não pode ser feito com este item agora.';

  @override
  String get failureDisk =>
      'Não foi possível ler ou gravar o arquivo em disco. Nada foi alterado.';

  @override
  String get failureIntegrity =>
      'O arquivo em disco não corresponde mais ao que o Alexandria registrou.';

  @override
  String get failureConfiguration =>
      'Não foi possível ler a configuração do Alexandria.';

  @override
  String get failureConflict => 'Isso já existe no Alexandria.';

  @override
  String get failureUnexpected => 'Algo deu errado no Alexandria.';
}
