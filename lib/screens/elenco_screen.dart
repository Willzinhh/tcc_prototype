import 'package:flutter/material.dart';

import '../core/utils/equipe_repository.dart';
import '../models/equipe.dart';
import '../models/jogador.dart';

const int _tamanhoMaximoElenco = 14;

class TelaElenco extends StatefulWidget {
  final String nomeInicial;
  final List<Jogador> elencoInicial;

  const TelaElenco({
    super.key,
    required this.nomeInicial,
    required this.elencoInicial,
  });

  @override
  State<TelaElenco> createState() => _TelaElencoState();
}

class _TelaElencoState extends State<TelaElenco> {
  final EquipeRepository _repositorio = EquipeRepository();
  late final TextEditingController _nomeController;
  late List<Jogador> _elenco;
  late Future<List<Equipe>> _futureEquipesSalvas;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial);
    _elenco = List.of(widget.elencoInicial);
    _futureEquipesSalvas = _repositorio.listar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _recarregarEquipesSalvas() {
    setState(() {
      _futureEquipesSalvas = _repositorio.listar();
    });
  }

  Future<void> _abrirFormularioJogador({Jogador? existente}) async {
    final nomeController = TextEditingController(text: existente?.nome ?? "");
    final numeroController =
    TextEditingController(text: existente?.numero.toString() ?? "");
    PosicaoJogador posicaoSelecionada = existente?.posicao ?? PosicaoJogador.ponteiro;

    final Jogador? resultado = await showDialog<Jogador>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existente == null ? "Novo Jogador" : "Editar Jogador"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome / sigla"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Número da camisa"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PosicaoJogador>(
                value: posicaoSelecionada,
                decoration: const InputDecoration(labelText: "Posição"),
                items: PosicaoJogador.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.nomeCompleto)))
                    .toList(),
                onChanged: (p) {
                  if (p != null) setDialogState(() => posicaoSelecionada = p);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final numero = int.tryParse(numeroController.text.trim());
                if (nome.isEmpty || numero == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preencha nome e número corretamente.")),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  Jogador(
                    id: existente?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    nome: nome,
                    numero: numero,
                    posicao: posicaoSelecionada,
                  ),
                );
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );

    if (resultado == null) return;

    setState(() {
      if (existente == null) {
        if (_elenco.length >= _tamanhoMaximoElenco) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("O elenco já tem 14 jogadores (máximo).")),
          );
          return;
        }
        _elenco.add(resultado);
      } else {
        final indice = _elenco.indexWhere((j) => j.id == existente.id);
        if (indice != -1) _elenco[indice] = resultado;
      }
    });
  }

  void _removerJogador(Jogador jogador) {
    setState(() {
      _elenco.removeWhere((j) => j.id == jogador.id);
    });
  }

  Future<void> _salvarElenco() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dê um nome para a equipe antes de salvar.")),
      );
      return;
    }
    final equipe = Equipe(
      id: nome.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
      nome: nome,
      elenco: _elenco,
    );
    await _repositorio.salvar(equipe);
    _recarregarEquipesSalvas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Elenco de $nome salvo para reutilizar depois.")),
      );
    }
  }

  Future<void> _carregarEquipeSalva(Equipe equipe) async {
    setState(() {
      _nomeController.text = equipe.nome;
      _elenco = List.of(equipe.elenco);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Elenco"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Salvar elenco para reutilizar",
            onPressed: _salvarElenco,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: "Nome da equipe",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Equipe>>(
                  future: _futureEquipesSalvas,
                  builder: (context, snapshot) {
                    final equipes = snapshot.data ?? [];
                    if (equipes.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: [
                        const Text("Carregar elenco salvo: ", style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: DropdownButton<Equipe>(
                            isExpanded: true,
                            hint: const Text("Selecionar...", style: TextStyle(fontSize: 12)),
                            items: equipes
                                .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text("${e.nome} (${e.elenco.length})"),
                            ))
                                .toList(),
                            onChanged: (e) {
                              if (e != null) _carregarEquipeSalva(e);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Jogadores (${_elenco.length}/$_tamanhoMaximoElenco)",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: _elenco.length >= _tamanhoMaximoElenco
                      ? null
                      : () => _abrirFormularioJogador(),
                  icon: const Icon(Icons.add),
                  label: const Text("Adicionar"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _elenco.isEmpty
                ? const Center(child: Text("Nenhum jogador ainda. Adicione até 14."))
                : ListView.builder(
              itemCount: _elenco.length,
              itemBuilder: (context, index) {
                final jogador = _elenco[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    child: Text(jogador.numero.toString()),
                  ),
                  title: Text(jogador.nome),
                  subtitle: Text(jogador.posicao.nomeCompleto),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _abrirFormularioJogador(existente: jogador),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _removerJogador(jogador),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, (_nomeController.text.trim(), _elenco)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "USAR ESTE ELENCO",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}