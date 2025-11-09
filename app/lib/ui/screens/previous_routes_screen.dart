import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart'; 

class PreviousRoutesScreen extends StatefulWidget {
  const PreviousRoutesScreen({super.key});
  @override
  State<PreviousRoutesScreen> createState() => _PreviousRoutesScreenState();
}

class _PreviousRoutesScreenState extends State<PreviousRoutesScreen> {
  
  final ApiService _apiService = locator<ApiService>();

  final ScrollController _scrollController =
      ScrollController(); // Controlador do scroll
  final List<Map<String, dynamic>> _routes = []; // Lista que acumula as rotas

  bool _isLoading = false; // Indica o carregamento inicial
  bool _isLoadingMore =
      false; // Indica o carregamento de mais itens (no final da lista)
  bool _hasMore = true; // Indica se ainda há mais dados para buscar na API
  int _offset = 0; // O "ponto de partida" da próxima busca
  final int _limit = 20; // Quantos itens buscar por vez
  String? _error; // Para armazenar mensagens de erro

  @override
  void initState() {
    super.initState();
    // Inicia a primeira busca
    _fetchInitialRoutes();
    // Adiciona um listener no ScrollController para detectar o fim da página
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // Limpa o listener
    _scrollController.dispose(); // Limpa o controller
    super.dispose();
  }

  // Listener do Scroll: chamado toda vez que o usuário rola
  void _onScroll() {

    // Verifica se estamos perto do fim da lista (ex: 90% rolado)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Se sim, busca mais rotas
      _fetchMoreRoutes();
    }
  }

  // Busca a primeira página de rotas
  Future<void> _fetchInitialRoutes() async {

    // Evita múltiplas chamadas
    if (_isLoading) return;

    print("[PreviousRoutes] Buscando rotas iniciais...");
    setState(() {
      _isLoading = true; // Ativa o loading principal
      _error = null; // Limpa erros antigos
    });

    try {
      final newRoutes = await _apiService.getPreviousRoutes(
        limit: _limit,
        offset: 0,
      );
      if (!mounted) return; // Garante que a tela ainda existe
      setState(() {
        _routes.clear(); // Limpa a lista antes de adicionar os primeiros
        _routes.addAll(newRoutes);
        _offset = newRoutes.length; // Atualiza o offset
        _hasMore =
            newRoutes.length ==
            _limit; // Se recebeu menos que o limite, não há mais
        _isLoading = false;
      });
    } catch (e) {
      print("[PreviousRoutes] Erro ao buscar rotas iniciais: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString(); // Salva o erro para mostrar na UI
      });
    }
  }

  // Busca as próximas páginas de rotas
  Future<void> _fetchMoreRoutes() async {
  
    // Condições de guarda: não busca se já estiver buscando, ou se não houver mais dados
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    print("[PreviousRoutes] Buscando mais rotas... Offset: $_offset");
    setState(() {
      _isLoadingMore = true; // Ativa o loading *secundário* (no fim da lista)
    });

    try {
      final newRoutes = await _apiService.getPreviousRoutes(
        limit: _limit,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _routes.addAll(newRoutes); // Adiciona os novos itens à lista existente
        _offset += newRoutes.length; // Atualiza o offset
        _hasMore = newRoutes.length == _limit; // Verifica se ainda há mais
        _isLoadingMore = false;
      });
    } catch (e) {
      print("[PreviousRoutes] Erro ao buscar mais rotas: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar mais rotas.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _refreshRoutes() async {
  
    print("[PreviousRoutes] Atualizando rotas...");
    // Reseta o estado e busca a primeira página novamente
    _offset = 0;
    _hasMore = true;
    _routes.clear();
    await _fetchInitialRoutes();
  }

  // Formata a data (igual antes)
  String _formatDateTime(String? dateTimeString) {
  
    if (dateTimeString == null || dateTimeString.isEmpty)
      return 'Data indisponível';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
    } catch (e) {
      return 'Data inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
 
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rotas anteriores'), centerTitle: true),
      body: _buildBody(textTheme),
    );
  }

  // Widget auxiliar para construir o corpo da tela
  Widget _buildBody(TextTheme textTheme) {
  
    // Estado 1: Carregamento Inicial
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado 2: Erro no Carregamento Inicial
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
              const SizedBox(height: 15),
              Text(
                'Erro ao carregar rotas.\nVerifique sua conexão com a API.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  fixedSize: null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _refreshRoutes,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // Estado 3: Sucesso, mas lista vazia
    if (_routes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshRoutes,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 60,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Nenhuma rota anterior foi salva.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Estado 4: Sucesso com dados, exibe a lista
    return RefreshIndicator(
      onRefresh: _refreshRoutes,
      child: ListView.builder(
        controller: _scrollController, // Conecta o controlador de scroll
        padding: const EdgeInsets.all(15),
        itemCount: _routes.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Se for o último item E ainda houver mais dados, mostra o loading
          if (index == _routes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Se for um item normal da lista
          final route = _routes[index];
          final routeId = route['id'] ?? (index + 1);
          final createdAt = _formatDateTime(route['created_at'] as String?);
          final commands =
              route['commands'] as String? ?? 'Comandos indisponíveis';

          // Constrói o Card (igual antes)
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF191C23),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: const Color(0xFF33DDFF),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              title: Text(
                'Rota $routeId',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              trailing: Text(
                createdAt,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              // subtitle: Padding(
              //   padding: const EdgeInsets.only(top: 5.0),
              //   child: Text(
              //     commands,
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: 12,
              //     ),
              //     maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              onTap: () {
                print('[PreviousRoutes] Rota selecionada: ID $routeId');
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ID: $routeId\nComandos: $commands',
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'FECHAR',
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              },
              splashColor: const Color(0xFF33DDFF),
            ),
          );
        },
      ),
    );
  }
}