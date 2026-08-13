// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalLoginResult _$LocalLoginResultFromJson(Map<String, dynamic> json) =>
    LocalLoginResult(
      success: json['success'] as bool,
      sessionId: json['sessionId'] as String,
      emailConfirmed: json['emailConfirmed'] as bool? ?? true,
    );
