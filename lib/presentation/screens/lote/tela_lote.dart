import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/modelo_entrega.dart';
import '../assinatura/tela_assinatura.dart';

class TelaLote extends StatefulWidget {
  const TelaLote({super.key});

  @override
  State<TelaLote> createState() => _TelaLoteState();
}

class _TelaLoteState extends State<TelaLote> {
  // Controllers
  final _nomeController = TextEditingController();
  final _prontuarioController = TextEditingController();
  final _volumeController = TextEditingController(text: "A"); // Padrão "A"
  final _tituloLoteController = TextEditingController();

  // Estado
  String _tipoDocumento = 'Alta Hospitalar';
  bool _temCapa = true;
  DateTime _dataSelecionada = DateTime.now();
  final List<ItemEntrega> _itensDoLote = [];

  final List<String> _tiposDeDocumento = [
    'Alta Hospitalar',
    'AIH Internação',
    'AIH Parcial',
    'Nota de Débito',
    'Outros'
  ];

  // OCR
  final ImagePicker _picker = ImagePicker();
  bool _lendoImagem = false;

  // --- LÓGICA DE OCR ---
  Future<void> _escanearTexto() async {
    try {
      setState(() => _lendoImagem = true);
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final inputImage = InputImage.fromFilePath(photo.path);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        String provavelNome = "";
        String provavelProntuario = "";

        // Heurística Simples (Melhorar com Regex depois se precisar)
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String texto = line.text.trim();
            // Prontuário (Números > 3 dígitos)
            if (RegExp(r'^[0-9]+$').hasMatch(texto) && texto.length > 3) {
              provavelProntuario = texto;
            }
            // Nome (Texto longo sem números)
            else if (texto.length > 5 &&
                !texto.contains('/') &&
                !RegExp(r'[0-9]').hasMatch(texto)) {
              if (texto.length > provavelNome.length) provavelNome = texto;
            }
          }
        }

        if (provavelNome.isNotEmpty) _nomeController.text = provavelNome;
        if (provavelProntuario.isNotEmpty)
          _prontuarioController.text = provavelProntuario;

        textRecognizer.close();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Dados lidos!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _lendoImagem = false);
    }
  }

  // --- LÓGICA DE DATA ---
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  // --- ADICIONAR ITEM À LISTA ---
  void _adicionarItem() {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite o nome do paciente!')));
      return;
    }

    setState(() {
      _itensDoLote.add(ItemEntrega(
        nomePaciente: _nomeController.text,
        prontuario: _prontuarioController.text,
        tipoDocumento: _tipoDocumento,
        volume: _volumeController.text, // NOVO
        comCapa: _temCapa ? 1 : 0, // NOVO
      ));

      // Limpa campos para o próximo scan, mas mantém configurações úteis
      _nomeController.clear();
      _prontuarioController.clear();
      // Não limpa o tipo de documento, pois geralmente escaneia vários do mesmo tipo
      _volumeController.text = "A"; // Reseta volume para o padrão
      _temCapa = true; // Reseta capa
    });
  }

  void _removerItem(int index) {
    setState(() => _itensDoLote.removeAt(index));
  }

  // --- FINALIZAR (RASCUNHO OU ASSINATURA) ---
  void _mostrarOpcoesFinalizacao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalizar Lote"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Deseja salvar para entregar depois ou colher assinatura agora?"),
            const SizedBox(height: 16),
            TextField(
              controller: _tituloLoteController,
              decoration: const InputDecoration(
                labelText: "Nome do Lote (Opcional)",
                hintText: "Ex: Manhã UTI",
                border: OutlineInputBorder(),
              ),
            )
          ],
        ),
        actions: [
          // BOTÃO 1: SALVAR RASCUNHO (MANHÃ)
          TextButton(
            onPressed: () async {
              if (_itensDoLote.isEmpty) return;

              final novoProto = Protocolo(
                dataHora: _dataSelecionada.toIso8601String(),
                titulo: _tituloLoteController.text.isEmpty
                    ? "Lote ${_dataSelecionada.day}/${_dataSelecionada.month}"
                    : _tituloLoteController.text,
                status: 0, // 0 = Rascunho
                assinaturaBytes: null,
              );

              await DatabaseHelper()
                  .salvarProtocoloCompleto(novoProto, _itensDoLote);

              if (mounted) {
                Navigator.pop(ctx); // Fecha Dialog
                Navigator.pop(context); // Volta pra Home
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Rascunho salvo!"),
                    backgroundColor: Colors.orange));
              }
            },
            child: const Text("SALVAR RASCUNHO"),
          ),

          // BOTÃO 2: ASSINAR AGORA (TARDE)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaAssinatura(
                    itensDoLote: _itensDoLote,
                    dataEntrega: _dataSelecionada,
                    tituloLote: _tituloLoteController
                        .text, // Passar o título se tiver alterado a TelaAssinatura
                  ),
                ),
              );
            },
            child: const Text("ASSINAR AGORA"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dataFormatada =
        "${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lote de Entrega'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SELETOR DE DATA
          InkWell(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Text("Data: $dataFormatada",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1))),
                  const Spacer(),
                  const Text("Alterar", style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          ),

          // FORMULÁRIO DE CADASTRO
          Material(
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão OCR
                  ElevatedButton.icon(
                    onPressed: _lendoImagem ? null : _escanearTexto,
                    icon: _lendoImagem
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label:
                        Text(_lendoImagem ? "LENDO..." : "ESCANEAR DOCUMENTO"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Linha 1: Nome e Prontuário
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

                  // Linha 2: Tipo, Volume e Capa (NOVO)
                  Row(
                    children: [
                      // Tipo de Doc
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _tipoDocumento,
                          decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8)),
                          items: _tiposDeDocumento
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t,
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(() => _tipoDocumento = v!),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Volume (NOVO)
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _volumeController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                              labelText: 'Vol.',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 8)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Add
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(4)),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _adicionarItem,
                        ),
                      ),
                    ],
                  ),

                  // Linha 3: Checkbox Capa (NOVO)
                  Row(
                    children: [
                      Checkbox(
                        value: _temCapa,
                        onChanged: (v) => setState(() => _temCapa = v!),
                        activeColor: const Color(0xFF0D47A1),
                      ),
                      const Text("Com Capa?"),
                    ],
                  )
                ],
              ),
            ),
          ),

          // LISTA DE ITENS
          Expanded(
            child: _itensDoLote.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.format_list_bulleted,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Nenhum item adicionado.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _itensDoLote.length,
                    itemBuilder: (context, index) {
                      final item = _itensDoLote[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text("${index + 1}",
                                style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(item.nomePaciente,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          // SUBTITULO RICO COM AS NOVAS INFOS
                          subtitle: Text(
                              "${item.tipoDocumento} • Pront: ${item.prontuario}\nVol: ${item.volume} • ${item.comCapa == 1 ? 'C/ Capa' : 'S/ Capa'}"),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _removerItem(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // BOTÃO FLUTUANTE DE FINALIZAÇÃO
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))
        ]),
        child: ElevatedButton.icon(
          onPressed: _itensDoLote.isEmpty
              ? null
              : _mostrarOpcoesFinalizacao, // Abre o Dialog
          icon: const Icon(Icons.check_circle),
          label: Text("FINALIZAR LOTE (${_itensDoLote.length})"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
