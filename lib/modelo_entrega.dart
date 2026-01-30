// modelo_entrega.dart

// 1. O ITEM INDIVIDUAL (O Prontuário)
class ItemEntrega {
  final int? id;
  final int? protocoloId; // Chave Estrangeira: Liga o item ao protocolo pai
  final String nomePaciente;
  final String prontuario;
  final String tipoDocumento;

  ItemEntrega({
    this.id,
    this.protocoloId,
    required this.nomePaciente,
    required this.prontuario,
    required this.tipoDocumento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protocolo_id': protocoloId,
      'nomePaciente': nomePaciente,
      'prontuario': prontuario,
      'tipoDocumento': tipoDocumento,
    };
  }

  factory ItemEntrega.fromMap(Map<String, dynamic> map) {
    return ItemEntrega(
      id: map['id'],
      protocoloId: map['protocolo_id'],
      nomePaciente: map['nomePaciente'],
      prontuario: map['prontuario'],
      tipoDocumento: map['tipoDocumento'],
    );
  }
}

// 2. O PROTOCOLO (O Recibo da Entrega Inteira)
class Protocolo {
  final int? id;
  final String dataHora;
  final List<int> assinaturaBytes;
  // A lista de itens não é salva na tabela 'protocolos', mas a usamos no app
  final List<ItemEntrega> itens;

  Protocolo({
    this.id,
    required this.dataHora,
    required this.assinaturaBytes,
    this.itens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dataHora': dataHora,
      'assinaturaBytes': assinaturaBytes,
    };
  }

  factory Protocolo.fromMap(Map<String, dynamic> map) {
    return Protocolo(
      id: map['id'],
      dataHora: map['dataHora'],
      // Converte BLOB para lista de bytes
      assinaturaBytes: List<int>.from(map['assinaturaBytes']),
    );
  }
}
