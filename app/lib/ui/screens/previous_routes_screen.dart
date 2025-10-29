import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class PreviousRoutesScreen extends StatefulWidget {
  const PreviousRoutesScreen({super.key});
  @override
  State<PreviousRoutesScreen> createState() => _PreviousRoutesScreenState();
}

class _PreviousRoutesScreenState extends State<PreviousRoutesScreen> {
  // SUBSTITUIR DPS PELA FORMA CORRETA - GetIt, Provider, etc
  final ApiService _apiService = ApiService(); // MODO INCORRETO (DEMO)

  // FutureBuilder lidará com o estado da busca (carregando, erro, sucesso)
  late Future<List<Map<String, dynamic>>> _routesFuture;

  @override
  void initState() {
    super.initState();
    // quando a tela é carregada ja inicia as buscas
    _routesFuture = _apiService.getPreviousRoutes();
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty)
      return 'Data indisponível';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat(
        'dd/MM/yyyy HH:mm',
        'pt_BR',
      ).format(dateTime); // Adiciona locale pt_BR
    } catch (e) {
      print("[PreviousRoutes] Erro ao formatar data '$dateTimeString': $e");
      return 'Data inválida';
    }
  }

  Future<void> _refreshRoutes() async {
    setState(() {
      // Atribui um novo Future para o FutureBuilder reconstruir a UI com dados atualizados
      _routesFuture = _apiService.getPreviousRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(
      context,
    ).textTheme; // Pega estilos de texto do tema

    return Scaffold(
      appBar: AppBar(title: const Text('Rotas anteriores'), centerTitle: true),
      // FutureBuilder gerencia os estados da requisição assíncrona
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _routesFuture, // O Future que ele observa
        builder: (context, snapshot) {
          // Estado: Carregando dados...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado: Erro na requisição
          if (snapshot.hasError) {
            print("[PreviousRoutes] Erro no FutureBuilder: ${snapshot.error}");
            // Oferece uma forma de tentar novamente
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erro ao carregar rotas.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    // Estilo customizado para o botão de tentar novamente
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade100,
                      foregroundColor: Colors.black,
                      fixedSize: null, // Tamanho adaptável
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _refreshRoutes, // Tenta recarregar
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          // Estado: Sucesso, mas lista vazia
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Usa RefreshIndicator para permitir 'puxar para atualizar' mesmo com lista vazia
            return RefreshIndicator(
              onRefresh: _refreshRoutes,
              child: ListView(
                // Precisa de um Scrollable (ListView) para o RefreshIndicator funcionar
                physics:
                    const AlwaysScrollableScrollPhysics(), // Garante que sempre pode puxar
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                  ), // Espaço responsivo
                  const Center(
                    child: Icon(
                      Icons.history_toggle_off,
                      size: 60,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text(
                      'Nenhuma rota anterior foi salva.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            );
          }

          // Estado: Sucesso com dados! Exibe a lista.
          final routes = snapshot.data!;
          // RefreshIndicator permite 'puxar para atualizar'
          return RefreshIndicator(
            onRefresh: _refreshRoutes,
            child: ListView.builder(
              padding: const EdgeInsets.all(15), // Padding ao redor da lista
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                // Obtém os dados de cada rota (com tratamento para nulos)
                final routeId = route['id'] ?? (index + 1); // Usa ID ou índice
                final createdAt = _formatDateTime(
                  route['created_at'] as String?,
                );
                final commands =
                    route['commands'] as String? ?? 'Comandos indisponíveis';

                // Card estilizado para cada item da lista
                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ), // Espaço abaixo de cada card
                  color: const Color(
                    0xFF191C23,
                  ), // Cor de fundo do card (cinza dos botões)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    // Borda Ciano suave, menos chamativa que no botão Outlined
                    side: BorderSide(
                      color: const Color(0xFF33DDFF).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  // ListTile organiza o conteúdo do card (título, subtítulo, trailing)
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    // Título principal (Nome da Rota)
                    title: Text(
                      'Rota $routeId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 17,
                      ), // SemiBold
                    ),
                    // Trailing: Conteúdo alinhado à direita (Data/Hora)
                    trailing: Text(
                      createdAt,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    // Subtítulo (Preview dos Comandos)
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                        top: 5.0,
                      ), // Espaço acima do subtítulo
                      child: Text(
                        commands,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1, // Mostra apenas 1 linha
                        overflow: TextOverflow
                            .ellipsis, // Adiciona '...' se for longo
                      ),
                    ),
                    // Ação ao clicar no item
                    onTap: () {
                      print('[PreviousRoutes] Rota selecionada: ID $routeId');
                      // Exemplo: Mostra os comandos completos em um SnackBar
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ID: $routeId\nComandos: $commands',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          duration: const Duration(
                            seconds: 5,
                          ), // Mais tempo para ler
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ), // Botão para fechar
                        ),
                      );
                      // TODO: Implementar a navegação para detalhes da rota
                    },
                    //Efeito visual ao clicar
                    splashColor: const Color(0x0433DDFF),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
