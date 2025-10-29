enum CommandType { andar, girar }

class TrajectoryCommand {
  final CommandType type;
  final int? value;

  TrajectoryCommand({required this.type, this.value});

  @override
  String toString() {
    switch (type) {
      case CommandType.andar:
        return 'ANDAR ${value ?? 0} CM'; // Usa 0 se valor for nulo por algum motivo
      case CommandType.girar:
        final direction = (value ?? 0) >= 0 ? 'DIREITA' : 'ESQUERDA';
        return 'GIRAR ${(value ?? 0).abs()} GRAUS $direction';
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last, // 'andar', 'girar'
    'value': value,
  };
}
