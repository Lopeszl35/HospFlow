import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tela_lote.dart';
import 'database_helper.dart';
import 'modelo_entrega.dart';

void main() {
  runApp(const MeuAppHospitalar());
}

class MeuAppHospitalar extends StatelessWidget {
  const MeuAppHospitalar({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Protocolo de Entrega',
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
  // Lista Original (Tudo que veio do banco)
  List<Protocolo> _todosProtocolos = [];
  // Lista Filtrada (O que aparece na tela após busca)
  List<Protocolo> _protocolosFiltrados = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Variáveis do Dashboard
  int _totalProntuariosMes = 0;
  int _totalAihsMes = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Carrega do banco e atualiza a tela
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    List<Protocolo> dados;
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      dados = []; // Web vazio
    } else {
      dados = await DatabaseHelper().getProtocolos();
    }

    // Calcula estatísticas
    _calcularDashboard(dados);

    setState(() {
      _todosProtocolos = dados;
      _protocolosFiltrados = dados; // Começa mostrando tudo
      _isLoading = false;
    });
  }

  // Lógica de BI (Business Intelligence) Simples
  void _calcularDashboard(List<Protocolo> lista) {
    final agora = DateTime.now();
    int pCount = 0;
    int aCount = 0;

    for (var proto in lista) {
      // Converte string ISO para Data Real
      DateTime dataProto = DateTime.parse(proto.dataHora);

      // Só conta se for deste mês e ano
      if (dataProto.month == agora.month && dataProto.year == agora.year) {
        for (var item in proto.itens) {
          if (item.tipoDocumento.toLowerCase().contains('alta')) {
            pCount++;
          } else if (item.tipoDocumento.toLowerCase().contains('aih')) {
            aCount++;
          }
        }
      }
    }

    _totalProntuariosMes = pCount;
    _totalAihsMes = aCount;
  }

  // Lógica da Busca (A Lupa)
  void _filtrarLista(String query) {
    if (query.isEmpty) {
      setState(() => _protocolosFiltrados = _todosProtocolos);
      return;
    }

    final minusculo = query.toLowerCase();

    setState(() {
      _protocolosFiltrados = _todosProtocolos.where((proto) {
        // 1. Busca pela DATA (Ex: usuário digita "2023" ou "29")
        bool achouData = proto.dataHora.contains(query);

        // 2. Busca dentro dos ITENS (Nome paciente ou Prontuário)
        bool achouItem = proto.itens.any((item) =>
            item.nomePaciente.toLowerCase().contains(minusculo) ||
            item.prontuario.contains(minusculo));

        return achouData || achouItem;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard & Protocolos'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- HEADER: DASHBOARD (Resumo do Mês) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D47A1), // Fundo Azul contínuo do AppBar
            child: Column(
              children: [
                const Text("Resumo deste Mês",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _cardResumo("Prontuários", _totalProntuariosMes,
                        Icons.folder_shared),
                    const SizedBox(width: 10),
                    _cardResumo("AIH's", _totalAihsMes, Icons.description),
                  ],
                ),
              ],
            ),
          ),

          // --- BARRA DE BUSCA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarLista, // Chama filtro ao digitar
              decoration: InputDecoration(
                hintText: 'Buscar Paciente, Prontuário ou Data...',
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

          // --- LISTA DE RESULTADOS ---
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
                            const Text("Nada encontrado.")
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _protocolosFiltrados.length,
                        itemBuilder: (context, index) {
                          final proto = _protocolosFiltrados[index];
                          // Formata data para exibir
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
                                  "ID: #${proto.id} • ${proto.itens.length} Documentos"),
                              children: proto.itens.map((item) {
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
              .then((_) => _carregarDados()); // Recarrega dashboard ao voltar
        },
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add_to_photos, color: Colors.white),
        label: const Text("NOVO LOTE", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Widget auxiliar para os cartões do topo
  Widget _cardResumo(String titulo, int valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // Translúcido
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icone, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(titulo,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
