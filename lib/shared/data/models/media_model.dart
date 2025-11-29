import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/media_entity.dart';

part 'media_model.freezed.dart';
part 'media_model.g.dart';

@freezed
class MediaModel with _$MediaModel {
  const factory MediaModel({
    required String id,
    required String type,
    required String url,
    String? localPath,
    required int sizeInBytes,
    String? mimeType,
    int? width,
    int? height,
    int? durationInSeconds,
    String? thumbnailUrl,
    required DateTime uploadedAt,
  }) = _MediaModel;

  const MediaModel._();

  factory MediaModel.fromJson(Map<String, dynamic> json) =>
      _$MediaModelFromJson(json);

  /// Convert to domain entity
  MediaEntity toEntity() {
    return MediaEntity(
      id: id,
      type: _parseMediaType(type),
      url: url,
      localPath: localPath,
      sizeInBytes: sizeInBytes,
      mimeType: mimeType,
      width: width,
      height: height,
      durationInSeconds: durationInSeconds,
      thumbnailUrl: thumbnailUrl,
      uploadedAt: uploadedAt,
    );
  }

  /// Create from domain entity
  factory MediaModel.fromEntity(MediaEntity entity) {
    return MediaModel(
      id: entity.id,
      type: entity.type.name,
      url: entity.url,
      localPath: entity.localPath,
      sizeInBytes: entity.sizeInBytes,
      mimeType: entity.mimeType,
      width: entity.width,
      height: entity.height,
      durationInSeconds: entity.durationInSeconds,
      thumbnailUrl: entity.thumbnailUrl,
      uploadedAt: entity.uploadedAt,
    );
  }

  /// Parse media type from string
  static MediaType _parseMediaType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      case 'document':
        return MediaType.document;
      case 'voice':
        return MediaType.voice;
      case 'gif':
        return MediaType.gif;
      default:
        return MediaType.document;
    }
  }
}
