import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';

// IMPORTS DA ARQUITETURA
import '../../../data/local/database_helper.dart';
import '../../../data/models/modelo_entrega.dart';
import '../../../core/theme/app_theme.dart';

// NAVEGAÇÃO
import '../lote/tela_lote.dart';
import '../assinatura/tela_assinatura.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  // Estado
  List<Protocolo> _todosProtocolos = [];
  List<Protocolo> _protocolosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Dashboard
  DateTime _mesSelecionado = DateTime.now();
  int _totalProntuarios = 0;
  int _totalAihInternacao = 0;
  int _totalAihParcial = 0;
  int _totalOutros = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // --- LÓGICA DE DADOS ---

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    List<Protocolo> dados;
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      dados = [];
    } else {
      dados = await DatabaseHelper().getProtocolos();
    }

    _calcularDashboard(dados, _mesSelecionado);

    if (mounted) {
      setState(() {
        _todosProtocolos = dados;
        _protocolosFiltrados = dados;
        _isLoading = false;
        // Reaplica filtro de texto se houver
        if (_searchController.text.isNotEmpty) {
          _filtrarLista(_searchController.text);
        }
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

    _totalProntuarios = pCount;
    _totalAihInternacao = aIntCount;
    _totalAihParcial = aParcCount;
    _totalOutros = outCount;
  }

  // --- AÇÕES DO USUÁRIO ---

  Future<void> _selecionarMesFiltro() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _mesSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "SELECIONE O MÊS DE REFERÊNCIA",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryModern),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.month != _mesSelecionado.month ||
            picked.year != _mesSelecionado.year)) {
      setState(() {
        _mesSelecionado = picked;
        _calcularDashboard(_todosProtocolos, _mesSelecionado);
      });
    }
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
        bool achouTitulo = proto.titulo
            .toLowerCase()
            .contains(minusculo); // Busca por título tbm
        bool achouItem = proto.itens.any((item) =>
            item.nomePaciente.toLowerCase().contains(minusculo) ||
            item.prontuario.contains(minusculo));
        return achouData || achouItem || achouTitulo;
      }).toList();
    });
  }

  void _confirmarExclusao(int idProtocolo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Protocolo?"),
        content: const Text(
            "Esta ação é irreversível e apagará todos os itens vinculados."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!kIsWeb) await DatabaseHelper().excluirProtocolo(idProtocolo);
              _carregarDados();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Protocolo excluído."),
                    backgroundColor: AppTheme.error));
              }
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirAssinatura(Protocolo proto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaAssinatura(
          itensDoLote: proto.itens,
          dataEntrega: DateTime.parse(proto.dataHora),
          tituloLote: proto.titulo,
        ),
      ),
    ).then((_) => _carregarDados());
  }

  // --- WIDGETS ---

  @override
  Widget build(BuildContext context) {
    String mesAnoStr =
        "${_mesSelecionado.month.toString().padLeft(2, '0')}/${_mesSelecionado.year}";

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('HospFlow - Gestão'),
        elevation: 0,
        backgroundColor: AppTheme.primaryModern,
      ),
      body: Column(
        children: [
          // HEADER DASHBOARD
          _buildDashboardHeader(mesAnoStr),

          // BARRA DE BUSCA
          _buildSearchBar(),

          // LISTA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _protocolosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _protocolosFiltrados.length,
                        itemBuilder: (context, index) =>
                            _buildProtocoloCard(_protocolosFiltrados[index]),
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
        backgroundColor: AppTheme.primaryModern,
        icon: const Icon(Icons.add_to_photos, color: Colors.white),
        label: const Text("NOVO LOTE", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDashboardHeader(String mesAnoStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient, // Usando o gradiente do tema
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Resumo de Produção",
                  style: TextStyle(color: Colors.white70)),
              InkWell(
                onTap: _selecionarMesFiltro,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cards de Métricas
          Row(
            children: [
              _metricCard(
                  "Prontuários", _totalProntuarios, Icons.folder_shared),
              const SizedBox(width: 10),
              _metricCard(
                  "AIH Internação", _totalAihInternacao, Icons.local_hospital),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metricCard("AIH Parcial", _totalAihParcial, Icons.pie_chart),
              const SizedBox(width: 10),
              _metricCard("Outros", _totalOutros, Icons.description),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String titulo, int valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icone, color: Colors.white70, size: 24),
            const SizedBox(width: 12),
            Expanded(
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filtrarLista,
        decoration: InputDecoration(
          hintText: 'Buscar lote, paciente ou prontuário...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
          filled: true,
          fillColor: AppTheme.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Nenhum protocolo encontrado.",
              style: TextStyle(color: Colors.grey))
        ],
      ),
    );
  }

  Widget _buildProtocoloCard(Protocolo proto) {
    final dt = DateTime.parse(proto.dataHora);
    final dataStr =
        "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    final isRascunho = proto.status == 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isRascunho ? AppTheme.warning : AppTheme.success,
          child: Icon(isRascunho ? Icons.edit : Icons.check,
              color: Colors.white, size: 20),
        ),
        title: Text(
          proto.titulo.isNotEmpty ? proto.titulo : "Lote de Entrega",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        subtitle: Text(
          "$dataStr • ${proto.itens.length} itens",
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
        trailing: isRascunho
            ? IconButton(
                icon: const Icon(Icons.draw, color: AppTheme.primaryModern),
                tooltip: "Assinar Agora",
                onPressed: () => _abrirAssinatura(proto),
              )
            : null,
        children: [
          // Lista de Itens do Protocolo
          ...proto.itens.map((item) {
            return Container(
              color: AppTheme.background, // Cinza claro para diferenciar
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined,
                    size: 16, color: AppTheme.textGrey),
                title: Text(item.nomePaciente,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text("${item.tipoDocumento} - Pront: ${item.prontuario}"),
                trailing: Text(
                  "Vol: ${item.volume} ${item.comCapa == 1 ? '(Capa)' : ''}",
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ),
            );
          }).toList(),

          const Divider(height: 1),

          // Área de Assinatura (se existir)
          if (!isRascunho && proto.assinaturaBytes != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Assinatura do Recebedor:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textGrey,
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Image.memory(
                      Uint8List.fromList(proto.assinaturaBytes!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

          // Botão Excluir
          Container(
            color: Colors.red.withOpacity(0.05),
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmarExclusao(proto.id!),
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 18),
              label: const Text("EXCLUIR REGISTRO",
                  style: TextStyle(color: AppTheme.error)),
            ),
          ),
        ],
      ),
    );
  }
}
