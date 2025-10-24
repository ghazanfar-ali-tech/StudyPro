import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/playlist_provider.dart';
import 'package:file_picker/file_picker.dart';

class UploadVideoPlaylistScreen extends StatefulWidget {
  const UploadVideoPlaylistScreen({super.key});

  @override
  State<UploadVideoPlaylistScreen> createState() => _UploadVideoPlaylistScreenState();
}

class _UploadVideoPlaylistScreenState extends State<UploadVideoPlaylistScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _videoDurationController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<PlaylistProvider>(context);
    if (_titleController.text != provider.title) {
      _titleController.text = provider.title;
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      Provider.of<PlaylistProvider>(context, listen: false)
          .setVideo(File(pickedFile.path));
    }
  }

  void _submit(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    if (provider.selectedVideo != null && provider.title.isNotEmpty) {
      provider.addVideoToPlaylist();
      _titleController.clear(); 
      _urlController.clear();
      _videoDurationController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a video and enter a title"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Playlist')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width,
              height: height * 0.19,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.03),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 126, 127, 128),
                    Color.fromARGB(255, 2, 122, 219)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: provider.selectedVideo == null
                  ? Center(
                      child: IconButton(
                        icon: const Icon(Icons.video_library,
                            size: 40, color: Colors.white),
                        onPressed: () => _pickVideo(context),
                      ),
                    )
                  : const Center(
                      child: Text("Video Selected",
                          style: TextStyle(color: Colors.white))),
            ),
            SizedBox(height: height * 0.03),
            TextField(
              controller: _titleController,
              onChanged: (value) =>
                  Provider.of<PlaylistProvider>(context, listen: false)
                      .setTitle(value),
              decoration: InputDecoration(
                hintText: 'Video Title',
                prefixIcon: const Icon(Icons.title, color: Colors.blue),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: height * 0.03),
            TextField(
              controller: _videoDurationController,
              onChanged: (value) =>
                  Provider.of<PlaylistProvider>(context, listen: false)
                      .setVideoDuration(value),
              decoration: InputDecoration(
                hintText: 'Video Duration',
                prefixIcon: const Icon(Icons.timer, color: Colors.blue),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: height * 0.03),
TextField(
  onChanged: (value) =>
      Provider.of<PlaylistProvider>(context, listen: false).setDescription(value),
  decoration: InputDecoration(
    hintText: 'Video Description',
    prefixIcon: const Icon(Icons.description, color: Colors.blue),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),
  maxLines: 3,
),
SizedBox(height: height * 0.02),
if (provider.pdfs.isNotEmpty) ...[
  const Text("PDFs:", style: TextStyle(fontWeight: FontWeight.bold)),
  ...provider.pdfs.map((pdf) => ListTile(
        title: Text(pdf.path.split('/').last),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            int index = provider.pdfs.indexOf(pdf);
            Provider.of<PlaylistProvider>(context, listen: false)
                .removePdf(index);
          },
        ),
      )),
],

if (provider.urls.isNotEmpty) ...[
  const Text("Links:", style: TextStyle(fontWeight: FontWeight.bold)),
  ...provider.urls.map((url) => ListTile(
        title: Text(url),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            int index = provider.urls.indexOf(url);
            Provider.of<PlaylistProvider>(context, listen: false)
                .removeUrl(index);
          },
        ),
      )),
],

ElevatedButton.icon(
  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
  label: const Text("Add PDF"),
  onPressed: () async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      Provider.of<PlaylistProvider>(context, listen: false).addPdf(file);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
    shadowColor: AppColors.shadow(context),
  ),
),

 SizedBox(height: height * 0.02),
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          hintText: 'Enter URL (YouTube etc)',
          hintStyle: TextStyle(color: AppColors.textSecondary(context)),
          filled: true,
          fillColor: AppColors.cardBackground(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(color: AppColors.textPrimary(context)),
        onSubmitted: (url) {
          if (url.isNotEmpty) {
            Provider.of<PlaylistProvider>(context, listen: false).addUrl(url);
            _urlController.clear(); 
            setState(() {}); 
          }
        },
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.add_link),
      color: AppColors.primary,
      onPressed: () {
        final url = _urlController.text.trim();
        if (url.isNotEmpty) {
          Provider.of<PlaylistProvider>(context, listen: false).addUrl(url);
          _urlController.clear(); 
          setState(() {}); 
        }
      },
      style: IconButton.styleFrom(
        backgroundColor: AppColors.cardBackground(context),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.border(context)),
        ),
      ),
    ),
  ],
),


            SizedBox(height: height * 0.02),
          SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.upload, color: Colors.white),
    label: const Text("Add to Playlist"),
    onPressed: () => _submit(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 2,
      shadowColor: AppColors.shadow(context),
    ),
  ),
),
             SizedBox(height: SizeConfig().scaleHeight(20, context)),
            const Text("Uploaded Videos:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             SizedBox(height: SizeConfig().scaleHeight(10, context)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.playlist.length,
              itemBuilder: (context, index) {
                final videoData = provider.playlist[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_fill, size: 32),
                    title: Text(videoData['title']),
                    subtitle: const Text("Video Selected"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        provider.removeVideo(index);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
