import 'package:flutter/material.dart';

import '../core/utils/partida_em_andamento_repository.dart';
import '../core/utils/partida_repository.dart';
import '../core/utils/volei_utils.dart';
import '../models/avaliacao_fundamento.dart';
import '../models/complexo_jogo.dart';
import '../models/fundamento.dart';
import '../models/jogador.dart';
import '../models/partida.dart';
import '../models/partida_em_andamento.dart';
import '../models/set_resultado.dart';
import '../models/sistema_rotacao.dart';
import '../widgets/componente_bola.dart';
import '../widgets/componente_quadra.dart';
import '../widgets/menu_avaliacao_fundamento.dart';
import '../widgets/menus_scout.dart';
import '../widgets/placar_header.dart';

class JogoVolei extends StatefulWidget {
  final String nomeNossaEquipe;
  final List<Jogador> titularesNossos; // exatamente 6, ordem = posições 1 a 6
  final List<Jogador> bancoNosso;
  final SistemaRotacao sistemaNosso;
  final Jogador? liberoNosso;

  final String nomeAdversario;
  final List<Jogador> titularesAdversario; // exatamente 6, ordem = posições 1 a 6
  final List<Jogador> bancoAdversario;
  final SistemaRotacao sistemaAdversario;
  final Jogador? liberoAdversario;

  /// Quando presente, o jogo começa retomando esse estado salvo (ver
  /// "Continuar Jogo") em vez de começar do zero.
  final PartidaEmAndamento? estadoSalvo;

  const JogoVolei({
    super.key,
    this.nomeNossaEquipe = "NÓS",
    required this.titularesNossos,
    this.bancoNosso = const [],
    this.sistemaNosso = SistemaRotacao.cincoPorUm,
    this.liberoNosso,
    this.nomeAdversario = "ADVERSÁRIO",
    required this.titularesAdversario,
    this.bancoAdversario = const [],
    this.sistemaAdversario = SistemaRotacao.cincoPorUm,
    this.liberoAdversario,
    this.estadoSalvo,
  })  : assert(titularesNossos.length == 6, "É preciso escalar exatamente 6 titulares (nossa equipe)"),
        assert(titularesAdversario.length == 6, "É preciso escalar exatamente 6 titulares (adversário)");

  @override
  State<JogoVolei> createState() => _JogoVoleiState();
}

class _JogoVoleiState extends State<JogoVolei> {
  bool aguardandoCliqueDestino = false;
  String? acaoTemporaria;
  bool mostrandoMenuAcaoRapida = false;
  int placarNossaEquipe = 0;
  int placarAdversario = 0;
  String ladoComPosse = "baixo"; // "cima" ou "baixo"
  int contadorToques = 0;
  // true só entre um novo saque e o primeiro toque válido depois dele —
  // é o que diferencia "preciso checar se cruzou a rede" (saque) de
  // "toque zero por causa de um reset de bloqueio" (não precisa cruzar).
  bool aguardandoSaqueCruzar = true;
  String? jogadorSelecionado;
  // De qual time é o jogadorSelecionado (true=nosso, false=adversário) —
  // usado como fonte da verdade pra decidir quem pontua num PONTO/ERRO,
  // em vez de depender de onde a bola caiu na tela (ver _aplicarResultado).
  bool? _timeDoJogadorSelecionado;
  // Quem está na posição 1 (saque) do time que está sacando agora — a
  // qualidade do saque é derivada do que acontece na recepção adversária
  // (ver _simboloSaquePorRecepcao), então precisamos saber quem foi.
  Jogador? _servidorAtual;
  bool? _servidorEhNosso;
  String? acaoQualidade;
  bool mostrandoMenuJogadores = false;
  bool mostrandoMenuQualidade = false;

  final double qLargura = 300;
  final double qAltura = 500;

  // Desloca a quadra (e tudo que é relativo a ela: bola, rede, zonas de
  // saque) um pouco pra baixo do centro da tela, pra sobrar espaço em
  // cima e a bola do saque do time de cima não brigar com o placar.
  final double deslocamentoVerticalQuadra = 55;

  /// Ponto Y absoluto do topo da quadra — única fonte de verdade pra
  /// esse cálculo, usada em todo o resto do arquivo.
  double _qInicioY(double alturaTela) {
    return (alturaTela - qAltura) / 2 + deslocamentoVerticalQuadra;
  }

  double bolaX = 150;
  double bolaY = 250;

  String logAcao = "Toque na quadra para registrar";
  String zonaTextoAmigavel = "Aguardando toque...";

  // Complexo de Jogo atual (K0 a KV) — ver models/complexo_jogo.dart.
  // "onda" conta quantas vezes a bola já trocou de lado dentro do rally
  // atual: onda 1 = KI, onda 2 = KII, onda 3+ = KIII.
  String complexoAtual = ComplexoJogo.k0;
  int _ondaDoRally = 0;
  bool marcarProximaComoKV = false;

  // Fundamento técnico (S/R/E/A/B/D) selecionado no menu de avaliação —
  // o app sugere um (ver _fundamentoSugerido), mas o scout pode trocar
  // pelos chips a qualquer momento.
  Fundamento fundamentoSelecionadoMenu = Fundamento.recepcao;

  // Guardam o código (fundamento+símbolo) da avaliação em andamento
  // enquanto aguardamos o clique de "onde a bola caiu" (PONTO/ERRO).
  String _fundamentoPendente = "A";
  String _simboloPendente = "-";

  final PartidaRepository _repositorioPartidas = PartidaRepository();
  final PartidaEmAndamentoRepository _repositorioEmAndamento = PartidaEmAndamentoRepository();
  final List<Jogada> _jogadas = [];

  // Escalação em quadra de CADA time: índice 0 = posição 1 (saque), ...,
  // índice 5 = posição 6. Cada uma gira no sentido horário, de forma
  // independente, sempre que o respectivo time recupera o saque
  // (side-out a favor dele) durante o set. Definidas no initState (a
  // partir dos titulares OU de um estado salvo, se estivermos
  // retomando um jogo).
  late List<Jogador> posicoesNossoTime;
  late List<Jogador> bancoNosso;
  late List<Jogador> posicoesAdversario;
  late List<Jogador> bancoAdversario;

  /// Posições 5 (fundo-esquerda) e 6 (fundo-centro) são linha de fundo
  /// mas NÃO são a posição de saque (posição 1) — é onde o líbero entra
  /// automaticamente no lugar do central, se configurado.
  static const List<int> _indicesFundoSemSaque = [4, 5];

