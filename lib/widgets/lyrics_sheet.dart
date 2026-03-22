import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';
import '../providers/audio_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';

// ── LRC line model ────────────────────────────────────────────────────────────
class LrcLine {
  final Duration timestamp;
  final String text;
  const LrcLine(this.timestamp, this.text);
}

// ── Parse "[mm:ss.xx] text" LRC format ────────────────────────────────────────
List<LrcLine> parseLrc(String lrc) {
  final lines = <LrcLine>[];
  final re = RegExp(r'^\[(\d+):(\d+)[\.\:](\d+)\]\s*(.*)$');
  for (final line in lrc.split('\n')) {
    final m = re.firstMatch(line.trim());
    if (m == null) continue;
    final min = int.parse(m.group(1)!);
    final sec = int.parse(m.group(2)!);
    final ms = int.parse(m.group(3)!.padRight(3, '0').substring(0, 3));
    final text = m.group(4) ?? '';
    lines.add(LrcLine(
        Duration(minutes: min, seconds: sec, milliseconds: ms), text));
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

// ── Public entry point ────────────────────────────────────────────────────────
void showLyricsSheet(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LyricsSheet(song: song),
  );
}

// ── Main widget ───────────────────────────────────────────────────────────────
class _LyricsSheet extends ConsumerStatefulWidget {
  final Song song;
  const _LyricsSheet({required this.song});

  @override
  ConsumerState<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<_LyricsSheet> {
  String? _plainLyrics;
  List<LrcLine>? _syncedLines;
  bool _isSynced = true;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  int _lastHighlightedIndex = -1;
  // Positive = delay highlighting (lyrics fire later than timestamp)
  // Negative = advance highlighting (lyrics fire earlier)
  double _syncOffsetMs = 1000; // default 1s delay

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    // 1. Use cached Firestore value if present
    if (widget.song.lyrics.isNotEmpty) {
      _applyLyrics(widget.song.lyrics);
      return;
    }

    // 2. Fetch from LRClib
    try {
      final title = Uri.encodeQueryComponent(widget.song.title);
      final artist = Uri.encodeQueryComponent(widget.song.artist);
      final url = 'https://lrclib.net/api/get?track_name=$title&artist_name=$artist';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final synced = (data['syncedLyrics'] as String?) ?? '';
        final plain = (data['plainLyrics'] as String?) ?? '';
        final bestLyrics = synced.isNotEmpty ? synced : plain;

        if (bestLyrics.isNotEmpty) {
          // 3. Cache to Firestore for next time
          ref.read(firestoreServiceProvider).cacheLyricsForSong(
              widget.song.id, bestLyrics);
          _applyLyrics(bestLyrics);
        } else {
          if (mounted) setState(() { _isLoading = false; });
        }
      } else if (response.statusCode == 404) {
        if (mounted) setState(() { _isLoading = false; });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyLyrics(String raw) {
    final parsed = parseLrc(raw);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (parsed.isNotEmpty) {
          _syncedLines = parsed;
          _plainLyrics = parsed.map((l) => l.text).join('\n');
          final isPremium = ref.read(isPremiumProvider);
          _isSynced = isPremium;
        } else {
          _plainLyrics = raw;
          _isSynced = false;
        }
      });
    }
  }

  int _currentLineIndex(Duration position) {
    if (_syncedLines == null || _syncedLines!.isEmpty) return -1;
    // Apply the sync offset: positive offset delays highlighting so voice matches visual
    final adjustedPosition = position - Duration(milliseconds: _syncOffsetMs.round());
    if (adjustedPosition.isNegative) return 0;
    int idx = 0;
    for (int i = 0; i < _syncedLines!.length; i++) {
      if (_syncedLines![i].timestamp <= adjustedPosition) idx = i;
      else break;
    }
    return idx;
  }

  void _autoScroll(int index) {
    if (index == _lastHighlightedIndex) return;
    _lastHighlightedIndex = index;
    final key = _lineKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.4,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(audioProvider).position;
    final currentIndex = _isSynced && _syncedLines != null
        ? _currentLineIndex(position)
        : -1;

    if (currentIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll(currentIndex));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        // Use provided scrollController only for plain lyrics
        final effectiveController = _isSynced ? _scrollController : scrollController;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[950] ?? Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SkeletonImage(
                      imageUrl: widget.song.thumbnailUrl,
                      width: 44,
                      height: 44,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.song.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(widget.song.artist,
                              style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (!_isLoading && _plainLyrics != null && _syncedLines != null)
                      GestureDetector(
                        onTap: () {
                          final isPremium = ref.read(isPremiumProvider);
                          if (isPremium) {
                            setState(() => _isSynced = !_isSynced);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Live Synced Lyrics are for Premium members only'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isSynced
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isSynced
                                  ? AppTheme.primaryColor.withOpacity(0.5)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _isSynced ? '● Live' : 'Plain',
                                style: TextStyle(
                                  color: _isSynced ? AppTheme.primaryColor : Colors.white54,
                                  fontSize: 11, fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!ref.read(isPremiumProvider))
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Icon(Icons.lock, size: 10, color: Colors.white38),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Lyrics',
                            style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              // Sync offset control (only shown in live mode)
              if (_isSynced && _syncedLines != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, size: 14, color: Colors.white30),
                      const SizedBox(width: 6),
                      const Text('Sync', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: AppTheme.primaryColor.withOpacity(0.6),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: AppTheme.primaryColor,
                            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _syncOffsetMs,
                            min: -2000,
                            max: 4000,
                            divisions: 60,
                            onChanged: (v) => setState(() {
                              _syncOffsetMs = v;
                              _lastHighlightedIndex = -1; // force re-scroll
                            }),
                          ),
                        ),
                      ),
                      Text(
                        '${(_syncOffsetMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HorizontalScrollSkeleton(height: 40, width: 300),
                              SizedBox(height: 12),
                              HorizontalScrollSkeleton(height: 40, width: 250),
                              SizedBox(height: 12),
                              HorizontalScrollSkeleton(height: 40, width: 280),
                            ],
                          ),
                        ),
                      )
                    : _error != null
                        ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)))
                        : _plainLyrics == null
                            ? const Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
                                  SizedBox(height: 12),
                                  Text('No lyrics found for this song.', style: TextStyle(color: Colors.white38)),
                                ],
                              ))
                            : _isSynced && _syncedLines != null
                                ? ListView.builder(
                                    controller: effectiveController,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                    itemCount: _syncedLines!.length,
                                    itemBuilder: (context, i) {
                                      _lineKeys[i] ??= GlobalKey();
                                      final isCurrent = i == currentIndex;
                                      final isPast = i < currentIndex;
                                      return Padding(
                                        key: _lineKeys[i],
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 250),
                                          style: TextStyle(
                                            color: isCurrent
                                                ? Colors.white
                                                : isPast
                                                    ? Colors.white38
                                                    : Colors.white54,
                                            fontSize: isCurrent ? 20 : 16,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            height: 1.4,
                                          ),
                                          child: Text(_syncedLines![i].text),
                                        ),
                                      );
                                    },
                                  )
                                : SingleChildScrollView(
                                    controller: effectiveController,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                    child: Text(
                                      _plainLyrics!,
                                      style: const TextStyle(
                                        color: Color(0xDEFFFFFF),
                                        fontSize: 17,
                                        height: 2.0,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}
