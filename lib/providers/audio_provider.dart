import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/music_models.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

// ── Audio Handler Implementation ──────────────────────────────────────────────

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  bool _isPremium = false;

  void updatePremiumStatus(bool isPremium) {
    if (_isPremium != isPremium) {
      _isPremium = isPremium;
      playbackState.add(_transformEvent(_player.playbackEvent));
    }
  }

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Broadcast state changes from the player to the system
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen for current item changes to update mediaItem efficiently
    _player.sequenceStateStream.listen((sequenceState) {
      final item = sequenceState?.currentSource?.tag as MediaItem?;
      if (item != null) {
        mediaItem.add(item);
      }
    });

    // Update mediaItem when duration is discovered by the player
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    _player.setAudioSource(_playlist);
  }

  AudioPlayer get player => _player;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (!_isPremium) return;
    return _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  Future<void> setQueue(List<Song> songs) async {
    final mediaItems = songs.map((s) => MediaItem(
          id: s.id,
          album: s.album,
          title: s.title,
          artist: s.artist,
          duration: s.duration,
          artUri: s.thumbnailUrl.isNotEmpty ? Uri.parse(s.thumbnailUrl) : null,
          extras: {'url': s.audioUrl},
        )).toList();

    queue.add(mediaItems);

    final audioSources = mediaItems.map((item) => AudioSource.uri(
          Uri.parse(item.extras!['url'] as String),
          tag: item,
        )).toList();

    await _playlist.clear();
    await _playlist.addAll(audioSources);
  }

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    play();
  }

  // Helper to transform just_audio events to audio_service states
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_isPremium) MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        if (_isPremium) MediaAction.skipToPrevious,
        MediaAction.skipToNext,
      },
      androidCompactActionIndices: _isPremium ? const [0, 1, 3] : const [0, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  // This will be initialized in main.dart and overridden in ProviderScope
  throw UnimplementedError();
});

enum RepeatMode { none, one, all }

class AudioState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration bufferedPosition;
  final Duration totalDuration;
  final List<Song> queue;
  final List<Song> originalQueue;
  final bool isShuffled;
  final RepeatMode repeatMode;

  AudioState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.queue = const [],
    this.originalQueue = const [],
    this.isShuffled = false,
    this.repeatMode = RepeatMode.none,
  });

  AudioState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? bufferedPosition,
    Duration? totalDuration,
    List<Song>? queue,
    List<Song>? originalQueue,
    bool? isShuffled,
    RepeatMode? repeatMode,
  }) {
    return AudioState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      queue: queue ?? this.queue,
      originalQueue: originalQueue ?? this.originalQueue,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  final MyAudioHandler _handler;
  final Ref _ref;

  AudioNotifier(this._handler, this._ref) : super(AudioState()) {
    _init();
    _handler.updatePremiumStatus(_ref.read(isPremiumProvider));
    _ref.listen<bool>(isPremiumProvider, (previous, next) {
      _handler.updatePremiumStatus(next);
    });
  }

  void _init() {
    final player = _handler.player;

    player.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
    });

    player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    player.bufferedPositionStream.listen((buffered) {
      state = state.copyWith(bufferedPosition: buffered);
    });

    player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(totalDuration: duration);
      }
    });

    // Sync current song with handler's mediaItem
    _handler.mediaItem.listen((item) {
      if (item != null) {
        final song = state.queue.firstWhere(
          (s) => s.id == item.id,
          orElse: () => Song(
            id: item.id,
            title: item.title,
            artist: item.artist ?? '',
            album: item.album ?? '',
            thumbnailUrl: item.artUri?.toString() ?? '',
            audioUrl: item.extras?['url'] ?? '',
            duration: item.duration ?? Duration.zero,
          ),
        );
        state = state.copyWith(currentSong: song);
        // Record recently played
        _ref.read(firestoreServiceProvider).addToRecentlyPlayed(song);
      } else {
        state = state.copyWith(currentSong: null);
      }
    });

    // Sync repeat mode with player
    player.loopModeStream.listen((loopMode) {
      RepeatMode newMode;
      switch (loopMode) {
        case LoopMode.off:
          newMode = RepeatMode.none;
          break;
        case LoopMode.one:
          newMode = RepeatMode.one;
          break;
        case LoopMode.all:
          newMode = RepeatMode.all;
          break;
      }
      state = state.copyWith(repeatMode: newMode);
    });

    // Sync shuffle mode with player
    player.shuffleModeEnabledStream.listen((enabled) {
      state = state.copyWith(isShuffled: enabled);
    });
  }

  Future<void> playSong(Song song) async {
    final index = state.queue.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      await _handler.playSongAtIndex(index);
    } else {
      // If song not in queue, set it as the only song or add it
      await setQueue([song]);
      await _handler.playSongAtIndex(0);
    }
  }

  Future<void> playFromSongs(List<Song> songs, Song song) async {
    await setQueue(songs);
    
    // Enforce shuffle for free users
    final isPremium = _ref.read(isPremiumProvider);
    if (!isPremium) {
      await _handler.player.setShuffleModeEnabled(true);
      await _handler.player.shuffle();
    }

    final index = songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      await _handler.playSongAtIndex(index);
    }
  }

  void togglePlay() {
    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void seek(Duration position) {
    _handler.seek(position);
  }

  Future<void> setQueue(List<Song> songs) async {
    state = state.copyWith(queue: songs, originalQueue: songs, isShuffled: false);
    await _handler.setQueue(songs);
  }

  void skipToNext() {
    _handler.skipToNext();
  }

  void skipToPrevious() {
    _handler.skipToPrevious();
  }

  void toggleShuffle() {
    final newShuffle = !state.isShuffled;
    _handler.player.setShuffleModeEnabled(newShuffle);
    if (newShuffle) {
      _handler.player.shuffle();
    }
    state = state.copyWith(isShuffled: newShuffle);
  }

  void cycleRepeatMode() {
    LoopMode nextMode;
    switch (state.repeatMode) {
      case RepeatMode.none:
        nextMode = LoopMode.all;
        break;
      case RepeatMode.all:
        nextMode = LoopMode.one;
        break;
      case RepeatMode.one:
        nextMode = LoopMode.off;
        break;
    }
    _handler.player.setLoopMode(nextMode);
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return AudioNotifier(handler, ref);
});
