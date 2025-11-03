import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/trajectory_command.dart';
import 'previous_routes_screen.dart';
import '../../services/ble_manager.dart';
import '../../services/api_service.dart';

// Recebe a instância do BleManager via construtor
class RouteEditorScreen extends StatefulWidget {
  final BleManager bleManager;

  const RouteEditorScreen({super.key, required this.bleManager});

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _angleController = TextEditingController();
  final List<TrajectoryCommand> _commands = [];
  bool _isSending = false; // Controla estado de envio/loading

  // Obtém a instância do BleManager passada pelo widget
  late final BleManager _bleManager;
  // Instância do ApiService (SUBSTITUIR PELA FORMA CORRETA DE OBTER INSTÂNCIA)
  final ApiService _apiService = ApiService(); // MODO INCORRETO (DEMO)

  @override
  void initState() {
    super.initState();
    _bleManager = widget.bleManager;
    _setupConnectionLostListener(); // Chama a função corrigida
  }

  void _setupConnectionLostListener() {
    // Apenas registra a função _handleConnectionLost como listener
    _bleManager.connectionState.removeListener(_handleConnectionLost);
    _bleManager.connectionState.addListener(_handleConnectionLost);
  }

  // Nova função _handleConnectionLost (contém a lógica)
  void _handleConnectionLost() {
    final state = _bleManager.connectionState.value;
    print("[RouteEditor] Listener: Estado mudou para $state");
    if (state == BluetoothConnectionState.disconnected && mounted) {
      print("[RouteEditor] Conexão perdida! Voltando...");
      // ScaffoldMessenger.of(context).showSnackBar(/* ... SnackBar ... */);
      Navigator.of(context).pop();
      _bleManager.connectionState.removeListener(_handleConnectionLost);
    }
  }

  @override
  void dispose() {
    _bleManager.connectionState.removeListener(_handleConnectionLost);
    _distanceController.dispose();
    _angleController.dispose();
    super.dispose();
  }

  void _addCommand(CommandType type) {
    if (_isSending) return;
    int? value;
    TextEditingController? controllerToClear;
    String? errorMessage;

    try {
      if (type == CommandType.andar) {
        value = int.tryParse(_distanceController.text);
        controllerToClear = _distanceController;
        if (value == null || value == 0)
          errorMessage = "Distância inválida (não pode ser zero ou vazio).";
      } else if (type == CommandType.girar) {
        value = int.tryParse(_angleController.text);
        controllerToClear = _angleController;
        if (value == null || value == 0)
          errorMessage = "Ângulo inválido (não pode ser zero ou vazio).";
      }

      if (errorMessage == null) {
        setState(() {
          _commands.add(TrajectoryCommand(type: type, value: value));
          controllerToClear?.clear();
        });
        FocusScope.of(context).unfocus(); // Esconde o teclado
      } else {
        _showFeedbackSnackBar(errorMessage, isError: true);
        controllerToClear?.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      _showFeedbackSnackBar("Erro ao adicionar comando.", isError: true);
      print("Erro _addCommand: $e");
    }
  }

  void _removeCommand(int index) {
    if (_isSending) return;
    setState(() {
      _commands.removeAt(index);
    });
  }

  Future<void> _startRoute() async {
    // 1. Validações iniciais (antes de mostrar o pop-up)
    if (_isSending) return; // Evita envio duplo
    if (_commands.isEmpty) {
      _showFeedbackSnackBar(
        "Adicione comandos ao percurso antes de iniciar.",
        isError: true,
      );
      return;
    }

    // 2. Mostra o Pop-up de Confirmação (AlertDialog)
    final bool? wantsToStart = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Permite fechar clicando fora
      builder: (BuildContext dialogContext) {
        // AlertDialog é o widget do pop-up
        return AlertDialog(
          // Estilização para bater com o Figma
          backgroundColor: const Color(0xFF191C23), // Fundo cinza escuro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: const Color(0xFF33DDFF), width: 1),
          ),
          title: const Text(
            'Deseja iniciar o percurso?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          // actions são os botões na parte inferior
          actionsAlignment:
              MainAxisAlignment.center, // Centraliza a Row de botões
          actionsPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 10,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centraliza os botões
              children: [
                // Botão "Sim" (Azul Ciano)
                SizedBox(
                  width: 120, // Largura fixa como no Figma
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF33DDFF), // Ciano
                      foregroundColor: const Color(0xFF0D0F14), // Texto escuro
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ), // Altura interna
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sim',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Fecha o pop-up e retorna 'true'
                      Navigator.of(dialogContext).pop(true);
                    },
                  ),
                ),
                const SizedBox(width: 15), // Espaço entre os botões
                // Botão "Não" (Outlined)
                SizedBox(
                  width: 120, // Largura fixa como no Figma
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ), // Borda cinza
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ), // Altura interna
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Não',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Fecha o pop-up e retorna 'false'
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    // --- Fim da lógica do Pop-up ---

