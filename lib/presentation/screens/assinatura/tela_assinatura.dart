import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/modelo_entrega.dart';

class TelaAssinatura extends StatefulWidget {
  final List<ItemEntrega> itensDoLote;
  final DateTime dataEntrega;
  final String? tituloLote;

  const TelaAssinatura({
    super.key,
    required this.itensDoLote,
    required this.dataEntrega,
    this.tituloLote,
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

  bool _salvando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvarAssinatura() async {
    if (_controller.isEmpty) return;

    setState(() => _salvando = true);

    try {
      final signatureData = await _controller.toPngBytes();

      if (signatureData != null) {
        final novoProtocolo = Protocolo(
          dataHora: widget.dataEntrega.toIso8601String(),
          assinaturaBytes: signatureData,
          titulo: widget.tituloLote ??
              "Lote ${widget.dataEntrega.day}/${widget.dataEntrega.month}",
          status: 1, // 1 = Entregue/Assinado
        );

        if (!kIsWeb) {
          await DatabaseHelper()
              .salvarProtocoloCompleto(novoProtocolo, widget.itensDoLote);
        }

        if (mounted) {
          // Volta tudo até a tela inicial (limpa a pilha)
          Navigator.popUntil(context, (route) => route.isFirst);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrega confirmada com sucesso!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dataStr =
        "${widget.dataEntrega.day.toString().padLeft(2, '0')}/${widget.dataEntrega.month.toString().padLeft(2, '0')}/${widget.dataEntrega.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletar Assinatura'),
        backgroundColor: AppTheme.primaryModern,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner de Informação
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: AppTheme.warning.withOpacity(0.1), // Fundo amarelado suave
            child: Column(
              children: [
                Text(
                  "Confirmando entrega de ${widget.itensDoLote.length} documentos",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Data de Referência: $dataStr",
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),

          // Área de Assinatura
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const Text("Assine no quadro acima",
              style: TextStyle(color: AppTheme.textLight)),

          // Botões de Ação
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Botão Limpar
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.clear(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.textGrey),
                      foregroundColor: AppTheme.textDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("LIMPAR"),
                  ),
                ),
                const SizedBox(width: 16),
                // Botão Confirmar
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvarAssinatura,
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label:
                        Text(_salvando ? "SALVANDO..." : "CONFIRMAR ENTREGA"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success, // Verde para sucesso
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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
