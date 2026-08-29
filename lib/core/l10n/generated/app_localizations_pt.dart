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
  String get failureUnexpected => 'Algo deu errado no Alexandria.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loading => 'Carregando';

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
  String get preferencesLabel => 'Preferências';

  @override
  String get settingsMenuLabel => 'Configurações';

  @override
  String get settingsMenuOpen => 'Abrir configurações';

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
  String get animationLabel => 'Animação do álbum';

  @override
  String get animationByYear => 'Seguir o ano do álbum';

  @override
  String get animationVinyl => 'Sempre vinil';

  @override
  String get animationTape => 'Sempre fita cassete';

  @override
  String get animationDisc => 'Sempre CD';

  @override
  String get animationOff => 'Desligada';

  @override
  String get startupRecheckLabel => 'Verificar a biblioteca ao iniciar';

  @override
  String get startupRecheckDescription =>
      'Procura arquivos adicionados, alterados ou removidos enquanto o Alexandria esteve fechado.';

  @override
  String get preferencesUnsaved =>
      'Sua escolha foi aplicada, mas não pôde ser salva — ela não será lembrada na próxima vez que o Alexandria iniciar.';

  @override
  String get preferencesClose => 'Concluído';

  @override
  String get changeCredentialsOpen => 'Alterar credenciais…';

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
  String get librarySourcesClose => 'Fechar as pastas da biblioteca';

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
  String get indexScopeTitle => 'O que há nesta pasta?';

  @override
  String get indexScopeBody =>
      'O Alexandria vai catalogar apenas os tipos de arquivo que você escolher aqui. Uma pasta de música limitada a música mantém as capas fora das suas imagens.';

  @override
  String get indexScopeAll => 'Todos os arquivos suportados';

  @override
  String get indexScopeConfirm => 'Adicionar a pasta';

  @override
  String get indexScopeEmpty =>
      'Escolha ao menos um tipo de arquivo, ou todos eles.';

  @override
  String get librarySourcesScopeUnreadable =>
      'Abrange tipos de arquivo que esta versão não reconhece';

  @override
  String get librarySourcesStartUnreadableScope =>
      'Esta pasta está definida para abranger tipos de arquivo que esta versão não reconhece, então ela não foi analisada. Remova-a e adicione-a novamente para escolher o que ela abrange.';

  @override
  String get librarySourcesStartNotRegistered =>
      'Esta pasta não está mais na sua biblioteca, então ela não foi analisada.';

  @override
  String get librarySourcesScopeAll => 'Todos os arquivos suportados';

  @override
  String librarySourcesScopeOnly(String types) {
    return 'Somente $types';
  }

  @override
  String get libraryTypeAudio => 'Música';

  @override
  String get libraryTypeVideo => 'Vídeo';

  @override
  String get libraryTypeDocument => 'Livros';

  @override
  String get libraryTypeComic => 'Quadrinhos';

  @override
  String get libraryTypeText => 'Notas';

  @override
  String get libraryTypeHtml => 'Páginas salvas';

  @override
  String get libraryTypeImage => 'Imagens';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get librarySourcesRescan => 'Reanalisar';

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
  String get librarySourcesRunCancelled => 'A análise foi cancelada.';

  @override
  String get librarySourcesRunPaused =>
      'A análise está pausada. Ela pode ser retomada de onde parou.';

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
  String get librarySourcesRecheck => 'Reverificar biblioteca';

  @override
  String get librarySourcesPause => 'Pausar';

  @override
  String get librarySourcesResume => 'Retomar';

  @override
  String get librarySourcesCancelRun => 'Cancelar';

  @override
  String get librarySourcesCancelRunTitle => 'Cancelar esta análise?';

  @override
  String get librarySourcesCancelRunConfirm =>
      'Esta análise não pode ser retomada depois de cancelada. Tudo o que ela já catalogou continua na sua biblioteca.';

  @override
  String get librarySourcesCancelRunAction => 'Cancelar a análise';

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
      'Este registro está excluído. Restaure-o para editá-lo ou abri-lo novamente.';

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
  String get detailsFileSection => 'O arquivo';

  @override
  String get detailsFileName => 'Nome do arquivo';

  @override
  String get detailsFileSize => 'Tamanho em disco';

  @override
  String get detailsFileFormat => 'Formato';

  @override
  String get detailsFileModified => 'Última modificação';

  @override
  String get dashboardRecent => 'Adicionados recentemente';

  @override
  String get dashboardRecentNone => 'Nada foi adicionado ainda.';

  @override
  String get dashboardInProgress => 'Em andamento';

  @override
  String get dashboardInProgressNone => 'Nada em andamento.';

  @override
  String dashboardInProgressIn(String list) {
    return 'Em $list';
  }

  @override
  String dashboardInProgressInAt(String list, String progress) {
    return 'Em $list — $progress';
  }

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
  String get musicMetadataFieldAlbumArtist => 'Artista do álbum';

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
  String get musicViewArtists => 'Artistas';

  @override
  String get musicViewAlbums => 'Álbuns';

  @override
  String get musicViewSongs => 'Músicas';

  @override
  String get musicBreadcrumbRoot => 'Biblioteca de música';

  @override
  String get musicUnknownTitle => 'Título desconhecido';

  @override
  String get musicUnknownArtist => 'Artista desconhecido';

  @override
  String get musicUnknownAlbum => 'Álbum desconhecido';

  @override
  String get musicRowActions => 'Ações desta faixa';

  @override
  String get musicEmpty => 'Nenhum arquivo de áudio catalogado ainda.';

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
  String get audioClosePlayer => 'Fechar o player';

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

  @override
  String get comicFitPage => 'Ajustar à página';

  @override
  String get comicFitWidth => 'Ajustar à largura';

  @override
  String get comicNextPage => 'Próxima página';

  @override
  String get comicPreviousPage => 'Página anterior';

  @override
  String comicPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String comicPagesSkipped(String pages) {
    return 'Não foi possível ler estas páginas: $pages';
  }

  @override
  String get imageFit => 'Ajustar à janela';

  @override
  String get imageNext => 'Próxima imagem';

  @override
  String get imagePrevious => 'Imagem anterior';

  @override
  String imageOf(int position, int total) {
    return '$position de $total';
  }

  @override
  String get pageScriptsNotRun =>
      'Esta página é exibida como conteúdo. Nenhum script contido nela é executado.';

  @override
  String get pageMalformed =>
      'A marcação desta página está incompleta, então parte dela pode estar faltando.';

  @override
  String pageMissingAssets(String assets) {
    return 'Estes arquivos referenciados pela página não estão no disco: $assets';
  }

  @override
  String get bookmarkAdd => 'Adicionar favorito';

  @override
  String get bookmarkEdit => 'Editar este favorito';

  @override
  String get bookmarkCreate => 'Criar';

  @override
  String get bookmarkSave => 'Salvar';

  @override
  String get bookmarkTitleLabel => 'Título';

  @override
  String get bookmarkUrlLabel => 'Endereço';

  @override
  String get bookmarksNone => 'Você ainda não salvou nenhum favorito.';

  @override
  String get bookmarkFieldEmpty => 'Isto não pode ficar vazio.';

  @override
  String get bookmarkUrlMalformed => 'Isto não é um endereço.';

  @override
  String get bookmarkUrlUnopenable =>
      'Digite um endereço começando com http:// ou https://.';

  @override
  String get bookmarkNoBrowser =>
      'Não foi possível abrir um navegador para este favorito.';

  @override
  String get bookmarkCopyUrl => 'Copiar o endereço';

  @override
  String get watchlistsTitle => 'Listas de exibição';

  @override
  String get watchlistsOpen => 'Listas de exibição';

  @override
  String get watchlistsNone => 'Você ainda não criou uma lista de exibição.';

  @override
  String get watchlistNameLabel => 'Nome da lista';

  @override
  String get watchlistCreate => 'Criar';

  @override
  String get watchlistNameEmpty => 'Dê um nome à lista.';

  @override
  String get watchlistDelete => 'Excluir esta lista';

  @override
  String get watchlistEmpty => 'Nada está sendo acompanhado nesta lista ainda.';

  @override
  String get watchlistAddTo => 'Adicionar a uma lista';

  @override
  String get watchlistRemoveVideo => 'Parar de acompanhar este vídeo';

  @override
  String get watchlistAlreadyTracked => 'Esse vídeo já está nessa lista.';

  @override
  String get watchlistNotFound => 'Essa lista ou esse vídeo não está mais lá.';

  @override
  String get watchStatePending => 'Não iniciado';

  @override
  String get watchStateWatching => 'Assistindo';

  @override
  String get watchStateWatched => 'Assistido';

  @override
  String watchlistDeleteMessage(String name) {
    return 'Excluir $name? Os vídeos são mantidos — apenas o acompanhamento é removido.';
  }

  @override
  String watchlistAlreadyIn(String name) {
    return '$name — já está lá';
  }

  @override
  String watchlistItemCount(int count) {
    return '$count acompanhados';
  }

  @override
  String get watchProgressSave => 'Salvar progresso';

  @override
  String get watchCurrentEpisodeLabel => 'Episódio';

  @override
  String get watchTotalEpisodesLabel => 'de quantos';

  @override
  String get watchEpisodeNotANumber => 'Digite um número inteiro.';

  @override
  String get watchEpisodeNotPositive =>
      'Os episódios são contados a partir de 1.';

  @override
  String get watchEpisodeBeyondTotal =>
      'Isso passa do total que você informou.';

  @override
  String watchEpisode(int episode) {
    return 'episódio $episode';
  }

  @override
  String watchEpisodeOf(int episode, int total) {
    return 'episódio $episode de $total';
  }

  @override
  String get readingListsTitle => 'Listas de leitura';

  @override
  String get readingListsOpen => 'Listas de leitura';

  @override
  String get readingListsNone => 'Você ainda não criou uma lista de leitura.';

  @override
  String get readingListNameLabel => 'Nome da lista de leitura';

  @override
  String get readingListCreate => 'Criar';

  @override
  String get readingListNameEmpty => 'Dê um nome à lista de leitura.';

  @override
  String get readingListDelete => 'Excluir esta lista de leitura';

  @override
  String get readingListEmpty =>
      'Nada está sendo acompanhado nesta lista ainda.';

  @override
  String get readingListAddTo => 'Adicionar a uma lista de leitura';

  @override
  String get readingListRemoveItem => 'Parar de acompanhar este item';

  @override
  String get readingListAlreadyTracked =>
      'Esse item já está nessa lista de leitura.';

  @override
  String get readingListNotFound => 'Essa lista ou esse item não está mais lá.';

  @override
  String get readStatePending => 'Não iniciado';

  @override
  String get readStateReading => 'Lendo';

  @override
  String get readStateRead => 'Lido';

  @override
  String readingListDeleteMessage(String name) {
    return 'Excluir $name? Os livros e quadrinhos são mantidos — apenas o acompanhamento é removido.';
  }

  @override
  String readingListAlreadyIn(String name) {
    return '$name — já está lá';
  }

  @override
  String readingListItemCount(int count) {
    return '$count acompanhados';
  }

  @override
  String get playlistsTitle => 'Playlists';

  @override
  String get playlistsOpen => 'Playlists';

  @override
  String get playlistsNone => 'Você ainda não criou uma playlist.';

  @override
  String get playlistNameLabel => 'Nome da playlist';

  @override
  String get playlistRenameLabel => 'Novo nome';

  @override
  String get playlistCreate => 'Criar';

  @override
  String get playlistRenameSave => 'Renomear';

  @override
  String get playlistRename => 'Renomear esta playlist';

  @override
  String get playlistDelete => 'Excluir esta playlist';

  @override
  String get playlistNameEmpty => 'Dê um nome à playlist.';

  @override
  String get playlistNotFound => 'Essa playlist não está mais lá.';

  @override
  String playlistDeleteMessage(String name) {
    return 'Excluir $name? As faixas nela são mantidas — apenas a playlist é removida.';
  }

  @override
  String get playlistDetailEmpty => 'Esta playlist ainda não tem faixas.';

  @override
  String get playlistRemoveTrack => 'Remover da playlist';

  @override
  String get enrichmentLyricsTitle => 'Letra';

  @override
  String enrichmentLyricsSource(String source) {
    return 'Letra de $source';
  }

  @override
  String enrichmentImageCredit(String source) {
    return 'Fotografia: $source';
  }

  @override
  String get enrichmentFindForTrack => 'Buscar letra e imagens';

  @override
  String get enrichmentLookingUp => 'Buscando…';

  @override
  String get enrichmentNothingFound => 'Nada encontrado para esta faixa.';

  @override
  String get enrichmentUnavailable =>
      'A busca de informações musicais está desativada nesta instalação.';

  @override
  String get playlistPlay => 'Reproduzir esta playlist';

  @override
  String get playlistAddTo => 'Adicionar a uma playlist';

  @override
  String get playlistAddAlbumTo => 'Adicionar álbum a uma playlist';

  @override
  String get playlistAddArtistTo => 'Adicionar artista a uma playlist';

  @override
  String get playlistAddCreateOne => 'Crie uma playlist primeiro';

  @override
  String get readCurrentIssueLabel => 'Edição atual';

  @override
  String get readTotalIssuesLabel => 'Total de edições';

  @override
  String get readIssueNotANumber => 'Use um número inteiro.';

  @override
  String get readIssueNotPositive => 'As edições são contadas a partir de um.';

  @override
  String get readIssueBeyondTotal => 'Isso passa do total que você informou.';

  @override
  String get readProgressSave => 'Salvar progresso';

  @override
  String readIssue(int current) {
    return 'edição $current';
  }

  @override
  String readIssueOf(int current, int total) {
    return 'edição $current de $total';
  }

  @override
  String get deleteFile => 'Excluir este arquivo';

  @override
  String get deleteFileOnDisk => 'O arquivo no disco não é afetado.';

  @override
  String get deleteFileInUse =>
      'Ele está tocando ou aberto agora — confirmar interrompe isso.';

  @override
  String get deleteBookmark => 'Excluir este favorito';

  @override
  String get deleteAlreadyDeleted => 'Esse registro já havia sido excluído.';

  @override
  String get deleteNotFound => 'Esse registro não está mais lá.';

  @override
  String deleteFileMessage(String name) {
    return 'Ocultar $name da biblioteca? Ele continua restaurável.';
  }

  @override
  String deleteBookmarkMessage(String title) {
    return 'Ocultar $title dos seus favoritos? Ele continua restaurável.';
  }

  @override
  String get deletedItemsTitle => 'Itens excluídos';

  @override
  String get deletedItemsOpen => 'Itens excluídos';

  @override
  String get deletedItemsNone => 'Nada foi excluído.';

  @override
  String get restoreRecord => 'Restaurar';

  @override
  String get restoreNotFound =>
      'Esse registro não pode ser restaurado — ele sumiu ou o prazo passou.';

  @override
  String get retentionElapsed =>
      'Não é mais restaurável — só pode ser expurgado.';

  @override
  String get retentionUnknown => 'Restaurável';

  @override
  String retentionRemaining(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Restaurável por mais $days dias',
      one: 'Restaurável por mais 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get purgeRecord => 'Expurgar';

  @override
  String get purgeRecordOnDisk => 'O arquivo no disco não é removido.';

  @override
  String get purgeNotDeleted =>
      'Exclua esse registro primeiro — só um registro excluído pode ser expurgado.';

  @override
  String get purgeNotFound => 'Esse registro não está mais lá.';

  @override
  String get purgeNothingOnDisk =>
      'O registro foi removido e nenhum arquivo foi encontrado no disco.';

  @override
  String get purgeDiskFailed =>
      'Nada foi removido — nem o arquivo nem o registro.';

  @override
  String purgeRecordMessage(String name) {
    return 'Remover $name do catálogo permanentemente? Isso não pode ser desfeito.';
  }

  @override
  String purgeTooSoon(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Esse registro pode ser expurgado em $days dias.',
      one: 'Esse registro pode ser expurgado em 1 dia.',
    );
    return '$_temp0';
  }

  @override
  String get purgeOnDiskTitle => 'Remover do disco';

  @override
  String get purgeOnDiskAction => 'Excluir o arquivo do disco';

  @override
  String get purgeOnDiskExplanation =>
      'Esta é a única ação aqui que remove seus dados do disco. Todas as outras mantêm o arquivo e alteram apenas o catálogo.';

  @override
  String get purgeOnDiskIrreversible => 'Isso não pode ser desfeito.';

  @override
  String purgeOnDiskMessage(String path) {
    return 'Excluir $path do disco e remover seu registro?';
  }

  @override
  String get missingFilesTitle => 'Arquivos ausentes';

  @override
  String get missingFilesOpen => 'Arquivos ausentes';

  @override
  String get missingFilesNone =>
      'Todos os arquivos catalogados foram encontrados no disco.';

  @override
  String get missingFilesExplanation =>
      'Estes registros continuam no catálogo — nada é removido porque um arquivo está ausente. Reexamine para ver se eles voltaram, ou abra um registro para decidir o que fazer.';

  @override
  String get missingFilesRescan => 'Reexaminar a biblioteca';

  @override
  String get missingFilesOpenDetails => 'Abrir';

  @override
  String get missingFilesUnregisteredFolder =>
      'De uma pasta que não está mais registrada.';

  @override
  String get recoveryCodesTitle => 'Guarde seus códigos de recuperação';

  @override
  String get recoveryCodesExplanation =>
      'Esta é a única vez que eles são exibidos. Cada um substitui uma senha esquecida uma única vez — sem eles, uma senha esquecida significa uma biblioteca perdida.';

  @override
  String get recoveryCodesCopy => 'Copiar os códigos';

  @override
  String get recoveryCodesCopied => 'Copiados para a área de transferência.';

  @override
  String get recoveryCodesAcknowledge => 'Eu os guardei';

  @override
  String get recoveryCodesNone =>
      'Sua conta foi criada, mas nenhum código de recuperação veio com ela. Gere um conjunto nas preferências antes de precisar de um.';

  @override
  String get recoveryTitle => 'Recuperar acesso';

  @override
  String get recoveryOpen => 'Não consigo entrar';

  @override
  String get recoveryExplanation =>
      'Digite um dos códigos de recuperação que você guardou quando a conta foi criada e escolha uma nova senha. O código é consumido ao ser usado, e todas as sessões abertas são encerradas.';

  @override
  String get recoveryCodeLabel => 'Código de recuperação';

  @override
  String get recoveryNewPassword => 'Nova senha';

  @override
  String get recoveryConfirmPassword => 'Repita a nova senha';

  @override
  String get recoveryCodeMissing => 'Digite um código de recuperação.';

  @override
  String get recoveryPasswordMissing => 'Digite uma nova senha.';

  @override
  String get recoverySubmit => 'Substituir a senha';

  @override
  String get recoveryCodeUnknown =>
      'Esse não é um dos códigos de recuperação desta conta. Verifique e tente novamente.';

  @override
  String get recoveryCodeUsed =>
      'Esse código de recuperação já foi usado. Cada um funciona uma vez — tente outro da sua lista.';

  @override
  String get recoveryRefused =>
      'Não foi possível substituir a senha. Verifique o código e tente novamente.';

  @override
  String get recoveryDone => 'Sua senha foi substituída';

  @override
  String get recoveryDoneExplanation =>
      'O código usado foi consumido e todas as sessões abertas foram encerradas. Entre com a nova senha.';

  @override
  String get recoveryBackToLogin => 'Voltar para entrar';

  @override
  String get recoveryCodesRegenerate => 'Gerar novos códigos de recuperação';

  @override
  String get recoveryCodesRegenerateMessage =>
      'Todos os códigos que você tem agora deixam de funcionar, e dez novos tomam o lugar deles. Eles são exibidos uma única vez.';

  @override
  String get recoveryCodesNoneLeft =>
      'Não resta nenhum código de recuperação. Gere um conjunto enquanto você ainda sabe sua senha.';

  @override
  String recoveryCodesRemaining(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count códigos de recuperação restantes',
      one: '1 código de recuperação restante',
    );
    return '$_temp0';
  }

  @override
  String get collectionsTitle => 'Coleções';

  @override
  String get collectionsOpen => 'Coleções';

  @override
  String get collectionsNone => 'Você ainda não criou uma coleção.';

  @override
  String get collectionNameLabel => 'Nome da coleção';

  @override
  String get collectionRenameLabel => 'Novo nome';

  @override
  String get collectionCreate => 'Criar';

  @override
  String get collectionRenameSave => 'Renomear';

  @override
  String get collectionRename => 'Renomear esta coleção';

  @override
  String get collectionDelete => 'Excluir esta coleção';

  @override
  String get collectionNameEmpty => 'Dê um nome à coleção.';

  @override
  String get collectionNotFound => 'Essa coleção não está mais lá.';

  @override
  String get collectionKindFile => 'Arquivos';

  @override
  String get collectionKindBookmark => 'Favoritos';

  @override
  String collectionDeleteMessage(String name) {
    return 'Excluir $name? Os itens dentro dela são mantidos — apenas o agrupamento é removido.';
  }

  @override
  String collectionItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
      zero: 'Vazia',
    );
    return '$_temp0';
  }

  @override
  String get collectionAddItems => 'Adicionar itens';

  @override
  String get collectionAddChosen => 'Adicionar';

  @override
  String get collectionRemoveItem => 'Remover desta coleção';

  @override
  String get collectionEmpty => 'Esta coleção está vazia.';

  @override
  String get collectionNoCandidates =>
      'Não há nada do tipo desta coleção para adicionar.';

  @override
  String collectionItemsAdded(String names) {
    return 'Adicionados: $names';
  }

  @override
  String collectionItemsAlreadyPresent(String names) {
    return 'Já nesta coleção: $names';
  }

  @override
  String collectionItemNotAdded(String name, String reason) {
    return '$name não foi adicionado — $reason';
  }

  @override
  String get bookmarkCollectionLabel => 'Coleção';

  @override
  String get bookmarkCollectionNone => 'Fora de uma coleção';

  @override
  String get bookmarkFilterLabel => 'Mostrar';

  @override
  String get bookmarkFilterAll => 'Todos os favoritos';

  @override
  String get collectionItemWrongKind => 'não é do tipo desta coleção';

  @override
  String get collectionItemGone => 'ele não existe mais';

  @override
  String get libraryToolsOpen => 'Ferramentas da biblioteca';

  @override
  String get libraryToolsLabel => 'Biblioteca';

  @override
  String get libraryToolsGroupLibrary => 'Biblioteca';

  @override
  String get libraryToolsGroupTracking => 'Acompanhamento';

  @override
  String get libraryToolsGroupReview => 'Revisão';

  @override
  String get activityBarLabel => 'Indexação em segundo plano';

  @override
  String get activityDiscovering => 'Procurando pastas…';

  @override
  String activityProgress(int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$processedString de $totalString';
  }

  @override
  String activityRemaining(String duration) {
    return 'faltam cerca de $duration';
  }

  @override
  String activityDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
      zero: 'menos de um minuto',
    );
    return '$_temp0';
  }

  @override
  String activityDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String activityPaused(int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Pausado — $processedString de $totalString';
  }

  @override
  String activityAggregate(int count, int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Indexando $count pastas — $processedString de $totalString';
  }

  @override
  String activityAggregateDiscovering(int count) {
    return 'Indexando $count pastas';
  }

  @override
  String activityAggregatePaused(int count, int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$count pastas pausadas — $processedString de $totalString';
  }

  @override
  String activityAggregatePausedDiscovering(int count) {
    return '$count pastas pausadas';
  }

  @override
  String activityComplete(String folder) {
    return 'Indexação de $folder concluída';
  }

  @override
  String activityFailed(String folder) {
    return 'A indexação de $folder falhou';
  }

  @override
  String get activityCatalog => 'o catálogo';

  @override
  String get activityRepacing =>
      'Recomeçando a verificação do início em velocidade baixa';

  @override
  String get activityRepacingNormal =>
      'Recomeçando a verificação do início em velocidade normal';

  @override
  String get activityPause => 'Pausar';

  @override
  String get activityResume => 'Retomar';

  @override
  String get activityCancel => 'Cancelar';

  @override
  String get activityViewAll => 'Ver';

  @override
  String get activityPriorityLow => 'Baixa';

  @override
  String get activityPriorityNormal => 'Normal';

  @override
  String get activityDismiss => 'Dispensar';
}
