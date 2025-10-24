import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/providers/playlist_provider.dart';
import 'package:studypro/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studypro/views/Gemini_AI/constants.dart';

class CourseCreationScreen extends StatefulWidget {
  const CourseCreationScreen({super.key});

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  String? username;
  bool isUsernameLoaded = false;

  final TextEditingController _categoryController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Data Science',
    'Marketing',
    'Other',
  ];

  String? imageUrl;
  File? selectedImageFile;
  bool isUploading = false;
  double uploadProgress = 0.0;
  String uploadStatus = '';

  final QuillController _titleController = QuillController.basic(
    config: const QuillControllerConfig(),
  );
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final QuillController _descriptionController = QuillController.basic(
    config: const QuillControllerConfig(),
  );


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;



  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        username = 'anonymous_user';
        isUsernameLoaded = true;
      });
      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          username = snapshot.data()?['username'] ?? 'user_${user.uid.substring(0, 8)}';
          isUsernameLoaded = true;
        });
      } else {
        setState(() {
          username = 'user_${user.uid.substring(0, 8)}';
          isUsernameLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching username: $e");
      setState(() {
        username = 'user_${user?.uid.substring(0, 8) ?? 'unknown'}';
        isUsernameLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
  
    _descriptionController.dispose();
    _categoryController.dispose(); 
    super.dispose();
  }

  String get currentUserEmail => _auth.currentUser?.email ?? 'unknown_user';
  String get sanitizedUserEmail => currentUserEmail.replaceAll('@', '_').replaceAll('.', '_');

  String get safeUsername {
    if (!isUsernameLoaded || username == null || username!.isEmpty) {
      return sanitizedUserEmail.isNotEmpty ? sanitizedUserEmail : 'default_user';
    }
    return username!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      debugPrint("No image selected.");
      return;
    }

    setState(() {
      selectedImageFile = File(pickedFile.path);
      imageUrl = null;
    });
  }

  Future<String?> uploadFileToCloudinary(File file, String fileType, String fileName) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/${fileType == 'video' ? 'video' : 'image'}/upload");
    final courseId = DateTime.now().millisecondsSinceEpoch.toString();
    final userFolder = safeUsername;

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..fields["folder"] = "studypro_users/$userFolder/courses/$courseId"
      ..fields["public_id"] = "${fileType}_${fileName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}";

    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    debugPrint("Uploading $fileType to folder: studypro_users/$userFolder/courses/$courseId");

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = utf8.decode(responseData);
    final jsonMap = jsonDecode(responseString);

    if (response.statusCode == 200) {
      debugPrint("Upload successful: ${jsonMap["secure_url"]}");
      return jsonMap["secure_url"];
    } else {
      debugPrint("Upload failed: ${jsonMap['error']}");
      return null;
    }
  }

  Future<String?> uploadPdfToCloudinary(File file, String fileName, String courseId) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");
    final userFolder = safeUsername;

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..fields["folder"] = "studypro_users/$userFolder/courses/$courseId/pdfs"
      ..fields["public_id"] = "pdf_${fileName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}"
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    debugPrint("Uploading PDF to folder: studypro_users/$userFolder/courses/$courseId/pdfs");

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = utf8.decode(responseData);
    final jsonMap = jsonDecode(responseString);

    if (response.statusCode == 200) {
      debugPrint("PDF Upload successful: ${jsonMap["secure_url"]}");
      return jsonMap["secure_url"];
    } else {
      debugPrint("PDF Upload failed: ${jsonMap['error']}");
      return null;
    }
  }

  void _updateProgress(double progress, String status) {
    setState(() {
      uploadProgress = progress;
      uploadStatus = status;
    });
  }

  Future<void> uploadCourseData() async {
    if (!isUsernameLoaded) {
      _showSnackBar("Please wait, loading user data...");
      return;
    }

    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    final titleText = _titleController.document.toPlainText().trim();
    if (titleText.isEmpty || titleText == '\n') {
      _showSnackBar("Please enter course title");
      return;
    }

    if (_durationController.text.trim().isEmpty) {
      _showSnackBar("Please enter course duration");
      return;
    }

   

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showSnackBar("Please select a course category");
      return;
    }

    if (selectedImageFile == null) {
      _showSnackBar("Please select a course thumbnail");
      return;
    }

    if (provider.playlist.isEmpty) {
      _showSnackBar("Please add at least one video to the playlist");
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      final courseId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint("Creating course with ID: $courseId for user: $safeUsername");

      int totalTasks = 1; 
      for (var video in provider.playlist) {
        totalTasks++; 
        totalTasks += (video['pdfs'] as List<File>).length;
      }

      int completedTasks = 0;

      _updateProgress(completedTasks / totalTasks, "Uploading course thumbnail...");
      final thumbnailUrl = await uploadFileToCloudinary(
        selectedImageFile!,
        'image',
        'thumbnail_${titleText.replaceAll(' ', '_')}',
      );

      if (thumbnailUrl == null) {
        _showSnackBar("Failed to upload course thumbnail");
        setState(() => isUploading = false);
        return;
      }

      completedTasks++;
      _updateProgress(completedTasks / totalTasks, "Thumbnail uploaded successfully!");

      List<Map<String, dynamic>> processedPlaylist = [];

      for (int i = 0; i < provider.playlist.length; i++) {
        final videoData = provider.playlist[i];

        _updateProgress(completedTasks / totalTasks, "Uploading video ${i + 1}: ${videoData['title']}");
        final videoUrl = await uploadFileToCloudinary(
          videoData['video'] as File,
          'video',
          'video_${i + 1}_${(videoData['title'] as String).replaceAll(' ', '_')}',
        );

        if (videoUrl == null) {
          _showSnackBar("Failed to upload video: ${videoData['title']}");
          setState(() => isUploading = false);
          return;
        }

        completedTasks++;

        List<String> pdfUrls = [];
        final pdfs = videoData['pdfs'] as List<File>;

        for (int pdfIndex = 0; pdfIndex < pdfs.length; pdfIndex++) {
          _updateProgress(completedTasks / totalTasks, "Uploading PDF ${pdfIndex + 1} for video ${i + 1}...");
          final pdfFileName = pdfs[pdfIndex].path.split('/').last.replaceAll('.pdf', '');
          final pdfUrl = await uploadPdfToCloudinary(
            pdfs[pdfIndex],
            'video_${i + 1}_${pdfFileName}',
            courseId,
          );

          if (pdfUrl != null) {
            pdfUrls.add(pdfUrl);
          }

          completedTasks++;
        }

        processedPlaylist.add({
          'title': videoData['title'],
          'description': videoData['description'],
          'videoUrl': videoUrl,
          'pdfUrls': pdfUrls,
          'urls': videoData['urls'] as List<String>,
          'order': i,
          'videoDuration': videoData['videoDuration'],
        });

        _updateProgress(completedTasks / totalTasks, "Video ${i + 1} processed successfully!");
      }

      _updateProgress(0.95, "Saving course data...");

      final titleJson = _titleController.document.toDelta().toJson();
      final descriptionJson = _descriptionController.document.toDelta().toJson();
      final descriptionText = _descriptionController.document.toPlainText();

   
    

      final courseData = {
        'courseId': courseId,
        'title': titleText,
        'titleRich': titleJson,
        'duration': _durationController.text.trim(),
    
        'thumbnailUrl': thumbnailUrl,
        'description': descriptionText,
        'descriptionRich': descriptionJson,
        'category': _selectedCategory, 
        'playlist': processedPlaylist,
        'createdBy': currentUserEmail,
        'createdByUsername': username,
        'cloudinaryFolder': "studypro_users/$safeUsername/courses/$courseId",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'videoCount': processedPlaylist.length,
        'totalPdfs': processedPlaylist.fold(0, (sum, video) => sum + (video['pdfUrls'] as List).length),
        'totalUrls': processedPlaylist.fold(0, (sum, video) => sum + (video['urls'] as List).length),
      };

      await _firestore.collection('courses').add(courseData);

      _updateProgress(1.0, "Course uploaded successfully!");

      provider.clearAllData();
      _clearForm();

      _showSnackBar("Course uploaded successfully! 🎉");
    } catch (e) {
      debugPrint("Error uploading course: $e");
      _showSnackBar("Failed to upload course: ${e.toString()}");
    } finally {
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
        uploadStatus = '';
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _durationController.clear();
    _ratingController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    setState(() {
      selectedImageFile = null;
      imageUrl = null;
      _selectedCategory = null; 
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('success') || message.contains('🎉') ? Colors.green : Colors.red,
        duration: Duration(seconds: message.contains('🎉') ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Upload Course'),
        actions: [
          if (!isUsernameLoaded)
             Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: SizeConfig().scaleHeight(20, context),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: (isUploading || !isUsernameLoaded) ? null : pickImage,
                      child: Column(
                        children: [
                          Container(
                            width: SizeConfig().scaleWidth(160, context),
                            height: SizeConfig().scaleHeight(150, context),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: selectedImageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/upload_image.png',
                                        height: SizeConfig().scaleHeight(135, context),
                                        width: SizeConfig().scaleWidth(150, context),
                                      ),
                                    ],
                                  ),
                          ),
                           SizedBox(height: SizeConfig().scaleHeight(10, context)),
                          const Text(
                            "Tap to upload course thumbnail",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                     SizedBox(width: SizeConfig().scaleWidth(10, context)),
                    InkWell(
                      onTap: (isUploading || !isUsernameLoaded)
                          ? null
                          : () {
                              Navigator.pushNamed(context, AppRoutes.uploadPlaylist);
                            },
                      child: Column(
                        children: [
                          Container(
                            width: SizeConfig().scaleWidth(168, context),
                            height: SizeConfig().scaleHeight(150, context),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/upload_video.png',
                                    height: SizeConfig().scaleHeight(135, context),
                                    width: SizeConfig().scaleWidth(150, context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                           SizedBox(height: SizeConfig().scaleHeight(10, context)),
                          Text(
                            "Tap to manage videos (${provider.playlist.length} videos)",
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: SizeConfig().scaleHeight(10, context)),
                const Text(
                  "Course Title",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: _titleController,
                        config: QuillSimpleToolbarConfig(
                          showClipboardPaste: true,
                          embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                        ),
                      ),
                      Container(
                        height: SizeConfig().scaleHeight(80, context),
                        padding: const EdgeInsets.all(8),
                        child: QuillEditor(
                          controller: _titleController,
                          focusNode: FocusNode(),
                          scrollController: ScrollController(),
                          config: QuillEditorConfig(
                            placeholder: 'Enter course title...',
                            embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
                const Text(
                  "Course Category",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text("Select a category"),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (isUploading || !isUsernameLoaded)
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategory = value;
                            _categoryController.text = value ?? '';
                          });
                        },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
                const Text(
                  "Course Duration",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                TextField(
                  controller: _durationController,
                  enabled: !isUploading && isUsernameLoaded,
                  decoration: InputDecoration(
                    hintText: "e.g., 4 hours, 2 weeks, etc.",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(16, context)),
               
                const Text(
                  "Course Description",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(8, context)),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: _descriptionController,
                        config: QuillSimpleToolbarConfig(
                          showClipboardPaste: true,
                          embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                        ),
                      ),
                      Container(
                        height: SizeConfig().scaleHeight(200, context),
                        padding: const EdgeInsets.all(8),
                        child: QuillEditor(
                          controller: _descriptionController,
                          focusNode: FocusNode(),
                          scrollController: ScrollController(),
                          config: QuillEditorConfig(
                            placeholder: 'Enter course description...',
                            embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(32, context)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (isUploading || !isUsernameLoaded) ? null : uploadCourseData,
                    icon: isUploading
                        ?  SizedBox(
                            width: SizeConfig().scaleWidth(20, context),
                            height: SizeConfig().scaleHeight(20, context),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload_rounded, color: Colors.white),
                    label: Text(
                      !isUsernameLoaded
                          ? "Loading user data..."
                          : isUploading
                              ? "Uploading..."
                              : "Upload Course",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isUploading || !isUsernameLoaded) ? Colors.grey : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                 SizedBox(height: SizeConfig().scaleHeight(80, context)),
              ],
            ),
          ),
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Uploading Course",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (username != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "User: $username",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                         SizedBox(height: SizeConfig().scaleHeight(20, context)),
                        CircularProgressIndicator(
                          value: uploadProgress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                         SizedBox(height: SizeConfig().scaleHeight(16, context)),
                        Text(
                          "${(uploadProgress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                         SizedBox(height: SizeConfig().scaleHeight(12, context)),
                        Text(
                          uploadStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                         SizedBox(height: SizeConfig().scaleHeight(20, context)),
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}