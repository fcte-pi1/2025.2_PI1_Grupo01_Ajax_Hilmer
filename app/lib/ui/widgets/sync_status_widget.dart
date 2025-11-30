import 'package:flutter/material.dart';
import '../../service_locator.dart';
import '../../services/sync_service.dart';

// Widget que mostra o status de sincronização e permite forçar sync, não utilizado pois estamos nos conectabdo diretamente ao carrinho via wifi
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncService _syncService = locator<SyncService>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _syncService.pendingCount,
      builder: (context, pendingCount, child) {
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _syncService.isSyncing,
          builder: (context, isSyncing, child) {
            return Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSyncing ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSyncing ? Colors.blue.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSyncing ? Icons.sync : Icons.cloud_off,
                    color: isSyncing ? Colors.blue : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSyncing
                              ? 'Sincronizando...'
                              : '$pendingCount ${pendingCount == 1 ? 'item pendente' : 'itens pendentes'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSyncing
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          isSyncing
                              ? 'Enviando dados para a nuvem'
                              : 'Conecte à internet para sincronizar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSyncing)
                    ValueListenableBuilder<bool>(
                      valueListenable: _syncService.hasInternet,
                      builder: (context, hasInternet, child) {
                        return IconButton(
                          onPressed:
                              hasInternet ? () => _syncService.syncAll() : null,
                          icon: Icon(
                            Icons.cloud_upload,
                            color: hasInternet ? Colors.blue : Colors.grey,
                          ),
                          tooltip: 'Sincronizar agora',
                        );
                      },
                    ),
                  if (isSyncing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Banner compacto para mostrar na AppBar
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = locator<SyncService>();

    return ValueListenableBuilder<int>(
      valueListenable: syncService.pendingCount,
      builder: (context, pendingCount, child) {
        if (pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: syncService.isSyncing,
          builder: (context, isSyncing, child) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  IconButton(
                    onPressed: isSyncing ? null : () => syncService.syncAll(),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_off, color: Colors.orange),
                    tooltip: isSyncing
                        ? 'Sincronizando...'
                        : '$pendingCount pendentes - toque para sincronizar',
                  ),
                  if (!isSyncing)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
