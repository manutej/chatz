import 'package:equatable/equatable.dart';

/// Represents the state of an upload operation
enum UploadStatus {
  idle,
  compressing,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Represents the progress of a file upload operation
class UploadProgress extends Equatable {
  final String uploadId;
  final UploadStatus status;
  final double progress; // 0.0 to 1.0
  final int bytesTransferred;
  final int totalBytes;
  final String? error;
  final String? downloadUrl;

  const UploadProgress({
    required this.uploadId,
    required this.status,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.error,
    this.downloadUrl,
  });

  /// Initial state
  factory UploadProgress.initial(String uploadId) {
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.idle,
    );
  }

  /// Compressing state
  factory UploadProgress.compressing(String uploadId) {
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.compressing,
    );
  }

  /// Uploading state
  factory UploadProgress.uploading(
    String uploadId, {
    required int bytesTransferred,
    required int totalBytes,
  }) {
    final progress = totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.uploading,
      progress: progress,
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
    );
  }

  /// Completed state
  factory UploadProgress.completed(
    String uploadId, {
    required String downloadUrl,
  }) {
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.completed,
      progress: 1.0,
      downloadUrl: downloadUrl,
    );
  }

  /// Failed state
  factory UploadProgress.failed(
    String uploadId, {
    required String error,
  }) {
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.failed,
      error: error,
    );
  }

  /// Cancelled state
  factory UploadProgress.cancelled(String uploadId) {
    return UploadProgress(
      uploadId: uploadId,
      status: UploadStatus.cancelled,
    );
  }

  /// Get percentage (0-100)
  int get percentage => (progress * 100).toInt();

  /// Check if upload is in progress
  bool get isInProgress =>
      status == UploadStatus.compressing || status == UploadStatus.uploading;

  /// Check if upload is completed
  bool get isCompleted => status == UploadStatus.completed;

  /// Check if upload failed
  bool get isFailed => status == UploadStatus.failed;

  /// Check if upload was cancelled
  bool get isCancelled => status == UploadStatus.cancelled;

  /// Get formatted progress string
  String get formattedProgress {
    if (totalBytes > 0) {
      final mbTransferred = (bytesTransferred / (1024 * 1024)).toStringAsFixed(1);
      final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mbTransferred MB / $mbTotal MB';
    }
    return '$percentage%';
  }

  @override
  List<Object?> get props => [
        uploadId,
        status,
        progress,
        bytesTransferred,
        totalBytes,
        error,
        downloadUrl,
      ];

  UploadProgress copyWith({
    String? uploadId,
    UploadStatus? status,
    double? progress,
    int? bytesTransferred,
    int? totalBytes,
    String? error,
    String? downloadUrl,
  }) {
    return UploadProgress(
      uploadId: uploadId ?? this.uploadId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
