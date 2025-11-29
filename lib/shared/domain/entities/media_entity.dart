import 'package:equatable/equatable.dart';

/// Represents different types of media that can be uploaded/downloaded
enum MediaType {
  image,
  video,
  audio,
  document,
  voice,
  gif,
}

/// Extension to get MIME type from MediaType
extension MediaTypeExtension on MediaType {
  String get mimeTypePrefix {
    switch (this) {
      case MediaType.image:
      case MediaType.gif:
        return 'image';
      case MediaType.video:
        return 'video';
      case MediaType.audio:
      case MediaType.voice:
        return 'audio';
      case MediaType.document:
        return 'application';
    }
  }
}

/// Represents media file information
class MediaEntity extends Equatable {
  final String id;
  final MediaType type;
  final String url;
  final String? localPath;
  final int sizeInBytes;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? durationInSeconds;
  final String? thumbnailUrl;
  final DateTime uploadedAt;

  const MediaEntity({
    required this.id,
    required this.type,
    required this.url,
    this.localPath,
    required this.sizeInBytes,
    this.mimeType,
    this.width,
    this.height,
    this.durationInSeconds,
    this.thumbnailUrl,
    required this.uploadedAt,
  });

  /// Check if media has dimensions (image or video)
  bool get hasDimensions => width != null && height != null;

  /// Check if media has duration (audio or video)
  bool get hasDuration => durationInSeconds != null;

  /// Get human-readable file size
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get aspect ratio if dimensions available
  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        url,
        localPath,
        sizeInBytes,
        mimeType,
        width,
        height,
        durationInSeconds,
        thumbnailUrl,
        uploadedAt,
      ];

  MediaEntity copyWith({
    String? id,
    MediaType? type,
    String? url,
    String? localPath,
    int? sizeInBytes,
    String? mimeType,
    int? width,
    int? height,
    int? durationInSeconds,
    String? thumbnailUrl,
    DateTime? uploadedAt,
  }) {
    return MediaEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
