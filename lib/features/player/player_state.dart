class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.isPlaying = false,
    this.isBuffering = false,
    this.isOpening = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.errorText,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool isOpening;
  final Duration position;
  final Duration duration;
  final double volume;
  final String? errorText;

  PlaybackSnapshot copyWith({
    bool? isPlaying,
    bool? isBuffering,
    bool? isOpening,
    Duration? position,
    Duration? duration,
    double? volume,
    String? errorText,
    bool clearError = false,
  }) {
    return PlaybackSnapshot(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isOpening: isOpening ?? this.isOpening,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorText: clearError ? null : errorText ?? this.errorText,
    );
  }
}
