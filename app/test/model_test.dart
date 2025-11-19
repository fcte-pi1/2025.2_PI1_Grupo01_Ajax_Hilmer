import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/trajectory_command.dart';

void main() {
  group('TrajectoryCommand Tests', () {
    test('ANDAR command', () {
      final command = TrajectoryCommand(type: CommandType.andar, value: 100);
      expect(command.toString(), 'ANDAR 100 CM');
    });

    test('GIRAR command for right turn', () {
      final command = TrajectoryCommand(type: CommandType.girar, value: 90);
      expect(command.toString(), 'GIRAR 90 GRAUS DIREITA');
    });

    test('GIRAR command for left turn', () {
      final command = TrajectoryCommand(type: CommandType.girar, value: -45);
      expect(command.toString(), 'GIRAR 45 GRAUS ESQUERDA');
    });

    test('toJson method', () {
      final command = TrajectoryCommand(type: CommandType.andar, value: 50);
      final json = command.toJson();
      expect(json['type'], 'andar');
      expect(json['value'], 50);
    });

    test('CommandType enum', () {
      expect(CommandType.values.length, 2);
      expect(CommandType.andar, isNotNull);
      expect(CommandType.girar, isNotNull);
    });

    test('Multiple commands sequence', () {
      final commands = [
        TrajectoryCommand(type: CommandType.andar, value: 100),
        TrajectoryCommand(type: CommandType.girar, value: 90),
        TrajectoryCommand(type: CommandType.andar, value: 50),
      ];

      expect(commands.length, 3);
      expect(commands[0].value, 100);
      expect(commands[1].type, CommandType.girar);
      expect(commands[2].toString(), 'ANDAR 50 CM');
    });

    test('Command sequence to string', () {
      final commands = [
        TrajectoryCommand(type: CommandType.andar, value: 100),
        TrajectoryCommand(type: CommandType.girar, value: -45),
      ];

      final sequence = commands.map((cmd) => cmd.toString()).join(', ');
      expect(sequence, 'ANDAR 100 CM, GIRAR 45 GRAUS ESQUERDA');
    });

    test('Edge cases', () {
      expect(TrajectoryCommand(type: CommandType.andar, value: 0).toString(), 'ANDAR 0 CM');
      expect(TrajectoryCommand(type: CommandType.girar, value: 0).toString(), 'GIRAR 0 GRAUS DIREITA');
      expect(TrajectoryCommand(type: CommandType.andar, value: null).toString(), 'ANDAR 0 CM');
    });
  });
}