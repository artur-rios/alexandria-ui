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
  String get failureRateLimited =>
      'Tentativas demais. Espere um momento e tente de novo.';

  @override
  String get failureServiceUnavailable =>
      'O Alexandria não conseguiu acessar um serviço necessário, então essa etapa não aconteceu.';

  @override
  String rejectionPasswordTooShort(String min) {
    return 'Use pelo menos $min caracteres.';
  }

  @override
  String rejectionPasswordTooLong(String max) {
    return 'Use no máximo $max caracteres.';
  }

  @override
  String get rejectionPasswordWhitespace => 'A senha não pode ser só espaços.';

  @override
  String get rejectionPasswordRepeatedCharacter =>
      'A senha não pode ser um único caractere repetido.';

  @override
  String get rejectionPasswordTooCommon =>
      'Essa senha é comum demais. Escolha algo menos previsível.';

  @override
  String get rejectionPasswordContainsEmail =>
      'A senha não pode conter seu endereço de e-mail.';

  @override
  String get rejectionEmailUntrimmed =>
      'Remova os espaços ao redor do seu endereço de e-mail.';

  @override
  String get catalogLockedUndeliverable =>
      'Não foi possível enviar a mensagem de confirmação, então ela não está a caminho. O Alexandria ainda não consegue enviar e-mails.';

  @override
  String get failureUnexpected => 'Algo deu errado no Alexandria.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loading => 'Carregando';

  @override
  String get shellAreaPending => 'Nada para mostrar aqui ainda.';

  @override
  String get playbackBarLabel => 'Reprodução';

  @override
  String get playbackNothingPlaying => 'Nada em reprodução';

  @override
  String get destinationHome => 'Início';

  @override
  String get destinationMusic => 'Músicas';

  @override
  String get destinationMovies => 'Filmes';

  @override
  String get destinationSeries => 'Séries';

  @override
  String get destinationBooks => 'Livros';

  @override
  String get destinationComicBooks => 'Quadrinhos';

  @override
  String get destinationNotes => 'Notas';

  @override
  String get destinationPages => 'Páginas';

  @override
  String get destinationImages => 'Imagens';

  @override
  String get destinationBookmarks => 'Favoritos';

  @override
  String get preferencesTitle => 'Preferências';

  @override
  String get preferencesOpen => 'Abrir preferências';

  @override
  String get preferencesThemeLabel => 'Tema';

  @override
  String get preferencesThemeSystem => 'Acompanhar o sistema';

  @override
  String get preferencesThemeLight => 'Claro';

  @override
  String get preferencesThemeDark => 'Escuro';

  @override
  String get preferencesLanguageLabel => 'Idioma';

  @override
  String get preferencesLanguageSystem => 'Acompanhar o sistema';

  @override
  String get preferencesUnsaved =>
      'Sua escolha foi aplicada, mas não pôde ser salva — ela não será lembrada na próxima vez que o Alexandria iniciar.';

  @override
  String get preferencesClose => 'Concluído';

  @override
  String get changeCredentialsOpen => 'Alterar seu e-mail e senha';

  @override
  String get changeCredentialsTitle => 'Alterar credenciais';

  @override
  String get changeCredentialsIntro =>
      'Os dois são substituídos juntos. Você continua conectado.';

  @override
  String get changeCredentialsEmailLabel => 'Novo e-mail';

  @override
  String get changeCredentialsPasswordLabel => 'Nova senha';

  @override
  String get changeCredentialsConfirmationLabel => 'Repita a nova senha';

  @override
  String get changeCredentialsSubmit => 'Alterar';

  @override
  String get changeCredentialsDone => 'Seu e-mail e senha foram alterados.';

  @override
  String get changeCredentialsRejected =>
      'A alteração foi recusada, e seu e-mail e senha continuam os mesmos.';

  @override
  String get librarySourcesOpen => 'Pastas da biblioteca';

  @override
  String get librarySourcesTitle => 'Pastas da biblioteca';

  @override
  String get librarySourcesEmptyTitle => 'Nenhuma pasta da biblioteca ainda';

  @override
  String get librarySourcesEmptyBody =>
      'Adicione uma pasta do seu disco e o Alexandria vai catalogar o que houver dentro dela. Nada é movido, copiado ou alterado.';

  @override
  String get librarySourcesAdd => 'Adicionar uma pasta';

  @override
  String librarySourcesMissing(String path) {
    return 'Não há nenhuma pasta em $path. Nada foi adicionado.';
  }

  @override
  String librarySourcesUnreadable(String path) {
    return 'A pasta em $path não pode ser lida. Nada foi adicionado.';
  }

  @override
  String get librarySourcesAlreadyRegistered =>
      'Essa pasta já está na sua biblioteca.';

  @override
  String get librarySourcesOverlapTitle => 'Estas pastas se sobrepõem';

  @override
  String librarySourcesOverlapBody(String path, String existing) {
    return '$path se sobrepõe a $existing, que já está na sua biblioteca. Os arquivos dentro das duas serão catalogados uma vez para cada pasta.';
  }

  @override
  String get librarySourcesOverlapConfirm => 'Adicionar mesmo assim';

  @override
  String get librarySourcesIndexLater =>
      'A indexação chega com o próximo caso de uso.';

  @override
  String get dismiss => 'Dispensar';
}