  /// Escalação "efetiva" do nosso time, já considerando a troca
  /// automática pelo líbero: sempre que o central estiver na linha de
  /// fundo (posição 5 ou 6 — nunca na posição 1, de saque), aparece o
  /// líbero no lugar dele. A rotação em si (posicoesNossoTime) continua
  /// girando normalmente com o central de verdade.
  List<Jogador> get posicoesNossoTimeComLibero =>
      _aplicarLibero(posicoesNossoTime, widget.liberoNosso);

  List<Jogador> get posicoesAdversarioComLibero =>
      _aplicarLibero(posicoesAdversario, widget.liberoAdversario);

  List<Jogador> _aplicarLibero(List<Jogador> posicoes, Jogador? libero) {
    if (libero == null) return posicoes;
    return [
      for (int i = 0; i < posicoes.length; i++)
        if (_indicesFundoSemSaque.contains(i) && posicoes[i].posicao == PosicaoJogador.central)
          libero
        else
          posicoes[i],
    ];
  }

  // Regras da partida: melhor de 3 a 5 sets, cada set até 25 pontos com
  // 2 de diferença — exceto o 5º set (decisivo), que vai até 15.
  int numeroSetAtual = 1;
  int setsVencidosNos = 0;
  int setsVencidosAdversario = 0;
  final List<SetResultado> setsFinalizados = [];

  int get _pontosParaVencerSet => numeroSetAtual == 5 ? 15 : 25;

  // Pilha de estados salvos antes de cada ponto/erro aplicado, pra dar
  // pra desfazer caso a arbitragem reverta a decisão. Guarda no máximo
  // os últimos 20 pontos.
  final List<_EstadoParaDesfazer> _pilhaDesfazer = [];

  void _salvarSnapshotParaDesfazer() {
    _pilhaDesfazer.add(_EstadoParaDesfazer(
      placarNossaEquipe: placarNossaEquipe,
      placarAdversario: placarAdversario,
      ladoComPosse: ladoComPosse,
      contadorToques: contadorToques,
      aguardandoSaqueCruzar: aguardandoSaqueCruzar,
      complexoAtual: complexoAtual,
      ondaDoRally: _ondaDoRally,
      numeroSetAtual: numeroSetAtual,
      setsVencidosNos: setsVencidosNos,
      setsVencidosAdversario: setsVencidosAdversario,
      setsFinalizados: List.of(setsFinalizados),
      posicoesNossoTime: List.of(posicoesNossoTime),
      posicoesAdversario: List.of(posicoesAdversario),
      bancoNosso: List.of(bancoNosso),
      bancoAdversario: List.of(bancoAdversario),
      bolaX: bolaX,
      bolaY: bolaY,
      zonaTextoAmigavel: zonaTextoAmigavel,
      logAcao: logAcao,
      quantidadeJogadas: _jogadas.length,
    ));
    if (_pilhaDesfazer.length > 20) _pilhaDesfazer.removeAt(0);
  }

