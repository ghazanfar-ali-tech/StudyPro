import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Course {
  final String courseId;
  final String title;
  final String duration;
  final double rating;
  final String thumbnailUrl;
  final String description;
  final List<dynamic>? descriptionRich;
  final List<dynamic>? titleRich;
  final String category;
  final List<VideoData> playlist;
  final String createdBy;
  final String createdByUsername;
  final DateTime createdAt;
  final int videoCount;
  final int totalPdfs;
  final int totalUrls;
  final int reviewCount;
  final List<VideoData> videos;

  Course({
    required this.courseId,
    required this.title,
    required this.duration,
    required this.rating,
    required this.thumbnailUrl,
    required this.description,
    this.descriptionRich,
    this.titleRich,
    required this.category,
    required this.playlist,
    required this.createdBy,
    required this.createdByUsername,
    required this.createdAt,
    required this.videoCount,
    required this.totalPdfs,
    required this.totalUrls,
    this.reviewCount = 0,
    required this.videos,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      description: json['description'] ?? '',
      descriptionRich: json['descriptionRich'] != null
          ? List<dynamic>.from(json['descriptionRich'])
          : null,
      titleRich: json['titleRich'] != null
          ? List<dynamic>.from(json['titleRich'])
          : null,
      category: json['category'] ?? 'Other',
      playlist: (json['playlist'] as List<dynamic>? ?? [])
          .map((video) => VideoData.fromJson(video))
          .toList(),
      createdBy: json['createdBy'] ?? '',
      createdByUsername: json['createdByUsername'] ?? 'Unknown',
      createdAt: _parseCreatedAt(json['createdAt']),
      videoCount: json['videoCount'] ?? 0,
      totalPdfs: json['totalPdfs'] ?? 0,
      totalUrls: json['totalUrls'] ?? 0,
      reviewCount: json['reviewCount'] ?? 25,
      videos: (json['videos'] as List<dynamic>?)
              ?.map((v) => VideoData.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DateTime _parseCreatedAt(dynamic createdAt) {
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    } else if (createdAt is String) {
      try {
        return DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing createdAt string: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
class VideoData {
  final String title;
  final String description;
  final String videoUrl;
  final List<String> pdfUrls;
  final List<String> urls;
  final int order;
  final String duration;
  final String videoDuration;

  VideoData({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.pdfUrls,
    required this.urls,
    required this.order,
    this.duration = '0 hours',
    this.videoDuration = '00:00',
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      pdfUrls: List<String>.from(json['pdfUrls'] ?? []),
      urls: List<String>.from(json['urls'] ?? []),
      order: json['order'] ?? 0,
      duration: json['duration'] ?? '0 hours',
      videoDuration: json['videoDuration'] ?? '00:00',
    );
  }
}