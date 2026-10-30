import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Reproduce enlaces HTTPS MP4/HLS dentro de Flutter.
/// YouTube/Vimeo se abren en el reproductor externo (sin descargar el video).
class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({super.key, required this.uri});
  final Uri uri;

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  bool get _external {
    final host = widget.uri.host.toLowerCase();
    return host == 'youtube.com' || host.endsWith('.youtube.com') ||
        host == 'youtu.be' || host == 'vimeo.com' ||
        host.endsWith('.vimeo.com');
  }

  @override
  void initState() {
    super.initState();
    if (!_external) _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(widget.uri);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      controller.addListener(_update);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo reproducir el video. Verifica la URL, el formato y los permisos.';
      });
    }
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_update);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_external) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill, size: 36),
          title: const Text('Abrir video de la lección'),
          subtitle: const Text('Se abrirá en YouTube o Vimeo.'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            final opened = await launchUrl(widget.uri, mode: LaunchMode.externalApplication);
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No se pudo abrir el enlace del video.'),
              ));
            }
          },
        ),
      );
    }
    if (_error != null) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)));
    }
    final controller = _controller;
    if (_loading || controller == null || !controller.value.isInitialized) {
      return const AspectRatio(aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()));
    }
    return Column(children: [
      AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
      VideoProgressIndicator(controller, allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 10)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton.filled(
          tooltip: controller.value.isPlaying ? 'Pausar' : 'Reproducir',
          onPressed: () => controller.value.isPlaying
              ? controller.pause() : controller.play(),
          icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(width: 12),
        Text(_format(controller.value.position)),
        const Text(' / '),
        Text(_format(controller.value.duration)),
      ]),
    ]);
  }

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }
}
