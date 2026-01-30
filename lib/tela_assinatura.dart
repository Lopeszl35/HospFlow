import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'database_helper.dart';
import 'modelo_entrega.dart';
import 'package:flutter/foundation.dart';

class TelaAssinatura extends StatefulWidget {
  final List<ItemEntrega> itensDoLote;
  // NOVA PROPRIEDADE
  final DateTime dataEntrega;

  const TelaAssinatura({
    super.key,
    required this.itensDoLote,
    required this.dataEntrega, // Obrigatório receber a data
  });

  @override
  State<TelaAssinatura> createState() => _TelaAssinaturaState();
}

class _TelaAssinaturaState extends State<TelaAssinatura> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formatação simples da data para mostrar na tela
    String dataStr =
        "${widget.dataEntrega.day}/${widget.dataEntrega.month}/${widget.dataEntrega.year}";

    return Scaffold(
      appBar: AppBar(
          title: const Text('Assinatura'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.yellow[100],
            width: double.infinity,
            child: Column(
              children: [
                Text(
                    "Confirmando entrega de ${widget.itensDoLote.length} documentos",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Data de Referência: $dataStr",
                    style: TextStyle(color: Colors.brown[800])),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), color: Colors.white),
              child: Signature(
                  controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => _controller.clear(),
                        child: const Text("LIMPAR"))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_controller.isEmpty) return;

                      try {
                        final signatureData = await _controller.toPngBytes();
                        if (signatureData != null) {
                          // USAMOS A DATA QUE VEIO DA TELA ANTERIOR
                          final novoProtocolo = Protocolo(
                            dataHora: widget.dataEntrega
                                .toIso8601String(), // <--- AQUI
                            assinaturaBytes: signatureData,
                          );

                          if (kIsWeb) {
                            print("WEB: Salvando...");
                            await Future.delayed(const Duration(seconds: 1));
                          } else {
                            await DatabaseHelper().salvarProtocoloCompleto(
                                novoProtocolo, widget.itensDoLote);
                          }

                          if (context.mounted) {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Salvo com sucesso!'),
                                    backgroundColor: Colors.green));
                          }
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white),
                    child: const Text("CONFIRMAR"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
