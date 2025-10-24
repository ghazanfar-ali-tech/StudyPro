import 'package:cloud_firestore/cloud_firestore.dart';

class VideoProgress {
  final String videoId;
  final String videoTitle;
  final String courseId;
  final String courseTitle;
  final DateTime watchedAt;
  final Duration watchedDuration;
  final Duration totalDuration;
  final double progressPercentage;
  final List<String> skillsLearned;

  VideoProgress({
    required this.videoId,
    required this.videoTitle,
    required this.courseId,
    required this.courseTitle,
    required this.watchedAt,
    required this.watchedDuration,
    required this.totalDuration,
    required this.progressPercentage,
    required this.skillsLearned,
  });

  factory VideoProgress.fromMap(Map<String, dynamic> map) {
    return VideoProgress(
      videoId: map['videoId'] ?? '',
      videoTitle: map['videoTitle'] ?? '',
      courseId: map['courseId'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      watchedAt: (map['watchedAt'] as Timestamp).toDate(),
      watchedDuration: Duration(seconds: map['watchedDuration'] ?? 0),
      totalDuration: Duration(seconds: map['totalDuration'] ?? 0),
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      skillsLearned: List<String>.from(map['skillsLearned'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoTitle': videoTitle,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'watchedAt': Timestamp.fromDate(watchedAt),
      'watchedDuration': watchedDuration.inSeconds,
      'totalDuration': totalDuration.inSeconds,
      'progressPercentage': progressPercentage,
      'skillsLearned': skillsLearned,
    };
  }
}