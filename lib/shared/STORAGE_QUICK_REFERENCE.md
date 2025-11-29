# Firebase Storage Quick Reference

Quick reference for using the storage services in Chatz.

## Import Required Services

```dart
import 'package:chatz/core/di/injection.dart';
import 'package:chatz/shared/services/storage_service.dart';
import 'package:chatz/shared/data/datasources/storage_remote_data_source.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';
import 'package:chatz/shared/domain/usecases/upload_file_usecase.dart';
import 'package:chatz/shared/domain/usecases/pick_media_usecase.dart';
```

## Common Operations

### 1. Pick and Upload Profile Image

```dart
// Pick image
final picker = sl<PickImageFromGalleryUseCase>();
final file = await picker(imageQuality: 85);

if (file != null) {
  // Upload
  final dataSource = sl<StorageRemoteDataSource>();

  await for (final progress in dataSource.uploadProfileImage(
    imageFile: file,
    userId: currentUserId,
    compress: true,
  )) {
    if (progress.isCompleted) {
      final url = progress.downloadUrl!;
      // Save URL to user profile in Firestore
    }
  }
}
```

### 2. Upload Chat Image

```dart
final dataSource = sl<StorageRemoteDataSource>();

await for (final progress in dataSource.uploadChatImage(
  imageFile: imageFile,
  chatId: chatId,
  messageId: messageId,
  compress: true,
)) {
  // Update UI with progress
  setState(() {
    uploadProgress = progress.percentage;
  });

  if (progress.isCompleted) {
    // Save message with image URL
    await saveMessage(
      chatId: chatId,
      messageId: messageId,
      imageUrl: progress.downloadUrl!,
    );
  }
}
```

### 3. Upload Video with Thumbnail

```dart
final dataSource = sl<StorageRemoteDataSource>();

await for (final progress in dataSource.uploadChatVideo(
  videoFile: videoFile,
  chatId: chatId,
  messageId: messageId,
  compress: true,
  generateThumbnail: true,
)) {
  if (progress.isCompleted) {
    final videoUrl = progress.downloadUrl!;

    // Get thumbnail URL
    final thumbPath = StorageService.getVideoThumbnailPath(
      StorageService.getChatVideoPath(chatId, messageId),
    );
    final thumbUrl = await dataSource.getDownloadUrl(thumbPath);

    // Save message with both URLs
    await saveMessage(
      chatId: chatId,
      messageId: messageId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbUrl,
    );
  }
}
```

### 4. Upload Audio Message

```dart
final dataSource = sl<StorageRemoteDataSource>();

await for (final progress in dataSource.uploadChatAudio(
  audioFile: audioFile,
  chatId: chatId,
  messageId: messageId,
)) {
  if (progress.isCompleted) {
    await saveMessage(
      chatId: chatId,
      messageId: messageId,
      audioUrl: progress.downloadUrl!,
    );
  }
}
```

### 5. Upload Document

```dart
final dataSource = sl<StorageRemoteDataSource>();

await for (final progress in dataSource.uploadChatDocument(
  documentFile: documentFile,
  chatId: chatId,
  messageId: messageId,
  fileName: 'report.pdf',
)) {
  if (progress.isCompleted) {
    await saveMessage(
      chatId: chatId,
      messageId: messageId,
      documentUrl: progress.downloadUrl!,
      fileName: 'report.pdf',
    );
  }
}
```

### 6. Delete Chat Media

```dart
final dataSource = sl<StorageRemoteDataSource>();

// Delete image
await dataSource.deleteChatMedia(
  chatId: chatId,
  messageId: messageId,
  mediaType: MediaType.image,
  fileName: null,
);

// Delete video (also deletes thumbnail automatically)
await dataSource.deleteChatMedia(
  chatId: chatId,
  messageId: messageId,
  mediaType: MediaType.video,
  fileName: null,
);

// Delete document
await dataSource.deleteChatMedia(
  chatId: chatId,
  messageId: messageId,
  mediaType: MediaType.document,
  fileName: 'report.pdf',
);
```

### 7. Pick Multiple Images

```dart
final picker = sl<PickMultipleImagesUseCase>();

final images = await picker(
  imageQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
  limit: 10,
);

// Upload all images
for (final image in images) {
  // Upload each image...
}
```

### 8. Capture from Camera

```dart
final picker = sl<PickImageFromCameraUseCase>();

final photo = await picker(
  imageQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
);

if (photo != null) {
  // Upload photo...
}
```

### 9. Record Video

```dart
final picker = sl<RecordVideoWithCameraUseCase>();

final video = await picker(
  maxDuration: Duration(minutes: 2),
);

if (video != null) {
  // Upload video...
}
```

### 10. Manual Compression

