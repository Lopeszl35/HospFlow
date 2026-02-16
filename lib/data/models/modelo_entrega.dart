// 1. O ITEM INDIVIDUAL (O Prontuário)
class ItemEntrega {
  final int? id;
  final int? protocoloId; // Chave Estrangeira: Liga o item ao protocolo pai
  final String nomePaciente;
  final String prontuario;
  final String tipoDocumento;
  final String volume;
  final int comCapa;

  ItemEntrega({
    this.id,
    this.protocoloId,
    required this.nomePaciente,
    required this.prontuario,
    required this.tipoDocumento,
    this.volume = 'A',
    this.comCapa = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protocolo_id': protocoloId,
      'nomePaciente': nomePaciente,
      'prontuario': prontuario,
      'tipoDocumento': tipoDocumento,
      'volume': volume,
      'comCapa': comCapa,
    };
  }

  factory ItemEntrega.fromMap(Map<String, dynamic> map) {
    return ItemEntrega(
      id: map['id'],
      protocoloId: map['protocolo_id'],
      nomePaciente: map['nomePaciente'],
      prontuario: map['prontuario'],
      tipoDocumento: map['tipoDocumento'],
      volume: map['volume'] ?? "A",
      comCapa: map['comCapa'] ?? 1,
    );
  }
}

// 2. O PROTOCOLO (O Recibo da Entrega Inteira)
class Protocolo {
  final int? id;
  final String dataHora;
  final List<int>? assinaturaBytes;
  final String titulo;
  final int status;
  final List<ItemEntrega> itens;

  Protocolo({
    this.id,
    required this.dataHora,
    this.assinaturaBytes,
    this.titulo = "Remessa Geral",
    this.status = 0, // Começa como rascunho
    this.itens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dataHora': dataHora,
      'assinaturaBytes': assinaturaBytes, // SQLite aceita null em BLOB
      'titulo': titulo,
      'status': status,
    };
  }

  factory Protocolo.fromMap(Map<String, dynamic> map) {
    return Protocolo(
      id: map['id'],
      dataHora: map['dataHora'],
      assinaturaBytes: map['assinaturaBytes'] != null
          ? List<int>.from(map['assinaturaBytes'])
          : null,
      titulo: map['titulo'] ?? "Remessa",
      status: map['status'] ?? 1, // Retrocompatibilidade assume assinado
    );
  }
}
