import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';
part 'photo.g.dart';

@freezed
abstract class Photo with _$Photo {
  const factory Photo({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'suggestion_id') String? suggestionId,
    @JsonKey(name: 'uploaded_by') required String uploadedBy,
    @JsonKey(name: 'uploader_name') required String uploaderName,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    String? caption,
    @Default({}) Map<String, List<String>> reactions,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}
