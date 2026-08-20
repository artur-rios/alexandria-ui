// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_register_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalRegisterResult _$LocalRegisterResultFromJson(Map<String, dynamic> json) =>
    LocalRegisterResult(
      success: json['success'] as bool,
      email: json['email'] as String,
      sessionId: json['sessionId'] as String,
      recoveryCodes:
          (json['recoveryCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