```dart
final compressionService = sl<FileCompressionService>();

// Compress image
final compressed = await compressionService.compressImage(
  imageFile,
  quality: 85,
  maxWidth: 1920,
);

// Compress video
final compressedVideo = await compressionService.compressVideo(
  videoFile,
  quality: VideoQuality.MediumQuality,
);

// Generate thumbnail
final thumbnail = await compressionService.generateVideoThumbnail(
  videoFile,
  timeMs: 1000, // 1 second
);
```

## Storage Paths

Use StorageService static helpers to generate consistent paths:

```dart
// Profile image
final path = StorageService.getProfileImagePath(userId);
// Result: profile_images/{userId}/avatar.jpg

// Chat image
final path = StorageService.getChatImagePath(chatId, messageId);
// Result: chat_media/{chatId}/images/{messageId}.jpg

// Chat video
final path = StorageService.getChatVideoPath(chatId, messageId);
// Result: chat_media/{chatId}/videos/{messageId}.mp4

// Video thumbnail
final thumbPath = StorageService.getVideoThumbnailPath(videoPath);
// Result: chat_media/{chatId}/videos/{messageId}_thumb.jpg

// Chat audio
final path = StorageService.getChatAudioPath(chatId, messageId);
// Result: chat_media/{chatId}/audio/{messageId}.m4a

// Chat document
final path = StorageService.getChatDocumentPath(chatId, messageId, 'file.pdf');
// Result: chat_media/{chatId}/documents/{messageId}.pdf

// Status media
final path = StorageService.getStatusMediaPath(userId, statusId);
// Result: status_media/{userId}/{statusId}.jpg
```

## Progress States

```dart
await for (final progress in uploadStream) {
  switch (progress.status) {
    case UploadStatus.idle:
      // Not started
      break;
    case UploadStatus.compressing:
      // Compressing file before upload
      showMessage('Compressing...');
      break;
    case UploadStatus.uploading:
      // Uploading to Firebase
      updateProgress(progress.percentage);
      showMessage('Uploading: ${progress.percentage}%');
      break;
    case UploadStatus.completed:
      // Upload complete
      final url = progress.downloadUrl!;
      showMessage('Upload complete!');
      break;
    case UploadStatus.failed:
      // Upload failed
      showError(progress.error!);
      break;
    case UploadStatus.cancelled:
      // Upload cancelled
      showMessage('Upload cancelled');
      break;
  }
}
```

## Error Handling

```dart
final uploadUseCase = sl<UploadFileUseCase>();

await for (final result in uploadUseCase(params)) {
  result.fold(
    // Error
    (failure) {
      if (failure is NetworkFailure) {
        showError('No internet connection');
      } else if (failure is PermissionFailure) {
        showError('Permission denied. Please grant access.');
      } else if (failure is MediaUploadFailure) {
        showError('Upload failed: ${failure.message}');
      }
    },
    // Success
    (progress) {
      if (progress.isCompleted) {
        showSuccess('Upload complete!');
      }
    },
  );
}
```

## Permission Handling

```dart
final picker = sl<ImagePickerService>();

// Check permission
final hasPermission = await picker.isGalleryPermissionGranted();

if (!hasPermission) {
  // Request permission
  // Permission is requested automatically on first pick
  final image = await picker.pickImageFromGallery();

  if (image == null) {
    // User denied or permission not granted
    showDialog(
      // ... ask user to grant permission
      onOk: () => picker.openAppSettings(),
    );
  }
}
```

## Display Images

Use cached_network_image for efficient display:

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: downloadUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
)
```

## Get User Storage Size

```dart
final repository = sl<StorageRepository>();

final result = await repository.getUserStorageSize(userId: currentUserId);

result.fold(
  (failure) => showError(failure.message),
  (bytes) {
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
    showMessage('You are using $mb MB of storage');
  },
);
```

## Best Practices

1. **Always compress media before upload** (compress: true)
2. **Generate thumbnails for videos** (generateThumbnail: true)
3. **Use path helpers** instead of hardcoding paths
4. **Handle all progress states** in UI
5. **Show upload progress** to users
6. **Handle errors gracefully** with user-friendly messages
7. **Request permissions** before picking media
8. **Use cached_network_image** for displaying images
9. **Delete media** when messages are deleted
10. **Track storage usage** to warn users

## Compression Settings

Default settings (can be customized):

```dart
// Image compression
quality: 85,              // 85% quality
maxDimension: 1920,       // Max 1920px width/height
thumbnailSize: 300,       // 300x300 thumbnails

// Video compression
quality: VideoQuality.MediumQuality,  // 720p
autoCompress: true,       // Compress if >50MB

// Auto-compression thresholds
imageThreshold: 1MB,      // Compress images >1MB
videoThreshold: 50MB,     // Compress videos >50MB
```

## Need Help?

See full documentation: `/docs/FIREBASE_STORAGE.md`
