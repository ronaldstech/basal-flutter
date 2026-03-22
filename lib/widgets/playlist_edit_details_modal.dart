import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';

class PlaylistEditDetailsModal extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistEditDetailsModal({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistEditDetailsModal> createState() =>
      _PlaylistEditDetailsModalState();
}

class _PlaylistEditDetailsModalState
    extends ConsumerState<PlaylistEditDetailsModal> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descController = TextEditingController(text: widget.playlist.description);
    _imageController = TextEditingController(text: widget.playlist.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      var request = http.MultipartRequest(
          'POST', Uri.parse('https://unimarket-mw.com/basal/cover.php'));
          
      final ext = image.path.split('.').last.toLowerCase();
      String mimeType = 'jpeg';
      if (ext == 'png') mimeType = 'png';
      else if (ext == 'gif') mimeType = 'gif';
      else if (ext == 'webp') mimeType = 'webp';
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        image.path,
        contentType: MediaType('image', mimeType),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['url'] != null) {
          setState(() {
            _imageController.text = data['url'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: AppTheme.primaryColor));
          }
        } else if (data['error'] != null) {
          throw Exception(data['error']);
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(firestoreServiceProvider).updatePlaylistDetails(
            widget.playlist.id,
            name: name,
            description: _descController.text.trim(),
            imageUrl: _imageController.text.trim().isNotEmpty
                ? _imageController.text.trim()
                : null,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Edit Playlist Details',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Cover Image',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickAndUploadImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
                image: _imageController.text.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_imageController.text),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _isUploadingImage
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor))
                  : _imageController.text.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.camera,
                                  color: Colors.white54, size: 40),
                              SizedBox(height: 8),
                              Text('Tap to select image',
                                  style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Iconsax.edit,
                                color: Colors.white, size: 40),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSaving || _isUploadingImage ? null : _save,
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Save Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