  Future<void> _confirmarDesfazerUltimoPonto() async {
    if (_pilhaDesfazer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nada pra desfazer ainda.")),
      );
      return;
    }
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Desfazer último ponto?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Volta o placar, a rotação e o rally pro estado de antes da última jogada com ponto/erro registrada. Use se a arbitragem reverter a decisão.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Desfazer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) _desfazerUltimoPonto();
  }

  void _desfazerUltimoPonto() {
    final estado = _pilhaDesfazer.removeLast();
    setState(() {
      placarNossaEquipe = estado.placarNossaEquipe;
      placarAdversario = estado.placarAdversario;
      ladoComPosse = estado.ladoComPosse;
      contadorToques = estado.contadorToques;
      aguardandoSaqueCruzar = estado.aguardandoSaqueCruzar;
      complexoAtual = estado.complexoAtual;
      _ondaDoRally = estado.ondaDoRally;
      numeroSetAtual = estado.numeroSetAtual;
      setsVencidosNos = estado.setsVencidosNos;
      setsVencidosAdversario = estado.setsVencidosAdversario;
      setsFinalizados
        ..clear()
        ..addAll(estado.setsFinalizados);
      posicoesNossoTime = List.of(estado.posicoesNossoTime);
      posicoesAdversario = List.of(estado.posicoesAdversario);
      bancoNosso = List.of(estado.bancoNosso);
      bancoAdversario = List.of(estado.bancoAdversario);
      bolaX = estado.bolaX;
      bolaY = estado.bolaY;
      zonaTextoAmigavel = estado.zonaTextoAmigavel;
      while (_jogadas.length > estado.quantidadeJogadas) {
        _jogadas.removeLast();
      }
      jogadorSelecionado = null;
      mostrandoMenuJogadores = false;
      mostrandoMenuQualidade = false;
      aguardandoCliqueDestino = false;
      acaoTemporaria = null;
      logAcao = "PONTO DESFEITO — ${estado.logAcao}";
    });
    _salvarProgresso();
  }

  @override
  void initState() {
    super.initState();

    final estado = widget.estadoSalvo;
    if (estado != null) {
      posicoesNossoTime = List.of(estado.posicoesNossoTimeAtual);
      bancoNosso = List.of(estado.bancoNossoAtual);
      posicoesAdversario = List.of(estado.posicoesAdversarioAtual);
      bancoAdversario = List.of(estado.bancoAdversarioAtual);
      placarNossaEquipe = estado.placarNossaEquipe;
      placarAdversario = estado.placarAdversario;
      ladoComPosse = estado.ladoComPosse;
      numeroSetAtual = estado.numeroSetAtual;
      setsVencidosNos = estado.setsVencidosNos;
      setsVencidosAdversario = estado.setsVencidosAdversario;
      setsFinalizados.addAll(estado.setsFinalizados);
      _jogadas.addAll(estado.jogadas);
      contadorToques = 0;
      aguardandoSaqueCruzar = true;
      complexoAtual = ComplexoJogo.k0;
      zonaTextoAmigavel = "Retomando partida — toque pra continuar";
      logAcao = "Partida retomada de onde parou";
      // Reposiciona a bola na zona de saque de quem tinha a posse.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _posicionarParaSaque(ladoComPosse));
      });
    } else {
      posicoesNossoTime = List.of(widget.titularesNossos);
      bancoNosso = List.of(widget.bancoNosso);
      posicoesAdversario = List.of(widget.titularesAdversario);
      bancoAdversario = List.of(widget.bancoAdversario);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _escolherSaqueInicial();
      });
    }
  }

  // Linha da rede (y absoluto na tela) — usada como referência única para
  // decidir de que lado da quadra uma jogada terminou.
  double _redeDaQuadraY(BuildContext context) {
    final double alturaTela = MediaQuery.of(context).size.height;
    final double qInicioY = _qInicioY(alturaTela);
    return qInicioY + (qAltura / 2);
  }

  /// Mapeia o número da "onda" (quantas vezes a bola já trocou de lado
  /// dentro do rally atual) pro Complexo de Jogo correspondente:
  /// onda 1 = KI (recepção/ataque), onda 2 = KII (contra-ataque),
  /// onda 3 em diante = KIII (transição prolongada).
  String _rotuloDaOnda(int onda) {
    if (onda <= 1) return ComplexoJogo.kI;
    if (onda == 2) return ComplexoJogo.kII;
    return ComplexoJogo.kIII;
  }

  /// Verifica se um toque realmente mudou a posse de bola para o outro
  /// time.
  ///
  /// Só conta como "passou pro outro lado" se a bola caiu DENTRO dos
  /// limites laterais da quadra do lado oposto. Se ela cruzou a linha da
  /// rede mas saiu fora da quadra (para o lado), um jogador do MESMO time
  /// ainda pode correr e salvar — nesse caso a posse continua sendo nossa,
  /// mesmo que o toque tenha acontecido "do outro lado da rede" em y.
  bool _mudouDeLado({
    required double yAntigo,
    required double xNovo,
    required double yNovo,
    required double qInicioX,
    required double redeDaQuadraY,
  }) {
    final double xRelativo = xNovo - qInicioX;
    final bool dentroDaQuadraX = xRelativo >= 0 && xRelativo <= qLargura;
    if (!dentroDaQuadraX) return false;

    final bool ladoAntigoSuperior = yAntigo < redeDaQuadraY;
    final bool ladoNovoSuperior = yNovo < redeDaQuadraY;
    return ladoAntigoSuperior != ladoNovoSuperior;
  }

  void _processarAvaliacao(OpcaoAvaliacao opcao) {
    setState(() {
      if (opcao.geraKV) {
        // Overpass / bola sem ataque: a PRÓXIMA jogada (do adversário,
        // que recebe essa bola de graça) já nasce marcada como KV.
        marcarProximaComoKV = true;
      }

      if (opcao.ehPonto || opcao.ehErro) {
        aguardandoCliqueDestino = true;
        acaoTemporaria = opcao.ehPonto ? "PONTO" : "ERRO";
        _fundamentoPendente = fundamentoSelecionadoMenu.sigla;
        _simboloPendente = opcao.simbolo;
        logAcao = "ONDE A BOLA CAIU? CLIQUE NA QUADRA";
      } else {
        final String codigo = "${fundamentoSelecionadoMenu.sigla}${opcao.simbolo}";
        _jogadas.add(Jogada(
          jogador: jogadorSelecionado,
          tipo: _tipoGenericoPara(opcao),
          zona: zonaTextoAmigavel,
          horario: DateTime.now(),
          complexo: complexoAtual,
          fundamento: fundamentoSelecionadoMenu.sigla,
          simbolo: opcao.simbolo,
          numeroSet: numeroSetAtual,
          jogadorEhNosso: _timeDoJogadorSelecionado,
        ));
        _timeDoJogadorSelecionado = null;
        logAcao = "[$complexoAtual] $codigo $jogadorSelecionado NA ${zonaTextoAmigavel.toUpperCase()}";

        if (fundamentoSelecionadoMenu == Fundamento.recepcao) {
          _registrarSaquePorRecepcao(opcao.simbolo);
        }

        if (fundamentoSelecionadoMenu == Fundamento.bloqueio) {
          // Toque de bloqueio não conta contra o limite de 3 toques do
          // time — a bola segue em jogo, mas a contagem reinicia pra
          // que a defesa/levantamento/ataque seguintes tenham os 3
          // toques completos.
          contadorToques = 0;
        }
      }
      mostrandoMenuJogadores = false;
      mostrandoMenuQualidade = false;
    });
  }

  /// Símbolo de saque derivado do que aconteceu na recepção — a mesma
  /// lógica do DataVolley: o saque é avaliado pelo efeito que causou.
  String _simboloSaquePorRecepcao(String simboloRecepcao) {
    switch (simboloRecepcao) {
      case "#": // recepção perfeita -> saque só de continuidade
        return "-";
      case "+": // recepção boa -> ainda tranquilo pra eles
        return "-";
      case "-": // recepção quebrada -> saque causou problema
        return "+";
      case "/": // overpass -> saque forçou um passe descontrolado
        return "+";
      case "=": // erro de recepção -> ace
        return "#";
      default:
        return "-";
    }
  }

  /// Registra a ação de saque (fundamento S) do sacador atual, com o
  /// símbolo derivado da recepção — sem aplicar placar (o ponto/erro já
  /// foi decidido pela própria jogada de recepção; isso é só o registro
  /// estatístico do saque em si).
  void _registrarSaquePorRecepcao(String simboloRecepcao) {
    if (_servidorAtual == null) return;
    final String simboloSaque = _simboloSaquePorRecepcao(simboloRecepcao);
    _jogadas.add(Jogada(
      jogador: _servidorAtual!.rotuloCompleto,
      tipo: simboloSaque == "#" || simboloSaque == "+" ? "POSITIVA" : "NEGATIVA",
      zona: "Zona de saque",
      horario: DateTime.now(),
      complexo: ComplexoJogo.k0,
      fundamento: Fundamento.saque.sigla,
      simbolo: simboloSaque,
      numeroSet: numeroSetAtual,
      jogadorEhNosso: _servidorEhNosso,
    ));
  }

  /// Mapeia o símbolo de avaliação pra uma categoria genérica
  /// (POSITIVA/NEGATIVA/NEUTRA), mantida pra compatibilidade com as
  /// telas de estatísticas e histórico que já existiam antes da
  /// codificação por fundamento.
  String _tipoGenericoPara(OpcaoAvaliacao opcao) {
    if (opcao.simbolo == "#" || opcao.simbolo == "+") return "POSITIVA";
    if (opcao.simbolo == "-") return "NEGATIVA";
    return "NEUTRA"; // "/" (overpass / bola sem ataque)
  }

  /// Fundamento sugerido a partir de onde estamos no rally e — quando
  /// já sabemos quem tocou — da posição dele em quadra. O scout sempre
  /// pode trocar pelos chips do menu (ex: virar recepção, ou marcar um
  /// ataque de segunda mesmo estando no toque 2).
  ///
  /// [jogador] e [posicoesDoTime] são opcionais: sem eles (ex: antes de
  /// escolher quem tocou) a sugestão ignora a linha do jogador.
  Fundamento _fundamentoSugerido({Jogador? jogador, List<Jogador>? posicoesDoTime}) {
    if (complexoAtual == ComplexoJogo.kIV) return Fundamento.levantamento;

    if (contadorToques == 1) {
      if (complexoAtual == ComplexoJogo.kI) return Fundamento.recepcao;

      // Fora do KI (bola vindo do adversário em transição): se quem
      // tocou está na linha de frente, o toque mais provável é um
      // BLOQUEIO; se está na linha de fundo, é uma DEFESA — jogador de
      // fundo não pode bloquear. De qualquer forma, o scout pode trocar
      // pra Recepção (ex: bola passou direto sem ninguém "defender" de
      // verdade, foi só recebida) ou qualquer outro fundamento no menu.
      if (jogador != null && posicoesDoTime != null) {
        final int indice = posicoesDoTime.indexWhere((j) => j.id == jogador.id);
        final bool linhaDeFrente = indice == 1 || indice == 2 || indice == 3; // P2, P3, P4
        if (linhaDeFrente) return Fundamento.bloqueio;
      }
      return Fundamento.defesa;
    }

    if (contadorToques == 2) return Fundamento.levantamento;
    return Fundamento.ataque;
  }

  /// Aplica o resultado de uma jogada ao placar.
  ///
  /// Prioridade pra decidir quem pontua:
  /// 1. Se sabemos de qual TIME é o jogador/ação (_timeDoJogadorSelecionado
  ///    != null — normalmente porque um jogador específico foi escolhido,
  ///    ou porque a ação rápida partiu do menu de um lado conhecido): um
  ///    PONTO daquele time é ponto pra ele; um ERRO daquele time é ponto
  ///    pro adversário. Essa é a fonte confiável, porque não depende de
  ///    geometria — evita o bug de "o time que errou ganha o ponto"
  ///    quando a bola cai do lado "errado" por acaso.
  /// 2. Só quando isso não está disponível (erros automáticos de saque
  ///    ou 4º toque, cujo autor já vem resolvido em [ladoSuperior] como
  ///    "nosso time errou?"), cai pra esse valor direto.
  void _aplicarResultado(String tipo, bool ladoSuperior, {String? zonaQueda}) {
    _salvarSnapshotParaDesfazer();

    final String codigo = "$_fundamentoPendente$_simboloPendente";
    final String quemDetalhe =
    jogadorSelecionado != null ? "$jogadorSelecionado " : "";
    final String zonaDetalhe = zonaQueda != null ? " na $zonaQueda" : "";
    final String prefixo = "[$complexoAtual] $codigo ";

    _jogadas.add(Jogada(
      jogador: jogadorSelecionado,
      tipo: tipo,
      zona: zonaQueda ?? zonaTextoAmigavel,
      horario: DateTime.now(),
      complexo: complexoAtual,
      fundamento: _fundamentoPendente,
      simbolo: _simboloPendente,
      numeroSet: numeroSetAtual,
      jogadorEhNosso: _timeDoJogadorSelecionado,
    ));

    if (_fundamentoPendente == Fundamento.recepcao.sigla) {
      // Erro de recepção fechado por aqui (R=) — o saque que causou
      // esse ace precisa ser registrado antes que o próximo saque
      // (chamado logo abaixo) troque quem é "o sacador atual".
      _registrarSaquePorRecepcao(_simboloPendente);
    }

    final bool timeConhecido = _timeDoJogadorSelecionado != null;
    final bool nossoPonto = timeConhecido
        ? (tipo == "PONTO" ? _timeDoJogadorSelecionado! : !_timeDoJogadorSelecionado!)
        : (tipo == "PONTO" ? ladoSuperior : !ladoSuperior);
    _timeDoJogadorSelecionado = null; // consumido — evita vazar pra próxima jogada

    if (nossoPonto) {
      placarNossaEquipe++;
    } else {
      placarAdversario++;
    }
    logAcao = "$prefixo$quemDetalhe$zonaDetalhe".trim();

    mostrandoMenuJogadores = false;
    mostrandoMenuQualidade = false;

    if (_setTerminou()) {
      _finalizarSet();
    } else {
      _posicionarParaSaque(nossoPonto ? "baixo" : "cima");
    }

    _salvarProgresso();
  }

  /// Salva uma foto do estado atual do jogo, pra dar pra fechar o app e
  /// continuar depois de onde parou ("Continuar Jogo" na tela inicial).
  /// Roda em segundo plano — não precisa travar a interface esperando.
  void _salvarProgresso() {
    _repositorioEmAndamento.salvar(PartidaEmAndamento(
      nomeNossaEquipe: widget.nomeNossaEquipe,
      bancoInicialNosso: List.of(widget.titularesNossos)..addAll(widget.bancoNosso),
      sistemaNosso: widget.sistemaNosso,
      liberoNosso: widget.liberoNosso,
      nomeAdversario: widget.nomeAdversario,
      bancoInicialAdversario: List.of(widget.titularesAdversario)..addAll(widget.bancoAdversario),
      sistemaAdversario: widget.sistemaAdversario,
      liberoAdversario: widget.liberoAdversario,
      placarNossaEquipe: placarNossaEquipe,
      placarAdversario: placarAdversario,
      ladoComPosse: ladoComPosse,
      numeroSetAtual: numeroSetAtual,
      setsVencidosNos: setsVencidosNos,
      setsVencidosAdversario: setsVencidosAdversario,
      setsFinalizados: List.of(setsFinalizados),
      jogadas: List.of(_jogadas),
      posicoesNossoTimeAtual: List.of(posicoesNossoTime),
      posicoesAdversarioAtual: List.of(posicoesAdversario),
      bancoNossoAtual: List.of(bancoNosso),
      bancoAdversarioAtual: List.of(bancoAdversario),
      salvoEm: DateTime.now(),
    ));
  }

  bool _setTerminou() {
    final int diferenca = (placarNossaEquipe - placarAdversario).abs();
    return (placarNossaEquipe >= _pontosParaVencerSet ||
        placarAdversario >= _pontosParaVencerSet) &&
        diferenca >= 2;
  }

  /// Fecha o set atual, atualiza o placar de sets e decide se a partida
  /// acabou (3 sets vencidos) ou se um novo set começa. O diálogo é
  /// mostrado só depois do frame atual, porque este método roda dentro
  /// de um setState.
  void _finalizarSet() {
    final SetResultado resultado = SetResultado(
      numeroSet: numeroSetAtual,
      placarNosso: placarNossaEquipe,
      placarAdversario: placarAdversario,
    );
    setsFinalizados.add(resultado);

    if (resultado.vencemos) {
      setsVencidosNos++;
    } else {
      setsVencidosAdversario++;
    }

    final bool partidaAcabou = setsVencidosNos == 3 || setsVencidosAdversario == 3;

    mostrandoMenuJogadores = false;
    mostrandoMenuQualidade = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (partidaAcabou) {
        _mostrarFimDePartida();
      } else {
        _mostrarFimDeSet(resultado);
      }
    });
  }

  Future<void> _mostrarFimDeSet(SetResultado resultado) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "FIM DO SET ${resultado.numeroSet}",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${resultado.placarNosso} x ${resultado.placarAdversario}\n\nSets: $setsVencidosNos x $setsVencidosAdversario",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                numeroSetAtual++;
                placarNossaEquipe = 0;
                placarAdversario = 0;
                contadorToques = 0;
                zonaTextoAmigavel = "Aguardando toque...";
                logAcao = "Novo set! Escolha quem saca.";
              });
              _escolherSaqueInicial();
            },
            child: const Text("Próximo set", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFimDePartida() async {
    final bool vencemosPartida = setsVencidosNos > setsVencidosAdversario;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          vencemosPartida ? "VITÓRIA!" : "DERROTA",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: vencemosPartida ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sets: $setsVencidosNos x $setsVencidosAdversario",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final s in setsFinalizados)
              Text(
                "Set ${s.numeroSet}: ${s.placarNosso} x ${s.placarAdversario}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            onPressed: () async {
              await _salvarPartida();
              await _repositorioEmAndamento.limpar();
              if (mounted) {
                Navigator.pop(context); // fecha o diálogo
                Navigator.pop(context); // volta pro dashboard
              }
            },
            child: const Text("Salvar e sair", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _registrarAcaoRapida(String tipo) {
    setState(() {
      final double redeDaQuadraY = _redeDaQuadraY(context);

      // Se isso é literalmente o primeiro toque do rally (ninguém tocou
      // de verdade — a bola só cruzou e alguém já bateu PONTO/ERRO
      // direto), a ação é do SACADOR: ace (S#) ou falta de saque (S=),
      // não um "ataque" genérico.
      final bool ehPrimeiroToqueDoRally = contadorToques == 1 && _ondaDoRally == 1;

      if (ehPrimeiroToqueDoRally) {
        jogadorSelecionado = _servidorAtual?.rotuloCompleto;
        _timeDoJogadorSelecionado = _servidorEhNosso;
        _fundamentoPendente = Fundamento.saque.sigla;
        _simboloPendente = tipo == "PONTO" ? "#" : "=";
      } else {
        // Diferente de quando um JOGADOR é escolhido: aqui não sabemos
        // quem fez a ação, só onde a bola está. "PONTO"/"ERRO" rápidos
        // representam o resultado da bola em si (ex: caiu do lado
        // adversário = nosso ataque venceu), não "o time de quem tocou
        // por último sempre pontua" — por isso usa a geometria da
        // quadra, igual ao clique manual de destino.
        jogadorSelecionado = null;
        _timeDoJogadorSelecionado = null;
        _fundamentoPendente = Fundamento.ataque.sigla;
        _simboloPendente = tipo == "PONTO" ? "#" : "=";
      }

      _aplicarResultado(tipo, bolaY < redeDaQuadraY);
    });
  }

  void _escolherSaqueInicial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final double larguraTela = MediaQuery.of(context).size.width;
        final double alturaTela = MediaQuery.of(context).size.height;

        double centroX = larguraTela / 2;
        double inicioQuadraY = _qInicioY(alturaTela);
        double fimQuadraY = inicioQuadraY + qAltura;

        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("INÍCIO DA PARTIDA",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("Qual equipe começa sacando?",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                setState(() {
                  ladoComPosse = "baixo";
                  bolaX = centroX;
                  bolaY = fimQuadraY + 45;
                  contadorToques = 0;
                  logAcao = "PARTIDA INICIADA: NOSSO SAQUE";
                  zonaTextoAmigavel = "ZONA DE SAQUE";
                });
                Navigator.pop(context);
              },
              child: Text(widget.nomeNossaEquipe.toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                setState(() {
                  ladoComPosse = "cima";
                  bolaX = centroX;
                  bolaY = inicioQuadraY - 45;
                  contadorToques = 0;
                  logAcao = "PARTIDA INICIADA: SAQUE DELES";
                  zonaTextoAmigavel = "ZONA DE SAQUE";
                });
                Navigator.pop(context);
              },
              child: Text(widget.nomeAdversario.toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String identificarZonaVolei(double x, double y) {
    return VoleiUtils.identificarZona(x, y, qLargura, qAltura);
  }

  void _finalizarJogadaComDestino(double xDestino, double yDestino) {
    setState(() {
      final double qInicioX = (MediaQuery.of(context).size.width - qLargura) / 2;
      final double qInicioY = _qInicioY(MediaQuery.of(context).size.height);
      final double redeDaQuadraY = _redeDaQuadraY(context);

      final String zonaQueda = identificarZonaVolei(xDestino - qInicioX, yDestino - qInicioY);

      // Antes: comparava a posição ANTIGA da bola com o centro da tela.
      // Correto: usar o ponto onde a bola realmente caiu (destino) e a
      // linha da rede, igual ao que a ação rápida já fazia.
      _aplicarResultado(acaoTemporaria!, yDestino < redeDaQuadraY, zonaQueda: zonaQueda);

      aguardandoCliqueDestino = false;
      acaoTemporaria = null;
    });
  }

  /// Registra um erro decidido automaticamente pelo app (falta de saque
  /// ou 4º toque na mesma jogada) — [nossoTimeErrou] diz quem realmente
  /// cometeu o erro, então o ponto vai sempre pro time contrário.
  /// [fundamento] identifica tecnicamente que tipo de erro foi esse
  /// (saque, no caso de falta de saque; ataque, no caso de 4º toque).
  void _registrarErroAutomatico({required bool nossoTimeErrou, required Fundamento fundamento}) {
    setState(() {
      if (fundamento == Fundamento.saque) {
        // Falta de saque tem autor conhecido: quem está na posição 1 do
        // time que estava sacando.
        jogadorSelecionado = _servidorAtual?.rotuloCompleto;
        _timeDoJogadorSelecionado = _servidorEhNosso;
      } else {
        jogadorSelecionado = null;
        _timeDoJogadorSelecionado = null; // aqui quem errou já vem em nossoTimeErrou
      }
      _fundamentoPendente = fundamento.sigla;
      _simboloPendente = "=";
      _aplicarResultado("ERRO", nossoTimeErrou);
      contadorToques = 0;
    });
  }

  void _posicionarParaSaque(String timeComPosse) {
    final double larguraTela = MediaQuery.of(context).size.width;
    final double alturaTela = MediaQuery.of(context).size.height;

    double centroX = larguraTela / 2;
    double inicioQuadraY = _qInicioY(alturaTela);
    double fimQuadraY = inicioQuadraY + qAltura;

    // Não usa setState aqui: este método sempre é chamado de dentro de
    // outro setState (_aplicarResultado / diálogo inicial), então um
    // segundo setState aninhado seria redundante.
    contadorToques = 0;
    bolaX = centroX;

    // Regra de rotação: cada time gira a própria escalação (sentido
    // horário) sempre que RECUPERA o saque (side-out a favor dele) — só
    // isso, não quando ele mesmo continua sacando após pontuar de novo.
    if (timeComPosse == "baixo" && ladoComPosse != "baixo") {
      _rotacionar(posicoesNossoTime);
    } else if (timeComPosse == "cima" && ladoComPosse != "cima") {
      _rotacionar(posicoesAdversario);
    }

    if (timeComPosse == "baixo") {
      bolaY = fimQuadraY + 45;
      ladoComPosse = "baixo";
    } else {
      bolaY = inicioQuadraY - 45;
      ladoComPosse = "cima";
    }

    zonaTextoAmigavel = "PREPARANDO SAQUE";
    mostrandoMenuJogadores = false;
    mostrandoMenuQualidade = false;
    complexoAtual = ComplexoJogo.k0;
    _ondaDoRally = 0;
    aguardandoSaqueCruzar = true;

    // Quem está na posição 1 do time que vai sacar é o sacador — pega
    // isso DEPOIS da rotação acima, já que ela pode ter acabado de trocar
    // quem ocupa a posição 1.
    final List<Jogador> escalacaoQueVaiSacar =
    timeComPosse == "baixo" ? posicoesNossoTime : posicoesAdversario;
    _servidorAtual = escalacaoQueVaiSacar.isNotEmpty ? escalacaoQueVaiSacar[0] : null;
    _servidorEhNosso = timeComPosse == "baixo";

    logAcao =
    "[${ComplexoJogo.k0}] SAQUE: ${_servidorAtual?.rotuloCompleto ?? (timeComPosse == 'baixo' ? widget.nomeNossaEquipe.toUpperCase() : widget.nomeAdversario.toUpperCase())}";
  }

  /// Gira uma escalação no sentido horário: quem estava na posição 1
  /// (saque) vai para a posição 6, e todos os outros avançam uma posição.
  void _rotacionar(List<Jogador> posicoes) {
    if (posicoes.length != 6) return;
    final Jogador queSaiuDoSaque = posicoes.removeAt(0);
    posicoes.add(queSaiuDoSaque);
  }

  Future<Jogador?> _escolherDoBanco(List<Jogador> banco) {
    return showDialog<Jogador>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Quem entra?", style: TextStyle(color: Colors.white)),
        children: banco.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text("Banco vazio.", style: TextStyle(color: Colors.white70)),
          ),
        ]
            : banco
            .map((j) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, j),
          child: Text(j.rotuloCompleto, style: const TextStyle(color: Colors.white)),
        ))
            .toList(),
      ),
    );
  }

  void _substituir({
    required List<Jogador> posicoes,
    required List<Jogador> banco,
    required int indicePosicao,
    required Jogador queEntra,
    required bool ehNosso,
  }) {
    final Jogador queSai = posicoes[indicePosicao];
    setState(() {
      posicoes[indicePosicao] = queEntra;
      banco.remove(queEntra);
      banco.add(queSai);

      _jogadas.add(Jogada(
        jogador: "${queEntra.rotuloCompleto} ⇄ ${queSai.rotuloCompleto}",
        tipo: "SUBSTITUICAO",
        zona: "Posição ${indicePosicao + 1}",
        horario: DateTime.now(),
        numeroSet: numeroSetAtual,
        jogadorEhNosso: ehNosso,
      ));

      logAcao = "SUBSTITUIÇÃO: ${queEntra.nome} entra no lugar de ${queSai.nome}";
    });
    _salvarProgresso();
  }

  Widget _listaEscalacao({
    required String titulo,
    required List<Jogador> posicoes,
    required List<Jogador> banco,
    required Color corDestaque,
    required StateSetter setModalState,
    required bool ehNosso,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(color: corDestaque, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < posicoes.length; i++)
          ListTile(
            dense: true,
            leading: CircleAvatar(radius: 14, backgroundColor: corDestaque, child: Text("${i + 1}")),
            title: Text(posicoes[i].rotuloCompleto, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              posicoes[i].posicao.nomeCompleto,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: IconButton(
              icon: Icon(Icons.swap_horiz, color: banco.isEmpty ? Colors.white24 : Colors.yellow),
              onPressed: banco.isEmpty
                  ? null
                  : () async {
                final Jogador? escolhido = await _escolherDoBanco(banco);
                if (escolhido != null) {
                  _substituir(
                    posicoes: posicoes,
                    banco: banco,
                    indicePosicao: i,
                    queEntra: escolhido,
                    ehNosso: ehNosso,
                  );
                  setModalState(() {});
                }
              },
            ),
          ),
        const SizedBox(height: 6),
        Text(
          "Banco (${banco.length})",
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: banco
              .map((j) => Chip(
            label: Text(j.rotuloCompleto),
            backgroundColor: Colors.white10,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
          ))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _abrirEscalacao() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: Colors.yellow,
                      tabs: [
                        Tab(text: widget.nomeNossaEquipe.toUpperCase()),
                        Tab(text: widget.nomeAdversario.toUpperCase()),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _listaEscalacao(
                              titulo: "Sistema: ${widget.sistemaNosso.rotulo}",
                              posicoes: posicoesNossoTime,
                              banco: bancoNosso,
                              corDestaque: Colors.blueAccent,
                              setModalState: setModalState,
                              ehNosso: true,
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _listaEscalacao(
                              titulo: "Sistema: ${widget.sistemaAdversario.rotulo}",
                              posicoes: posicoesAdversario,
                              banco: bancoAdversario,
                              corDestaque: Colors.redAccent,
                              setModalState: setModalState,
                              ehNosso: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmarFinalizarPartida() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Finalizar partida?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Sets: $setsVencidosNos x $setsVencidosAdversario\nSet atual (não salvo se incompleto): $placarNossaEquipe x $placarAdversario\n\nIsso vai salvar a partida no histórico.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Salvar e sair", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _salvarPartida();
      await _repositorioEmAndamento.limpar();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _salvarPartida() async {
    final partida = Partida(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: DateTime.now(),
      nomeEquipe: widget.nomeNossaEquipe,
      nomeAdversario: widget.nomeAdversario,
      setsVencidosNos: setsVencidosNos,
      setsVencidosAdversario: setsVencidosAdversario,
      sets: List.unmodifiable(setsFinalizados),
      jogadas: List.unmodifiable(_jogadas),
    );
    await _repositorioPartidas.salvar(partida);
  }

  /// Calcula onde desenhar o número de uma posição de rotação (0=P1 ...
  /// 5=P6) na tela, seguindo o layout padrão de vôlei:
  ///
  ///   perto da rede:   P4 -- P3 -- P2
  ///   fundo da quadra: P5 -- P6 -- P1
  ///
  /// Isso é sempre relativo a QUEM está de costas pra rede olhando o
  /// próprio campo — por isso a coluna (esquerda/direita) é espelhada
  /// para o time de cima, que está de frente para o lado oposto.
  Offset _posicaoDaRotacao(
      int indicePosicao, {
        required bool nossaQuadra,
        required double qInicioX,
        required double redeDaQuadraY,
      }) {
    const List<Offset> fracoes = [
      Offset(0.833, 0.75), // P1: fundo-direita (posição de saque)
      Offset(0.833, 0.25), // P2: rede-direita
      Offset(0.5, 0.25), // P3: rede-centro
      Offset(0.167, 0.25), // P4: rede-esquerda
      Offset(0.167, 0.75), // P5: fundo-esquerda
      Offset(0.5, 0.75), // P6: fundo-centro
    ];
    final Offset fracao = fracoes[indicePosicao];
    final double alturaMeia = qAltura / 2;

    final double xFracao = nossaQuadra ? fracao.dx : 1 - fracao.dx;
    final double x = qInicioX + xFracao * qLargura;

    // Nosso lado fica abaixo da rede (y cresce), o adversário fica acima
    // (y decresce) — os dois medidos a partir da mesma linha de rede.
    final double y = nossaQuadra
        ? redeDaQuadraY + fracao.dy * alturaMeia
        : redeDaQuadraY - fracao.dy * alturaMeia;

    return Offset(x, y);
  }

  Widget _numeroDeRotacao(int numero, Offset posicao, Color cor) {
    return Positioned(
      left: posicao.dx - 16,
      top: posicao.dy - 16,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor.withOpacity(0.22),
          border: Border.all(color: cor.withOpacity(0.55), width: 1.5),
        ),
        child: Text(
          "$numero",
          style: TextStyle(color: cor.withOpacity(0.95), fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;
    final double alturaTela = MediaQuery.of(context).size.height;

    final double qInicioX = (larguraTela - qLargura) / 2;
    final double qInicioY = _qInicioY(alturaTela);
    final double redeDaQuadraY = qInicioY + (qAltura / 2);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // CAMADA 1: DETECTOR DE TOQUES (QUADRA)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (mostrandoMenuJogadores || mostrandoMenuQualidade) {
                setState(() {
                  mostrandoMenuJogadores = false;
                  mostrandoMenuQualidade = false;
                });
                return;
              }

              double x = details.localPosition.dx;
              double y = details.localPosition.dy;

              if (aguardandoCliqueDestino) {
                _finalizarJogadaComDestino(x, y);
                return;
              }

              setState(() {
                if (aguardandoSaqueCruzar) {
                  // Logo após o saque: aqui só interessa se a bola cruzou
                  // a rede (eixo Y) — não importa se o toque foi dado
                  // fora dos limites laterais da quadra, porque isso é
                  // exatamente como se marca um saque que saiu fora
                  // (o time que sacou erra o saque de qualquer jeito).
                  final bool cruzouARede = (bolaY < redeDaQuadraY) != (y < redeDaQuadraY);
                  if (!cruzouARede) {
                    // Saque não passou pra quadra adversária (rede, ou
                    // ficou do mesmo lado): falta de saque — o time que
                    // estava sacando é quem errou.
                    _registrarErroAutomatico(
                      nossoTimeErrou: ladoComPosse == "baixo",
                      fundamento: Fundamento.saque,
                    );
                    return;
                  }
                  aguardandoSaqueCruzar = false;
                  contadorToques = 1;
                  _ondaDoRally = 1;
                  complexoAtual = marcarProximaComoKV ? ComplexoJogo.kV : ComplexoJogo.kI;
                  marcarProximaComoKV = false;
                } else {
                  final bool mudouLado = _mudouDeLado(
                    yAntigo: bolaY,
                    xNovo: x,
                    yNovo: y,
                    qInicioX: qInicioX,
                    redeDaQuadraY: redeDaQuadraY,
                  );
                  if (mudouLado) {
                    _ondaDoRally++;
                    contadorToques = 1; // outro time começou a jogar
                    complexoAtual = marcarProximaComoKV ? ComplexoJogo.kV : _rotuloDaOnda(_ondaDoRally);
                    marcarProximaComoKV = false;
                  } else if (contadorToques == 3) {
                    // O 3º toque (ataque) voltou pro mesmo lado — foi
                    // bloqueado e a bola seguiu em jogo: cobertura de
                    // ataque (KIV). O toque de bloqueio não conta contra
                    // o limite de 3 toques do time, então a contagem
                    // reinicia para essa nova sequência.
                    complexoAtual = ComplexoJogo.kIV;
                    contadorToques = 1;
                  } else {
                    // Mesmo time manteve a posse — inclui o caso de a bola
                    // ter ido para fora da quadra e um jogador do mesmo
                    // time ter corrido para salvar, e o caso de um toque
                    // de bloqueio ter acabado de zerar a contagem.
                    contadorToques++;
                  }
                }

                if (contadorToques > 3) {
                  // 4º toque: quem vinha tocando (lado de bolaY) é quem
                  // errou — o outro time pontua.
                  _registrarErroAutomatico(
                    nossoTimeErrou: bolaY >= redeDaQuadraY,
                    fundamento: Fundamento.ataque,
                  );
                  return;
                }

                bolaX = x;
                bolaY = y;
                final String zona = identificarZonaVolei(x - qInicioX, y - qInicioY);
                zonaTextoAmigavel = y < redeDaQuadraY ? "$zona (ADVERSÁRIO)" : zona;
                mostrandoMenuJogadores = true;
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned(
                    left: qInicioX,
                    top: qInicioY,
                    child: ComponenteQuadraVisual(largura: qLargura, altura: qAltura),
                  ),
                ],
              ),
            ),
          ),

          // CAMADA 1.5: NÚMEROS DA ROTAÇÃO (semi-transparentes, sobre a quadra)
          IgnorePointer(
            child: Builder(
              builder: (context) {
                final nossosNaQuadra = posicoesNossoTimeComLibero;
                final adversarioNaQuadra = posicoesAdversarioComLibero;
                return Stack(
                  children: [
                    for (int i = 0; i < nossosNaQuadra.length; i++)
                      _numeroDeRotacao(
                        nossosNaQuadra[i].numero,
                        _posicaoDaRotacao(
                          i,
                          nossaQuadra: true,
                          qInicioX: qInicioX,
                          redeDaQuadraY: redeDaQuadraY,
                        ),
                        Colors.blueAccent,
                      ),
                    for (int i = 0; i < adversarioNaQuadra.length; i++)
                      _numeroDeRotacao(
                        adversarioNaQuadra[i].numero,
                        _posicaoDaRotacao(
                          i,
                          nossaQuadra: false,
                          qInicioX: qInicioX,
                          redeDaQuadraY: redeDaQuadraY,
                        ),
                        Colors.redAccent,
                      ),
                  ],
                );
              },
            ),
          ),

          // CAMADA 2: BOLA
          Positioned(
            left: bolaX - 20,
            top: bolaY - 20,
            child: const IgnorePointer(
              child: ComponenteBolaVisual(),
            ),
          ),

          // CAMADA 2.5: PLACAR (agora sozinho lá em cima, sem disputa de espaço)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: HeaderPlacar(
                placarNossaEquipe: placarNossaEquipe,
                placarAdversario: placarAdversario,
                zonaTexto: zonaTextoAmigavel,
                numeroSet: numeroSetAtual,
                setsNossos: setsVencidosNos,
                setsAdversario: setsVencidosAdversario,
                ladoComPosse: ladoComPosse,
                logAcao: logAcao,
              ),
            ),
          ),

          // CAMADA 2.6: BOTÕES DE AÇÃO (desfazer, KV, escalação/substituição,
          // salvar) — agora numa faixa lá embaixo.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                color: Colors.black.withOpacity(0.55),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.undo,
                        color: _pilhaDesfazer.isEmpty ? Colors.white24 : Colors.orangeAccent,
                      ),
                      tooltip: "Desfazer último ponto (arbitragem reverteu)",
                      onPressed: _pilhaDesfazer.isEmpty ? null : _confirmarDesfazerUltimoPonto,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.card_giftcard,
                        color: marcarProximaComoKV ? Colors.yellow : Colors.white70,
                      ),
                      tooltip: marcarProximaComoKV
                          ? "Marcando próxima jogada como KV (toque pra desmarcar)"
                          : "Marcar próxima jogada como KV (bola de graça/down ball)",
                      onPressed: () {
                        setState(() => marcarProximaComoKV = !marcarProximaComoKV);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.groups, color: Colors.white70),
                      tooltip: "Escalação e substituições",
                      onPressed: _abrirEscalacao,
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white70),
                      tooltip: "Finalizar e salvar partida",
                      onPressed: _confirmarFinalizarPartida,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CAMADA 5: MENU RADIAL DE JOGADORES
          if (mostrandoMenuJogadores)
            Positioned(
              left: (bolaX - 125).clamp(0.0, larguraTela - 250),
              top: (bolaY - 125).clamp(0.0, alturaTela - 250),
              child: SizedBox(
                width: 250,
                height: 250,
                child: Builder(
                  builder: (context) {
                    // bolaY já foi atualizada pra posição do último toque:
                    // usamos o roster do time daquele lado da quadra —
                    // nosso time embaixo, adversário em cima.
                    final bool tocouNaNossaQuadra = bolaY >= redeDaQuadraY;
                    final List<Jogador> rosterDoLado =
                    tocouNaNossaQuadra ? posicoesNossoTimeComLibero : posicoesAdversarioComLibero;

                    return MenuRadialJogadores(
                      jogadores: rosterDoLado.map((j) => j.rotuloCurto).toList(),
                      onSelecionado: (rotuloCurto) {
                        setState(() {
                          final jogador = rosterDoLado.firstWhere(
                                (j) => j.rotuloCurto == rotuloCurto,
                            orElse: () => rosterDoLado.first,
                          );
                          jogadorSelecionado = jogador.rotuloCompleto;
                          _timeDoJogadorSelecionado = tocouNaNossaQuadra;
                          fundamentoSelecionadoMenu = _fundamentoSugerido(
                            jogador: jogador,
                            posicoesDoTime: rosterDoLado,
                          );
                          mostrandoMenuJogadores = false;
                          mostrandoMenuQualidade = true;
                        });
                      },
                      onPontoDireto: () => _registrarAcaoRapida("PONTO"),
                      onErroDireto: () => _registrarAcaoRapida("ERRO"),
                    );
                  },
                ),
              ),
            ),

          // CAMADA 6: MENU DE AVALIAÇÃO POR FUNDAMENTO (S/R/E/A/B/D)
          if (mostrandoMenuQualidade)
            Positioned(
              left: (bolaX - 130).clamp(0.0, larguraTela - 260),
              top: (bolaY - 130).clamp(0.0, alturaTela - 260),
              child: MenuAvaliacaoFundamento(
                fundamentosDisponiveis: const [
                  Fundamento.recepcao,
                  Fundamento.levantamento,
                  Fundamento.ataque,
                  Fundamento.bloqueio,
                  Fundamento.defesa,
                ],
                fundamentoSelecionado: fundamentoSelecionadoMenu,
                onTrocarFundamento: (f) {
                  setState(() => fundamentoSelecionadoMenu = f);
                },
                onAvaliado: _processarAvaliacao,
              ),
            ),
        ],
      ),
    );
  }
}

