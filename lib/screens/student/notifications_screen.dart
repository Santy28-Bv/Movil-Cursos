import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';
import '../../services/student_session.dart';
import '../../widgets/student/student_banner.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _session = StudentSession.instance;
  late final StudentRepository _repository;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository = StudentRepository(Supabase.instance.client);
    _refresh();
  }

  Future<void> _refresh() async {
    if (_loading || _saving) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _session.refreshNotices(
        _repository.notifications,
        count: _repository.unreadNoticeCount,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = studentError(error, 'No se pudieron cargar los avisos.');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _read([String? id]) async {
    if (_saving || _loading) return;
    setState(() => _saving = true);
    try {
      if (id == null) {
        await _session.markAllRead(() => _repository.markRead());
      } else {
        await _session.markRead(id, () => _repository.markRead(id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              studentError(
                error,
                'No se pudo guardar la lectura. Intenta nuevamente.',
              ),
            ),
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    try {
      await _session.refreshUnreadCount(_repository.unreadNoticeCount);
    } on ApiException {
      // La lectura ya se guardó. El siguiente refresco obtiene el total.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _loading || _saving ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: _session,
      builder:
          (context, _) => RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                StudentBanner(
                  title: 'Al día contigo',
                  message:
                      _session.unreadCountKnown
                          ? '${_session.unreadCount} notificaciones sin leer'
                          : 'Consulta los avisos de tu cuenta.',
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
                if (!_loading && _error == null && _session.notices.isEmpty)
                  const Text('No tienes notificaciones.'),
                if (_session.unreadCount > 0)
                  OutlinedButton.icon(
                    onPressed: _saving || _loading ? null : () => _read(),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Marcar todas como leídas'),
                  ),
                ..._session.notices.map(
                  (notice) => Card(
                    child: ListTile(
                      leading: Icon(
                        notice.isRead
                            ? Icons.drafts_outlined
                            : Icons.mark_email_unread_outlined,
                      ),
                      title: Text(notice.title),
                      subtitle: Text(notice.message),
                      isThreeLine: false,
                      trailing:
                          notice.isRead
                              ? null
                              : IconButton(
                                tooltip: 'Marcar como leída',
                                onPressed:
                                    _saving || _loading
                                        ? null
                                        : () => _read(notice.id),
                                icon: const Icon(Icons.done),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    ),
  );
}
