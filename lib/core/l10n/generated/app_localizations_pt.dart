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
  String get dismiss => 'Dispensar';

  @override
  String get librarySourcesIndex => 'Indexar';

  @override
  String get librarySourcesIndexing => 'Analisando…';

  @override
  String librarySourcesRunComplete(int scanned, int indexed, int skipped) {
    return '$scanned arquivos analisados, $indexed catalogados, $skipped ignorados.';
  }

  @override
  String librarySourcesRunFailedCount(int failed) {
    return '$failed arquivos não puderam ser lidos.';
  }

  @override
  String get librarySourcesRunFailed => 'A análise não foi concluída.';

  @override
  String get librarySourcesRunInterrupted =>
      'A análise não foi concluída, porque o Alexandria foi fechado enquanto ela estava em andamento.';

  @override
  String get librarySourcesRunRefused =>
      'Já existe uma análise desta pasta em andamento.';

  @override
  String get librarySourcesStartFailed =>
      'Não foi possível analisar esta pasta.';

  @override
  String get librarySourcesUnregister => 'Remover';

  @override
  String librarySourcesUnregisterTitle(String label) {
    return 'Remover $label das pastas da biblioteca?';
  }

  @override
  String get librarySourcesUnregisterBody =>
      'O Alexandria vai parar de analisar esta pasta. Tudo o que já foi catalogado a partir dela continua na sua biblioteca, e nada no disco é alterado.';

  @override
  String get librarySourcesUnregisterConfirm => 'Remover a pasta';

  @override
  String get librarySourcesUnregisterRefused =>
      'Esta pasta está sendo analisada. Ela pode ser removida quando a análise terminar.';

  @override
  String get librarySourcesRefresh => 'Atualizar o catálogo';

  @override
  String get librarySourcesRefreshing => 'Reverificando o catálogo…';

  @override
  String librarySourcesRefreshComplete(
    int refreshed,
    int unchanged,
    int missing,
  ) {
    return '$refreshed arquivos atualizados, $unchanged sem alteração, $missing agora ausentes.';
  }

  @override
  String get librarySourcesRefreshRunning =>
      'O catálogo já está sendo reverificado.';

  @override
  String get librarySourcesRefreshEmpty =>
      'Ainda não há nada catalogado. Adicione uma pasta e indexe-a primeiro.';

  @override
  String get librarySourcesRefreshFailed =>
      'Não foi possível reverificar o catálogo.';

  @override
  String get librarySourcesMissingReviewPending =>
      'A revisão de arquivos ausentes chega com o caso de uso dela.';

  @override
  String get destinationVideos => 'Vídeos';

  @override
  String get catalogEmptyTitle => 'Nada deste tipo ainda';

  @override
  String get catalogEmptyFirstRun =>
      'Sua biblioteca está vazia. Adicione uma pasta e indexe-a, e o que estiver dentro aparecerá aqui.';

  @override
  String get catalogEmptyAddFolder => 'Pastas da biblioteca';

  @override
  String get catalogFileMissing => 'Ausente do disco';

  @override
  String catalogCount(int count) {
    return '$count';
  }

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutDetailedList => 'Lista com detalhes';

  @override
  String get layoutGrid => 'Grade';

  @override
  String get layoutLabel => 'Layout';

  @override
  String get layoutSubstituted =>
      'A janela é estreita demais para esse layout, então a lista é exibida no lugar.';

  @override
  String get layoutUnsaved =>
      'O layout mudou, mas a escolha não pôde ser salva — ela não será lembrada na próxima vez.';

  @override
  String get searchLabel => 'Pesquisar na biblioteca';

  @override
  String get searchClear => 'Limpar a pesquisa';

  @override
  String searchNoResults(String term) {
    return 'Nada corresponde a “$term”.';
  }

  @override
  String get searchPartial =>
      'Parte da biblioteca não pôde ser lida, então podem existir mais resultados.';

  @override
  String searchResultsFor(String term) {
    return 'Resultados para “$term”';
  }

  @override
  String get filtersLabel => 'Filtros e ordem';

  @override
  String get filterLifecycle => 'Exibir';

  @override
  String get filterLifecycleActive => 'Na biblioteca';

  @override
  String get filterLifecycleDeleted => 'Excluídos';

  @override
  String get filterLifecycleAll => 'Tudo';

  @override
  String get sortLabel => 'Ordenar por';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByIndexed => 'Data de inclusão';

  @override
  String get sortAscending => 'Crescente';

  @override
  String get sortDescending => 'Decrescente';

  @override
  String get filtersClear => 'Limpar os filtros';

  @override
  String get filtersEmpty => 'Nada corresponde aos filtros definidos.';

  @override
  String get filtersRejected =>
      'Esse filtro foi recusado, então o anterior voltou.';

  @override
  String get detailsTitle => 'Detalhes';

  @override
  String get detailsPath => 'Onde está';

  @override
  String get detailsMetadata => 'Sobre o arquivo';

  @override
  String get detailsState => 'Estado';

  @override
  String get detailsStateActive => 'Na biblioteca';

  @override
  String get detailsStateDeleted => 'Excluído';

  @override
  String get detailsStateMissing => 'Ausente do disco';

  @override
  String get detailsOpen => 'Abrir';

  @override
  String get detailsNoViewer =>
      'Ainda não há nada que abra esse tipo de arquivo.';

  @override
  String get detailsMissingHint =>
      'O Alexandria não encontrou este arquivo onde o catálogo diz que ele está. Reverifique o catálogo para saber se ele voltou.';

  @override
  String get detailsRescan => 'Reverificar o catálogo';

  @override
  String get detailsDeletedHint =>
      'Este registro está excluído. A restauração chega com o caso de uso dela.';

  @override
  String get detailsNotFound => 'Esse arquivo não está mais no catálogo.';

  @override
  String get detailsMetadataNone =>
      'O núcleo não informa mais nada sobre este arquivo.';

  @override
  String get detailsWidth => 'Largura';

  @override
  String get detailsHeight => 'Altura';

  @override
  String get detailsPages => 'Páginas';

  @override
  String get detailsDuration => 'Duração';

  @override
  String get dashboardRecent => 'Adicionados recentemente';

  @override
  String get dashboardRecentNone => 'Nada foi adicionado ainda.';

  @override
  String get dashboardInProgress => 'Em andamento';

  @override
  String get dashboardInProgressNone =>
      'Nada em andamento. As listas de reprodução e de leitura chegam com os casos de uso delas.';

  @override
  String get dashboardCounts => 'O que há na biblioteca';

  @override
  String get dashboardLastRun => 'A última análise';

  @override
  String get dashboardLastRunNone => 'Nada foi analisado nesta sessão.';

  @override
  String get dashboardLastRunRunning => 'Uma análise está em andamento agora.';

  @override
  String get dashboardLastRunComplete => 'A última análise foi concluída.';

  @override
  String get dashboardLastRunFailed => 'A última análise não foi concluída.';

  @override
  String get dashboardLastRunInterrupted =>
      'A última análise foi interrompida quando o Alexandria fechou.';

  @override
  String get detailsEditMetadata => 'Editar metadados';

  @override
  String get musicMetadataTitle => 'Metadados da música';

  @override
  String get musicMetadataFieldTitle => 'Título';

  @override
  String get musicMetadataFieldArtist => 'Artista';

  @override
  String get musicMetadataFieldAlbum => 'Álbum';

  @override
  String get musicMetadataFieldYear => 'Ano';

  @override
  String get musicMetadataFieldGenre => 'Gênero';

  @override
  String get musicMetadataFieldTrack => 'Número da faixa';

  @override
  String get musicMetadataSave => 'Salvar';

  @override
  String get musicMetadataCancel => 'Cancelar';

  @override
  String get musicMetadataErrorNotANumber => 'Digite um número inteiro.';

  @override
  String get musicMetadataErrorYear => 'Digite um ano com quatro dígitos.';

  @override
  String get musicMetadataErrorTrack => 'O número da faixa começa em 1.';

  @override
  String musicMetadataErrorTooLong(int max) {
    return 'Use menos de $max caracteres.';
  }

  @override
  String get signOut => 'Sair';

  @override
  String get signOutUnsavedTitle => 'Alterações não salvas';

  @override
  String get signOutUnsavedMessage =>
      'Sair agora descarta as alterações que você não salvou. Cancele para voltar e salvá-las antes.';

  @override
  String get signOutUnsavedConfirm => 'Sair e descartar';

  @override
  String get signOutIndexRunContinues =>
      'Você saiu enquanto uma varredura ainda estava em andamento. Ela continua no núcleo, e o resultado aparece no seu próximo acesso.';

  @override
  String get videoMetadataTitle => 'Editar metadados do vídeo';

  @override
  String get videoMetadataFieldTitle => 'Título';

  @override
  String get videoMetadataFieldYear => 'Ano';

  @override
  String get videoMetadataFieldResolution => 'Resolução';

  @override
  String get videoMetadataFieldMediaKind => 'Tipo';

  @override
  String get videoMetadataMovie => 'Filme';

  @override
  String get videoMetadataSeries => 'Série';

  @override
  String get videoMetadataSave => 'Salvar';

  @override
  String get videoMetadataCancel => 'Cancelar';

  @override
  String get videoMetadataMarkingWarning =>
      'Este vídeo é acompanhado por episódio. Marcá-lo como filme substitui isso pelo progresso do item inteiro.';

  @override
  String get videoMetadataMarkingConfirm => 'Marcar como filme';

  @override
  String get videoMetadataErrorNotANumber => 'Digite um número inteiro.';

  @override
  String get videoMetadataErrorYear => 'Digite um ano com quatro dígitos.';

  @override
  String videoMetadataErrorTooLong(int max) {
    return 'Use menos de $max caracteres.';
  }

  @override
  String get videoMetadataMarkingCancel => 'Manter como série';

  @override
  String get renameOpen => 'Renomear';

  @override
  String get renameTitle => 'Renomear arquivo';

  @override
  String get renameFieldLabel => 'Nome do arquivo';

  @override
  String get renameSubmit => 'Renomear';

  @override
  String get renameNothingChanged =>
      'Nem o catálogo nem o arquivo em disco foram alterados.';

  @override
  String get renameErrorEmpty => 'Informe um nome de arquivo.';

  @override
  String get renameErrorForbidden =>
      'Este nome usa um caractere que o sistema de arquivos não permite.';

  @override
  String get renameErrorReserved =>
      'Este nome é reservado pelo sistema operacional.';

  @override
  String get renameErrorTrailingDot =>
      'Um nome de arquivo não pode terminar com ponto.';

  @override
  String renameErrorTooLong(int max) {
    return 'Use menos de $max caracteres no nome.';
  }

  @override
  String get editorOpen => 'Editar';

  @override
  String get editorClose => 'Fechar o editor';

  @override
  String get editorSave => 'Salvar';

  @override
  String get editorUnsaved => 'Alterações não salvas';

  @override
  String get editorDismiss => 'Dispensar';

  @override
  String get editorDiscard => 'Descartar';

  @override
  String get editorReload => 'Recarregar do disco';

  @override
  String get editorOverwrite => 'Salvar mesmo assim';

  @override
  String get editorSignInAgain => 'Entrar novamente';

  @override
  String get editorNothingToSave =>
      'O conteúdo não mudou, então nada foi gravado.';

  @override
  String get editorLeaveUnsaved =>
      'Você tem alterações não salvas. Salve, descarte ou continue no editor.';

  @override
  String get editorChangedOnDisk =>
      'Este arquivo mudou no disco desde que você o abriu. Recarregue para ver a nova versão ou salve mesmo assim para substituí-la.';

  @override
  String get editorRecordGone =>
      'Este arquivo não está mais no catálogo. O que você escreveu continua aqui e não foi salvo.';

  @override
  String get editorSessionRejected =>
      'Sua sessão terminou, então isto não pôde ser salvo. Entrar novamente fará você perder o que está na tela.';

  @override
  String get editorCouldNotRead => 'Não foi possível ler este arquivo.';

  @override
  String get editorSaveAndClose => 'Salvar e fechar';

  @override
  String get videoPlay => 'Reproduzir';

  @override
  String get videoPause => 'Pausar';

  @override
  String get videoClose => 'Fechar o player';

  @override
  String get videoSeekBackward => 'Voltar dez segundos';

  @override
  String get videoSeekForward => 'Avançar dez segundos';

  @override
  String get videoFullScreen => 'Tela cheia';

  @override
  String get videoSubtitles => 'Legendas';

  @override
  String get videoSubtitlesOff => 'Desligadas';

  @override
  String get videoNoSubtitles => 'Este arquivo não tem legendas';

  @override
  String get videoAudioTracks => 'Faixas de áudio';

  @override
  String get videoNoAudioTracks => 'Este arquivo tem uma única faixa de áudio';

  @override
  String get videoResume => 'Continuar';

  @override
  String get videoStartOver => 'Começar do início';

  @override
  String get videoFileMissing =>
      'Este arquivo não está onde o catálogo diz que está.';

  @override
  String get videoCannotDecode => 'Não é possível reproduzir este arquivo.';

  @override
  String videoResumePrompt(String position) {
    return 'Você parou de assistir em $position.';
  }

  @override
  String videoTrackUnnamed(String id) {
    return 'Faixa $id';
  }

  @override
  String get audioPlay => 'Reproduzir';

  @override
  String get audioPlayAlbum => 'Reproduzir álbum';

  @override
  String get audioPlayArtist => 'Reproduzir artista';

  @override
  String get audioPause => 'Pausar';

  @override
  String get audioNext => 'Próxima faixa';

  @override
  String get audioPrevious => 'Faixa anterior';

  @override
  String get audioStop => 'Parar';

  @override
  String get audioNothingPlayable =>
      'Não foi possível reproduzir nada desta seleção.';

  @override
  String audioSkipped(String name) {
    return '$name foi pulado — não foi possível reproduzi-lo.';
  }

  @override
  String audioResumePrompt(String position) {
    return 'Você parou esta faixa em $position.';
  }

  @override
  String get audioPlayer => 'Player';

  @override
  String get audioOpenPlayer => 'Abrir o player';

  @override
  String get albumMediumVinyl => 'Um disco de vinil girando em uma vitrola';

  @override
  String get albumMediumTape => 'Uma fita cassete girando em um toca-fitas';

  @override
  String get albumMediumDisc => 'Um disco girando em um player';

  @override
  String get viewerOpen => 'Abrir';

  @override
  String get viewerClose => 'Fechar o visualizador';

  @override
  String get viewerNext => 'Próximo capítulo';

  @override
  String get viewerPrevious => 'Capítulo anterior';

  @override
  String get viewerFileMissing =>
      'Este arquivo não está onde o catálogo diz que está.';

  @override
  String get viewerUnreadable =>
      'Não foi possível ler este arquivo. Ele pode estar danificado ou não ser o formato que o nome indica.';

  @override
  String get viewerEncrypted =>
      'Este documento está protegido por senha, que este aplicativo não pede nem armazena.';

  @override
  String get viewerNone =>
      'Ainda não há um visualizador para este tipo de arquivo. As outras ações continuam disponíveis.';

  @override
  String viewerUnsupportedFormat(String name) {
    return '$name está em um formato que nenhum decodificador incluído consegue abrir.';
  }

  @override
  String viewerChapterOf(int position, int total) {
    return 'Capítulo $position de $total';
  }
}
