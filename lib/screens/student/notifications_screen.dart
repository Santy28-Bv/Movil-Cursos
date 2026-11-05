import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/student_schema.dart';
import '../../repositories/student_repository.dart';
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
    if (StudentSchema.enabled) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _session.refreshNotices(_repository.notifications);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los avisos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _read([String? id]) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (id == null) {
        await _session.markAllRead(() => _repository.markRead());
      } else {
        await _session.markRead(id, () => _repository.markRead(id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la lectura. Intenta nuevamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      actions: [
        if (StudentSchema.enabled)
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
            onRefresh: StudentSchema.enabled ? _refresh : () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                StudentBanner(
                  title: 'Al día contigo',
                  message: '${_session.unreadCount} notificaciones sin leer',
                ),
                if (!StudentSchema.enabled)
                  const Text(
                    'El centro de avisos estará disponible cuando se conecte al servidor.',
                  ),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
                if (StudentSchema.enabled &&
                    !_loading &&
                    _error == null &&
                    _session.notices.isEmpty)
                  const Text('No tienes notificaciones.'),
                if (_session.unreadCount > 0)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _read(),
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
                                    _saving ? null : () => _read(notice.id),
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