    // 3. Verifica o resultado do pop-up
    if (wantsToStart != true) {
      print("[RouteEditor] Início do percurso cancelado pelo usuário.");
      return; // Usuário clicou em "Não" ou fora do pop-up, então paramos aqui.
    }

    // 4. Se o usuário clicou "Sim", continua com a lógica de envio
    try {
      setState(() {
        _isSending = true;
      }); // Inicia estado de envio
      final String commandsString = _commands
          .map((cmd) => cmd.toString())
          .join(', ');
      print(
        "[RouteEditor] Iniciando percurso (confirmado) com string: $commandsString",
      );

      // Tenta salvar no backend
      bool savedToApi = await _apiService.saveRoute(commandsString);
      if (mounted) {
        _showFeedbackSnackBar(
          savedToApi
              ? 'Rota salva no servidor com sucesso.'
              : 'Falha ao salvar rota no servidor.',
          isError: !savedToApi,
        );
      }
      // Decide se continua mesmo sem salvar API (aqui estamos continuando)
      await Future.delayed(const Duration(milliseconds: 300));

      // Envia para o carrinho via BLE
      if (mounted) {
        // Verifica novamente se a tela ainda existe
        bool sentToDevice = await _bleManager.sendTrajectory(commandsString);
        if (sentToDevice) {
          print("[RouteEditor] Comandos enviados para o carrinho.");
          if (mounted)
            _showFeedbackSnackBar(
              'Comandos enviados para o carrinho!',
              isError: false,
              color: Colors.blueAccent,
            );
          // TODO: Após enviar, ir para tela de executando percurso
        } else {
          print("[RouteEditor] Falha ao enviar comandos.");
          if (mounted)
            _showFeedbackSnackBar(
              "Falha ao enviar comandos para o carrinho.",
              isError: true,
            );
        }
      }
    } catch (e) {
      print("[RouteEditor] Erro na execução da rota: $e");
      if (mounted)
        _showFeedbackSnackBar("Ocorreu um erro inesperado.", isError: true);
    } finally {
      // 5. Garante que o estado de envio seja resetado
      if (mounted)
        setState(() {
          _isSending = false;
        });
    }
  }

  void _viewPreviousRoutes() {
    if (_isSending) return;
    print("[RouteEditor] Navegando para Rotas Anteriores...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreviousRoutesScreen()),
    );
  }

  // Mostra uma mensagem na parte inferior (SnackBar)
  void _showFeedbackSnackBar(
    String message, {
    bool isError = false,
    Color? color,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove anterior
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            color ??
            (isError
                ? Colors.redAccent
                : Colors.green), // Usa cor passada ou padrão
        duration: Duration(seconds: isError ? 3 : 2), // Mais tempo para erros
      ),
    );
  }

  // build UI
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Pega os estilos dos botões do tema para consistência
    final buttonStylePrimary = Theme.of(context).elevatedButtonTheme.style
        ?.copyWith(
          backgroundColor: MaterialStateProperty.all(
            const Color(0xFF00D4FF),
          ), // Ciano
          foregroundColor: MaterialStateProperty.all(
            const Color(0xFF0D0F14),
          ), // Texto escuro
        );
    final buttonStyleSecondary = Theme.of(context).outlinedButtonTheme.style;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Rotas'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // GestureDetector fecha o teclado quando toca fora
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // SingleChildScrollView para permitir rolagem
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure o percurso do carrinho',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '*ao final da rota, o carrinho depositará o objeto.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF191C23),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputCommandRow(
                      label: 'Distância (cm)',
                      controller: _distanceController,
                      onAdd: () => _addCommand(CommandType.andar),
                      icon: Icons.arrow_forward,
                      enabled: !_isSending,
                    ),
                    const SizedBox(
                      height: 15,
                    ), // Espaço REDUZIDO entre os inputs
                    _buildInputCommandRow(
                      label: 'Girar (graus)',
                      controller: _angleController,
                      onAdd: () => _addCommand(CommandType.girar),
                      icon: Icons.rotate_right,
                      enabled: !_isSending,
                    ),
                    const SizedBox(height: 10), // Espaço antes da legenda
                    Padding(
                      // Adiciona padding para alinhar com o texto do label
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'Valores positivos: direita | negativos: esquerda',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              //seção do percurso atual
              Text(
                'Percurso (${_commands.length} passos)',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Mostra a lista ou a mensagem de vazio
              _commands.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191C23),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white12,
                        ), // Borda sutil
                      ),
                      child: Text(
                        'Nenhum passo adicionado',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    )
                  // ListView.builder dentro de Column precisa de shrinkWrap e physics
                  : ListView.builder(
                      shrinkWrap: true, // Calcula o tamanho baseado no conteúdo
                      physics:
                          const NeverScrollableScrollPhysics(), // Desabilita scroll próprio
                      itemCount: _commands.length,
                      // Constrói cada item da lista visualmente
                      itemBuilder: (context, index) => _buildCommandListItem(
                        _commands[index],
                        index,
                        !_isSending,
                      ), // Passa estado de habilitação do delete
                    ),
              const SizedBox(height: 40),

              // Botões de ação inferiores
              ElevatedButton(
                style: buttonStylePrimary, // Estilo Ciano
                onPressed: _isSending
                    ? null
                    : _startRoute, // Desabilita se enviando
                // Mostra loading ou texto
                child: _isSending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Iniciar Percurso'),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                style: buttonStyleSecondary, // Estilo Padrão (Tema)
                onPressed: _isSending
                    ? null
                    : _viewPreviousRoutes, // Desabilita se enviando
                child: const Text('Visualizar rotas anteriores'),
              ),
              const SizedBox(height: 20), // Espaço final
            ],
          ),
        ),
      ),
    );
  }

  // Constroi a linha: Label + TextField + Botão '+'
  Widget _buildInputCommandRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required IconData icon,
    required bool enabled, // Para desabilitar durante envio
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled, // Habilita/Desabilita o campo
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ], // Apenas números e '-'
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ), // Teclado numérico
                decoration: InputDecoration(
                  // Usa estilo do tema
                  hintText: '0', // Placeholder
                  prefixIcon: Icon(icon, size: 20), // Ícone dentro do campo
                ),
                style: const TextStyle(
                  fontSize: 16,
                ), // Tamanho da fonte digitada
              ),
            ),
            const SizedBox(width: 10),
            // Botão Adicionar (+)
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF), // Ciano
                foregroundColor: const Color(0xFF0D0F14), // Preto
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(14),
              ),
              icon: const Icon(Icons.add),
              // Desabilita se o input estiver desabilitado
              onPressed: enabled ? onAdd : null,
            ),
          ],
        ),
      ],
    );
  }

  // Constrói um item da lista do percurso (com botão delete)
  Widget _buildCommandListItem(
    TrajectoryCommand command,
    int index,
    bool enableDelete,
  ) {
    IconData iconData;
    String description;
    // Define ícone e texto baseado no tipo de comando
    switch (command.type) {
      case CommandType.andar:
        iconData = Icons.arrow_forward;
        description = 'Andar ${command.value ?? 0}cm';
        break;
      case CommandType.girar:
        iconData = Icons.rotate_right;
        final dir = (command.value ?? 0) >= 0 ? 'Direita' : 'Esquerda';
        description = 'Girar ${(command.value ?? 0).abs()}° $dir';
        break;
    }

    // Container estilizado para o item
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Espaço abaixo
      padding: const EdgeInsets.only(
        left: 15,
        top: 8,
        bottom: 8,
        right: 5,
      ), // Padding interno ajustado
      decoration: BoxDecoration(
        color: const Color(0xFF191C23), // Cinza dos botões
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: const Color(0xFF00D4FF),
            size: 28,
          ), // Ícone Ciano
          const SizedBox(width: 15),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 16)),
          ), // Ocupa espaço
          // Botão Remover (lixeira)
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: enableDelete
                  ? Colors.redAccent.shade100
                  : Colors.grey.shade700,
            ),
            onPressed: enableDelete ? () => _removeCommand(index) : null,
            tooltip: 'Remover passo',
          ),
        ],
      ),
    );
  }
}
