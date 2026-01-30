import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tela_lote.dart';
import 'database_helper.dart';
import 'modelo_entrega.dart';

// Se der erro no Intl, remova este import ou adicione 'intl: ^0.18.0' no pubspec.yaml
// Vou usar formatação manual para garantir que rode sem configurar nada extra.

void main() {
  runApp(const MeuAppHospitalar());
}

class MeuAppHospitalar extends StatelessWidget {
  const MeuAppHospitalar({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HospFlow',
      theme: ThemeData(
          primaryColor: const Color(0xFF0D47A1),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D47A1),
              foregroundColor: Colors.white)),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});
  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  List<Protocolo> _todosProtocolos = [];
  List<Protocolo> _protocolosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // VARIÁVEIS DE ESTADO DO DASHBOARD
  DateTime _mesSelecionado =
      DateTime.now(); // Data base para o filtro (Mês/Ano)

  // Métricas Detalhadas
  int _totalProntuarios = 0;
  int _totalAihInternacao = 0;
  int _totalAihParcial = 0;
  int _totalOutros = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    List<Protocolo> dados;
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      dados = [];
    } else {
      dados = await DatabaseHelper().getProtocolos();
    }

    // Calcula baseado no mês selecionado (inicialmente é Hoje)
    _calcularDashboard(dados, _mesSelecionado);

    setState(() {
      _todosProtocolos = dados;
      _protocolosFiltrados = dados;
      _isLoading = false;
    });
  }

  // --- NOVA FUNÇÃO: Escolher Mês ---
  Future<void> _selecionarMesFiltro() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _mesSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // Dica UX: Mostramos o picker normal, mas o usuário escolhe um dia qualquer
      // e nós consideramos o MÊS desse dia.
      helpText: "SELECIONE O MÊS DE REFERÊNCIA",
    );

    if (picked != null &&
        (picked.month != _mesSelecionado.month ||
            picked.year != _mesSelecionado.year)) {
      setState(() {
        _mesSelecionado = picked;
        // Recalcula os números para o novo mês escolhido
        _calcularDashboard(_todosProtocolos, _mesSelecionado);
      });
    }
  }

  void _calcularDashboard(List<Protocolo> lista, DateTime dataReferencia) {
    int pCount = 0;
    int aIntCount = 0;
    int aParcCount = 0;
    int outCount = 0;

    for (var proto in lista) {
      DateTime dataProto = DateTime.parse(proto.dataHora);

      // FILTRO DE DATA: Só conta se for do mesmo Mês e Ano da referência
      if (dataProto.month == dataReferencia.month &&
          dataProto.year == dataReferencia.year) {
        for (var item in proto.itens) {
          String tipo = item.tipoDocumento.toLowerCase();

          if (tipo.contains('alta')) {
            pCount++;
          } else if (tipo.contains('aih') && tipo.contains('internação')) {
            aIntCount++;
          } else if (tipo.contains('aih') && tipo.contains('parcial')) {
            aParcCount++;
          } else {
            outCount++;
          }
        }
      }
    }

    // Atualiza as variáveis que a tela usa para desenhar
    _totalProntuarios = pCount;
    _totalAihInternacao = aIntCount;
    _totalAihParcial = aParcCount;
    _totalOutros = outCount;
  }

  void _filtrarLista(String query) {
    if (query.isEmpty) {
      setState(() => _protocolosFiltrados = _todosProtocolos);
      return;
    }
    final minusculo = query.toLowerCase();
    setState(() {
      _protocolosFiltrados = _todosProtocolos.where((proto) {
        bool achouData = proto.dataHora.contains(query);
        bool achouItem = proto.itens.any((item) =>
            item.nomePaciente.toLowerCase().contains(minusculo) ||
            item.prontuario.contains(minusculo));
        return achouData || achouItem;
      }).toList();
    });
  }

  void _confirmarExclusao(int idProtocolo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Protocolo?"),
        content: const Text("Esta ação é irreversível."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!kIsWeb) await DatabaseHelper().excluirProtocolo(idProtocolo);
              _carregarDados();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Excluído."), backgroundColor: Colors.red));
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formatação manual do nome do mês (ex: 01/2026)
    String mesAnoStr =
        "${_mesSelecionado.month.toString().padLeft(2, '0')}/${_mesSelecionado.year}";

    return Scaffold(
      appBar: AppBar(title: const Text('HospFlow - Gestão'), elevation: 0),
      body: Column(
        children: [
          // --- HEADER: DASHBOARD COM FILTRO ---
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D47A1),
            child: Column(
              children: [
                // Linha do Filtro de Data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Resumo de Produção",
                        style: TextStyle(color: Colors.white70)),

                    // BOTÃO PARA TROCAR O MÊS
                    InkWell(
                      onTap: _selecionarMesFiltro,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(mesAnoStr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // CARDS DE MÉTRICAS (Agora em Grid 2x2 para caber tudo)
                Row(
                  children: [
                    _cardResumo("Prontuários (Alta)", _totalProntuarios,
                        Icons.folder_shared),
                    const SizedBox(width: 10),
                    _cardResumo("AIH Internação", _totalAihInternacao,
                        Icons.local_hospital),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _cardResumo("AIH Parcial", _totalAihParcial,
                        Icons.pie_chart), // Ícone de "fatia" para parcial
                    const SizedBox(width: 10),
                    _cardResumo("Outros Docs", _totalOutros, Icons.description),
                  ],
                ),
              ],
            ),
          ),

          // BARRA DE BUSCA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarLista,
              decoration: InputDecoration(
                hintText: 'Buscar na lista abaixo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LISTA DE RESULTADOS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _protocolosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey[300]),
                            const Text("Nenhum protocolo encontrado.")
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _protocolosFiltrados.length,
                        itemBuilder: (context, index) {
                          final proto = _protocolosFiltrados[index];
                          final dt = DateTime.parse(proto.dataHora);
                          final dataStr =
                              "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

                          return Card(
                            elevation: 2,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0D47A1),
                                child: Text("${proto.itens.length}",
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                              title: Text("Lote de $dataStr",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "#${proto.id} • ${proto.itens.length} itens"),
                              children: [
                                ...proto.itens.map((item) {
                                  return Container(
                                    color: Colors.grey[50],
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.description_outlined,
                                          size: 16),
                                      title: Text(item.nomePaciente),
                                      subtitle: Text(
                                          "${item.tipoDocumento} - Pront: ${item.prontuario}"),
                                    ),
                                  );
                                }).toList(),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Assinatura:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey)),
                                      const SizedBox(height: 10),
                                      Container(
                                        height:
                                            80, // Altura um pouco menor para economizar espaço
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300)),
                                        child: Image.memory(
                                          Uint8List.fromList(
                                              proto.assinaturaBytes),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: Colors.red.shade50,
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _confirmarExclusao(proto.id!),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 18),
                                    label: const Text("EXCLUIR",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TelaLote()))
              .then((_) => _carregarDados());
        },
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add_to_photos, color: Colors.white),
        label: const Text("NOVO LOTE", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _cardResumo(String titulo, int valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icone, color: Colors.white70, size: 24),
            const SizedBox(width: 8),
            Expanded(
              // Expanded aqui evita que texto grande quebre o layout
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(titulo,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
