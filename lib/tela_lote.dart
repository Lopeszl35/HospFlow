import 'package:flutter/material.dart';
import 'modelo_entrega.dart';
import 'tela_assinatura.dart';

// DICA: Se der erro no 'intl', adicione "intl: ^0.18.0" no pubspec.yaml
// Mas vou fazer uma formatação manual simples para evitar que você precise mexer no pubspec agora.

class TelaLote extends StatefulWidget {
  const TelaLote({super.key});

  @override
  State<TelaLote> createState() => _TelaLoteState();
}

class _TelaLoteState extends State<TelaLote> {
  final _nomeController = TextEditingController();
  final _prontuarioController = TextEditingController();
  String _tipoDocumento = 'Alta Hospitalar';

  // NOVA VARIÁVEL: A data do lote (começa com Hoje)
  DateTime _dataSelecionada = DateTime.now();

  final List<ItemEntrega> _itensDoLote = [];
  final List<String> _tiposDeDocumento = [
    'Alta Hospitalar',
    'AIH Internação',
    'AIH Parcial',
    'Outros'
  ];

  // Função para escolher a data
  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020), // Permite datas passadas
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D47A1)),
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida != null && dataEscolhida != _dataSelecionada) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  void _adicionarItem() {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Digite o nome!')));
      return;
    }
    setState(() {
      _itensDoLote.add(ItemEntrega(
        nomePaciente: _nomeController.text,
        prontuario: _prontuarioController.text,
        tipoDocumento: _tipoDocumento,
      ));
      _nomeController.clear();
      _prontuarioController.clear();
    });
  }

  void _removerItem(int index) {
    setState(() => _itensDoLote.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    // Formatação manual da data para PT-BR (para não depender de pacote extra agora)
    String dataFormatada =
        "${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lote'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- NOVO CABEÇALHO DE DATA ---
          InkWell(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Data da Entrega do Lote",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dataFormatada,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1))),
                    ],
                  ),
                  const Spacer(),
                  const Text("Alterar", style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // --- FORMULÁRIO ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: TextField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                                labelText: 'Nome',
                                border: OutlineInputBorder(),
                                isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 1,
                        child: TextField(
                            controller: _prontuarioController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Pront.',
                                border: OutlineInputBorder(),
                                isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                            isDense: true),
                        items: _tiposDeDocumento
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoDocumento = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _adicionarItem,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15)),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA ---
          Expanded(
            child: _itensDoLote.isEmpty
                ? const Center(
                    child: Text("Adicione itens ao lote.",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _itensDoLote.length,
                    itemBuilder: (context, index) {
                      final item = _itensDoLote[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text("${index + 1}")),
                          title: Text(item.nomePaciente,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "${item.tipoDocumento} • ${item.prontuario}"),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _removerItem(index)),
                        ),
                      );
                    },
                  ),
          ),

          // --- BOTÃO FINALIZAR ---
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _itensDoLote.isEmpty
                  ? null
                  : () {
                      // MUDANÇA: Passamos a data selecionada para a próxima tela
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TelaAssinatura(
                                itensDoLote: _itensDoLote,
                                dataEntrega: _dataSelecionada // <--- AQUI
                                )),
                      );
                    },
              icon: const Icon(Icons.check_circle),
              label: Text("COLETAR ASSINATURA (${_itensDoLote.length})"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}
