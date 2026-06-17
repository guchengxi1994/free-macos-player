import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'macOS Video Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111315),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E847F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MacosPlayerPage(),
    );
  }
}

class MacosPlayerPage extends StatefulWidget {
  const MacosPlayerPage({super.key});

  @override
  State<MacosPlayerPage> createState() => _MacosPlayerPageState();
}

class _MacosPlayerPageState extends State<MacosPlayerPage> {
  static const String _defaultVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  late final Player _player;
  late final VideoController _videoController;
  late final TextEditingController _urlController;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<String>? _errorSubscription;

  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100;
  String? _errorText;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _urlController = TextEditingController(text: _defaultVideoUrl);
    _bindPlayerStreams();
    unawaited(_openMedia(_defaultVideoUrl));
  }

  void _bindPlayerStreams() {
    _playingSubscription = _player.stream.playing.listen((value) {
      if (!mounted) return;
      setState(() => _isPlaying = value);
    });
    _positionSubscription = _player.stream.position.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _durationSubscription = _player.stream.duration.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value);
    });
    _volumeSubscription = _player.stream.volume.listen((value) {
      if (!mounted) return;
      setState(() => _volume = value);
    });
    _bufferingSubscription = _player.stream.buffering.listen((value) {
      if (!mounted) return;
      setState(() => _isBuffering = value);
    });
    _errorSubscription = _player.stream.error.listen((value) {
      if (!mounted) return;
      setState(() => _errorText = value);
    });
  }

  Future<void> _openMedia(String input) async {
    final source = input.trim();
    if (source.isEmpty) {
      setState(() {
        _errorText = '请输入有效的视频地址';
      });
      return;
    }

    setState(() {
      _isOpening = true;
      _errorText = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      await _player.open(Media(_normalizeMediaSource(source)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = '加载失败: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final target = _position + offset;
    final max = _duration == Duration.zero ? target : _duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > max
            ? max
            : target;
    await _player.seek(clamped);
  }

  Future<void> _onSeek(double seconds) async {
    await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> _setVolume(double value) async {
    await _player.setVolume(value);
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _volumeSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _urlController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationSeconds = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds / 1000;
    final positionSeconds = _position.inMilliseconds <= 0
        ? 0.0
        : (_position.inMilliseconds / 1000).clamp(0.0, durationSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('macOS 视频播放器'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF171A1D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '视频 URL',
                          hintText: '输入 mp4 / m3u8 / 直播流地址',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _openMedia,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isOpening
                          ? null
                          : () => _openMedia(_urlController.text),
                      icon: const Icon(Icons.playlist_play_rounded),
                      label: Text(_isOpening ? '加载中' : '加载视频'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0E1012), Color(0xFF1D2428)],
                  ),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Video(
                        controller: _videoController,
                        controls: NoVideoControls,
                        fit: BoxFit.contain,
                      ),
                      if (_isBuffering || _isOpening)
                        const Center(child: CircularProgressIndicator()),
                      if (_errorText != null)
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.75),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _errorText!,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF171A1D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Slider(
                      value: positionSeconds,
                      max: durationSeconds,
                        onChanged: _duration == Duration.zero
                            ? null
                            : (value) => unawaited(_onSeek(value)),
                    ),
                    Row(
                      children: [
                        Text(formatDuration(_position)),
                        const Spacer(),
                        Text(formatDuration(_duration)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _seekRelative(
                            const Duration(seconds: -10),
                          ),
                          icon: const Icon(Icons.replay_10_rounded),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.tonalIcon(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                          ),
                          label: Text(_isPlaying ? '暂停' : '播放'),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _seekRelative(
                            const Duration(seconds: 10),
                          ),
                          icon: const Icon(Icons.forward_10_rounded),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.volume_up_rounded),
                        Expanded(
                          child: Slider(
                            value: _volume.clamp(0, 100),
                            max: 100,
                          onChanged: (value) => unawaited(_setVolume(value)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 44,
                          child: Text(
                            _volume.round().toString(),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  return '$minutes:$seconds';
}

String _normalizeMediaSource(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.hasScheme) {
    return source;
  }

  final file = File(source);
  if (file.existsSync()) {
    return file.uri.toString();
  }

  return source;
}
