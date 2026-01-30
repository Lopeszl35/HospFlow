import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'modelo_entrega.dart';
import 'tela_assinatura.dart';

class TelaLote extends StatefulWidget {
  const TelaLote({super.key});

  @override
  State<TelaLote> createState() => _TelaLoteState();
}

class _TelaLoteState extends State<TelaLote> {
  final _nomeController = TextEditingController();
  final _prontuarioController = TextEditingController();
  String _tipoDocumento = 'Alta Hospitalar';

  DateTime _dataSelecionada = DateTime.now();
  final List<ItemEntrega> _itensDoLote = [];
  final List<String> _tiposDeDocumento = [
    'Alta Hospitalar',
    'AIH Internação',
    'AIH Parcial',
    'Outros'
  ];

  // Ferramentas de OCR
  final ImagePicker _picker = ImagePicker();
  bool _lendoImagem = false; // Para mostrar loading

  Future<void> _escanearTexto() async {
    try {
      setState(() => _lendoImagem = true);

      // 1. Tira a foto
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final inputImage = InputImage.fromFilePath(photo.path);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);

        // 2. Processa a imagem
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        String provavelNome = "";
        String provavelProntuario = "";

        // 3. Tenta adivinhar o que é o que (Heurística Simples)
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String texto = line.text.trim();

            // Lógica: Se for só número e tiver tamanho de prontuário (ex: > 3 digitos)
            if (RegExp(r'^[0-9]+$').hasMatch(texto) && texto.length > 3) {
              provavelProntuario = texto;
            }
            // Lógica: Se for texto, não for data, e for longo, provavelmente é nome
            else if (texto.length > 5 &&
                !texto.contains('/') &&
                !RegExp(r'[0-9]').hasMatch(texto)) {
              // Pega o maior texto encontrado como nome (geralmente nomes são longos)
              if (texto.length > provavelNome.length) {
                provavelNome = texto;
              }
            }
          }
        }

        // 4. Preenche os campos
        if (provavelNome.isNotEmpty) _nomeController.text = provavelNome;
        if (provavelProntuario.isNotEmpty)
          _prontuarioController.text = provavelProntuario;

        textRecognizer.close();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Leitura concluída! Verifique os dados."),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao ler: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _lendoImagem = false);
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (dataEscolhida != null) {
      setState(() => _dataSelecionada = dataEscolhida);
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
          // Cabeçalho de Data
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
                      const Text("Data da Entrega",
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

          // --- ÁREA DE CADASTRO COM OCR ---
          // CORREÇÃO: Usamos Material em vez de Container para ter 'elevation'
          Material(
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Botão de Scanner
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _lendoImagem ? null : _escanearTexto,
                      icon: _lendoImagem
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.camera_alt),
                      label: Text(_lendoImagem
                          ? "PROCESSANDO..."
                          : "ESCANEAR ETIQUETA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800], // Cor destaque
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

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
          ),

          Expanded(
            child: _itensDoLote.isEmpty
                ? const Center(
                    child: Text("Adicione itens manualmente ou via câmera.",
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

          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _itensDoLote.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TelaAssinatura(
                                itensDoLote: _itensDoLote,
                                dataEntrega: _dataSelecionada)),
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
