import 'dart:io';
import 'package:flutter/material.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _playlist = [];

  File? _selectedVideo;
  String _title = '';
  String _videoDuration = '';
  String _description = '';
  List<File> _pdfs = [];
  List<File> _images = [];
  List<String> _urls = [];

  List<Map<String, dynamic>> get playlist => _playlist;
  File? get selectedVideo => _selectedVideo;
  String get title => _title;
  String get videoDuration => _videoDuration;
  String get description => _description;
  List<File> get pdfs => _pdfs;
  List<File> get images => _images;
  List<String> get urls => _urls;

  void setVideo(File video) {
    _selectedVideo = video;
    notifyListeners();
  }

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }
  void setVideoDuration(String duration) {
    _videoDuration = duration;
    notifyListeners();
  }

  void setDescription(String desc) {
    _description = desc;
    notifyListeners();
  }

  void addPdf(File pdf) {
    _pdfs.add(pdf);
    notifyListeners();
  }

  void addImage(File image) {
    _images.add(image);
    notifyListeners();
  }

  void addUrl(String url) {
    _urls.add(url);
    notifyListeners();
  }

  void removePdf(int index) {
    if (index >= 0 && index < _pdfs.length) {
      _pdfs.removeAt(index);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  void removeUrl(int index) {
    if (index >= 0 && index < _urls.length) {
      _urls.removeAt(index);
      notifyListeners();
    }
  }

  void addVideoToPlaylist() {
    if (_selectedVideo != null && _title.isNotEmpty) {
      _playlist.add({
        'video': _selectedVideo!,
        'title': _title,
        'description': _description,
        'pdfs': List<File>.from(_pdfs),
        'images': List<File>.from(_images),
        'urls': List<String>.from(_urls),
        'videoDuration': _videoDuration,
      });

      _clearCurrentVideo();
    }
  }

  void removeVideo(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      notifyListeners();
    }
  }

  void _clearCurrentVideo() {
    _selectedVideo = null;
    _title = '';
    _description = '';
    _pdfs = [];
    _images = [];
    _urls = [];
    notifyListeners();
  }

  void clearAllData() {
    _playlist.clear();
    _clearCurrentVideo();
  }

  int getTotalFilesCount() {
    int count = _playlist.length; 
    for (var video in _playlist) {
      count += (video['pdfs'] as List<File>).length; 
    }
    return count;
  }

  Map<String, int> getPlaylistSummary() {
    int totalVideos = _playlist.length;
    int totalPdfs = 0;
    int totalUrls = 0;

    for (var video in _playlist) {
      totalPdfs += (video['pdfs'] as List<File>).length;
      totalUrls += (video['urls'] as List<String>).length;
    }

    return {
      'videos': totalVideos,
      'pdfs': totalPdfs,
      'urls': totalUrls,
    };
  }
}