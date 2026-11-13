import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../services/academix_api.dart';
import '../../services/lesson_resource_service.dart';
import '../../services/resource_blob.dart';
import 'lesson_video_player.dart';

class LessonResource extends StatefulWidget {
  const LessonResource({super.key, required this.resource, required this.api});
  final LearningResource resource;
  final AcademixApi api;
  @override
  State<LessonResource> createState() => _LessonResourceState();
}

class _LessonResourceState extends State<LessonResource> {
  bool _loading = false;
  bool _opened = false;
  String? _error;
  ApiBinary? _file;
  String? _blob;
  Uri? _video;
  Map<String, String> _headers = {};
  @override
  void dispose() {
    if (_blob != null) revokeResourceUrl(_blob!);
    super.dispose();
  }

  Future<void> _open() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resource = widget.resource;
      if (resource.url.isNotEmpty) {
        final uri = LessonResourceService.validatedExternal(resource.url);
        if (uri == null) {
          throw const ApiException('Este enlace no está disponible.');
        }
        if (resource.isVideo) {
          _video = uri;
        } else if (!await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        )) {
          throw const ApiException('No pudimos abrir el enlace.');
        }
      } else if (resource.isVideo && !kIsWeb) {
        // Express verifica acceso y transmite rangos de bytes. El JWT solo va a su origen.
        _video = widget.api.endpoint(resource.contentPath);
        final token = widget.api.client.auth.currentSession?.accessToken;
        if (token == null) {
          throw const ApiException('Inicia sesión para abrir el video.');
        }
        _headers = {'Authorization': 'Bearer $token'};
      } else {
        final file = await widget.api.binary(resource.contentPath);
        if (!mounted) return;
        _file = file;
        if (file.contentType.startsWith('video/')) {
          if (kIsWeb) {
            _blob = createResourceUrl(file.bytes, file.contentType);
            _video = Uri.parse(_blob!);
          } else {
            _video = widget.api.endpoint(resource.contentPath);
            _headers = {
              'Authorization':
                  'Bearer ${widget.api.client.auth.currentSession!.accessToken}',
            };
          }
        }
      }
      if (mounted) setState(() => _opened = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = studentError(error, 'No pudimos abrir este recurso.'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    final file = _file;
    if (file == null) return;
    final owner = widget.api.client.auth.currentUser?.id;
    if (owner == null) return;
    final ext =
        const {
          'application/pdf': 'pdf',
          'image/png': 'png',
          'image/jpeg': 'jpg',
          'audio/mpeg': 'mp3',
          'text/plain': 'txt',
          'application/zip': 'zip',
        }[file.contentType.split(';').first] ??
        'bin';
    final name =
        '${widget.resource.title.replaceAll(RegExp(r'[^\wáéíóúÁÉÍÓÚñÑ .-]'), '_')}.$ext';
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile.fromData(file.bytes, mimeType: file.contentType, name: name)],
        fileNameOverrides: [name],
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'No pudimos abrir las opciones para guardar el archivo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              resource.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${resource.type}${resource.required ? ' · Obligatorio' : ''}',
            ),
            if (resource.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(resource.description),
              ),
            const SizedBox(height: 12),
            if (_video != null)
              LessonVideoPlayer(
                key: ValueKey(_video),
                uri: _video!,
                httpHeaders: _headers,
              )
            else if (_file?.contentType.startsWith('image/') == true)
              Image.memory(_file!.bytes)
            else if (_file != null)
              OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Abrir o guardar archivo'),
              )
            else if (resource.url.isNotEmpty || resource.contentPath.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _loading ? null : _open,
                icon: Icon(
                  resource.isVideo
                      ? Icons.play_circle_outline
                      : Icons.attach_file,
                ),
                label: Text(
                  _loading
                      ? 'Abriendo…'
                      : resource.url.isNotEmpty
                      ? 'Abrir enlace'
                      : 'Abrir recurso protegido',
                ),
              )
            else
              const Text('Este recurso no está disponible.'),
            if (_opened && resource.url.isNotEmpty && _video == null)
              TextButton(onPressed: _open, child: const Text('Abrir de nuevo')),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!),
              ),
          ],
        ),
      ),
    );
  }
}