/// Foto do estado da partida antes de um ponto ser aplicado — guardada
/// pra dar pra desfazer se a arbitragem reverter a decisão.
class _EstadoParaDesfazer {
  final int placarNossaEquipe;
  final int placarAdversario;
  final String ladoComPosse;
  final int contadorToques;
  final bool aguardandoSaqueCruzar;
  final String complexoAtual;
  final int ondaDoRally;
  final int numeroSetAtual;
  final int setsVencidosNos;
  final int setsVencidosAdversario;
  final List<SetResultado> setsFinalizados;
  final List<Jogador> posicoesNossoTime;
  final List<Jogador> posicoesAdversario;
  final List<Jogador> bancoNosso;
  final List<Jogador> bancoAdversario;
  final double bolaX;
  final double bolaY;
  final String zonaTextoAmigavel;
  final String logAcao;
  final int quantidadeJogadas;

  _EstadoParaDesfazer({
    required this.placarNossaEquipe,
    required this.placarAdversario,
    required this.ladoComPosse,
    required this.contadorToques,
    required this.aguardandoSaqueCruzar,
    required this.complexoAtual,
    required this.ondaDoRally,
    required this.numeroSetAtual,
    required this.setsVencidosNos,
    required this.setsVencidosAdversario,
    required this.setsFinalizados,
    required this.posicoesNossoTime,
    required this.posicoesAdversario,
    required this.bancoNosso,
    required this.bancoAdversario,
    required this.bolaX,
    required this.bolaY,
    required this.zonaTextoAmigavel,
    required this.logAcao,
    required this.quantidadeJogadas,
  });
}