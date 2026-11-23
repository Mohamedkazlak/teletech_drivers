import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';

/// A push payload. The system notification is already shown when the app
/// is in the background; this carries the data used to open the right screen.
final class PushMessage extends Equatable {
  const PushMessage({
    required this.notificationId,
    required this.type,
    this.tripId,
    this.tripRequestId,
    this.title,
    this.body,
  });

  final String notificationId;
  final AppNotificationType type;
  final String? tripId;
  final String? tripRequestId;
  final String? title;
  final String? body;

  static PushMessage? fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final id = _text(data[ApiJsonKeys.notificationId]);
    if (id == null) return null;
    return PushMessage(
      notificationId: id,
      type: AppNotificationType.fromWire(_text(data[ApiJsonKeys.type]) ?? ''),
      tripId: _text(data[ApiJsonKeys.tripId]),
      tripRequestId: _text(data[ApiJsonKeys.tripRequestId]),
      title: _optional(title),
      body: _optional(body),
    );
  }

  static PushMessage? fromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      return fromData(
        data,
        title: _text(data['title']),
        body: _text(data['body']),
      );
    } on FormatException {
      return null;
    }
  }

  String encode() {
    return jsonEncode({
      ApiJsonKeys.notificationId: notificationId,
      ApiJsonKeys.type: type.wireValue,
      ApiJsonKeys.tripId: tripId ?? '',
      ApiJsonKeys.tripRequestId: tripRequestId ?? '',
      'title': title ?? '',
      'body': body ?? '',
    });
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _optional(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  List<Object?> get props => [
    notificationId,
    type,
    tripId,
    tripRequestId,
    title,
    body,
  ];
}
