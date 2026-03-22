import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/music_models.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_image.dart';

class DownloadModal extends StatefulWidget {
  final List<Song> songs;

  const DownloadModal({super.key, required this.songs});

  @override
  State<DownloadModal> createState() => _DownloadModalState();
}

class _DownloadModalState extends State<DownloadModal> {
  late Set<String> _selectedSongIds;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Initially select all songs for download
    _selectedSongIds = widget.songs.map((s) => s.id).toSet();
  }

  void _toggleAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedSongIds = widget.songs.map((s) => s.id).toSet();
      } else {
        _selectedSongIds.clear();
      }
    });
  }

  void _toggleSong(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedSongIds.add(id);
      } else {
        _selectedSongIds.remove(id);
      }
    });
  }

  Future<void> _startDownload() async {
    if (_selectedSongIds.isEmpty || _isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      Directory? baseDir;
      if (Platform.isAndroid) {
        try {
          // Attempt to write to public Android Downloads directory
          baseDir = Directory('/storage/emulated/0/Download');
          final testDir = Directory('${baseDir.path}/basal');
          if (!await testDir.exists()) await testDir.create(recursive: true);
        } catch (e) {
          // Fallback to app-specific external storage
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          baseDir = extDirs?.first;
        }
      } else if (Platform.isIOS) {
        // iOS saves to its Application Documents (visible via Files app if configured)
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        // Desktop platforms Map to ~/Downloads
        baseDir = await getDownloadsDirectory();
      }
      
      baseDir ??= await getApplicationDocumentsDirectory();

      final basalDir = Directory('${baseDir.path}/basal');
      if (!await basalDir.exists()) {
        await basalDir.create(recursive: true);
      }

      final targetSongs = widget.songs.where((s) => _selectedSongIds.contains(s.id)).toList();
      
      for (int i = 0; i < targetSongs.length; i++) {
        final song = targetSongs[i];
        final file = File('${basalDir.path}/${song.title}.mp3');
        
        final response = await http.get(Uri.parse(song.audioUrl));
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
          setState(() {
            _downloadProgress = (i + 1) / targetSongs.length;
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully downloaded ${_selectedSongIds.length} songs to ${basalDir.path}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedSongIds.length == widget.songs.length;
    final someSelected = _selectedSongIds.isNotEmpty && !allSelected;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Header Grabber
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title and Select All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Download Playlist',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text('Select All', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      activeColor: AppTheme.primaryColor,
                      checkColor: Colors.black,
                      onChanged: _toggleAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          
          // Song List
          Expanded(
            child: ListView.builder(
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                final song = widget.songs[index];
                final isSelected = _selectedSongIds.contains(song.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.black,
                  onChanged: (val) => _toggleSong(song.id, val),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  secondary: SkeletonImage(
                    imageUrl: song.thumbnailUrl,
                    width: 40,
                    height: 40,
                    borderRadius: 4,
                  ),
                );
              },
            ),
          ),
          
          // Bottom Download Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selectedSongIds.isEmpty || _isDownloading ? null : _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isDownloading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Downloading... ${(_downloadProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Text(
                      _selectedSongIds.isEmpty 
                        ? 'Select songs to download' 
                        : 'Download ${_selectedSongIds.length} Song${_selectedSongIds.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
