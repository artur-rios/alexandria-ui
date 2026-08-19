// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibrarySource _$LibrarySourceFromJson(Map<String, dynamic> json) =>
    _LibrarySource(
      path: json['path'] as String,
      label: json['label'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      lastRunId: json['lastRunId'] as String?,
      lastRunOutcome: json['lastRunOutcome'] as String?,
      lastRunAt: json['lastRunAt'] == null
          ? null
          : DateTime.parse(json['lastRunAt'] as String),
    );

Map<String, dynamic> _$LibrarySourceToJson(_LibrarySource instance) =>
    <String, dynamic>{
      'path': instance.path,
      'label': instance.label,
      'registeredAt': instance.registeredAt.toIso8601String(),
      'lastRunId': instance.lastRunId,
      'lastRunOutcome': instance.lastRunOutcome,
      'lastRunAt': instance.lastRunAt?.toIso8601String(),
    };
