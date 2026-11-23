import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';

/// API notification JSON (`NotificationResource`).
final class NotificationDto extends Equatable {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.params,
    required this.createdAt,
    this.tripRequestId,
    this.tripId,
    this.readAt,
  });

  final String id;
  final String type;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> params;
  final DateTime createdAt;
  final String? tripRequestId;
  final String? tripId;
  final DateTime? readAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: ApiJsonParsers.requireNonEmptyString(json[ApiJsonKeys.id], 'id'),
      type: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.type],
        'type',
      ),
      titleKey: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.titleKey],
        'title_key',
      ),
      bodyKey: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.bodyKey],
        'body_key',
      ),
      params: _params(json[ApiJsonKeys.params]),
      tripRequestId: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.tripRequestId],
      ),
      tripId: ApiJsonParsers.optionalString(json[ApiJsonKeys.tripId]),
      readAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.readAt]),
      createdAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.createdAt],
        'created_at',
      ),
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      type: AppNotificationType.fromWire(type),
      titleKey: titleKey,
      bodyKey: bodyKey,
      params: params,
      createdAt: createdAt,
      tripRequestId: tripRequestId,
      tripId: tripId,
      readAt: readAt,
    );
  }

  static Map<String, String> _params(Object? value) {
    if (value is! Map) return const {};
    final params = <String, String>{};
    value.forEach((key, item) {
      if (key is! String || item == null) return;
      final text = item.toString().trim();
      if (text.isEmpty) return;
      params[key] = text;
    });
    return params;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    titleKey,
    bodyKey,
    params,
    createdAt,
    tripRequestId,
    tripId,
    readAt,
  ];
}
