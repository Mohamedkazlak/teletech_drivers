import 'package:dio/dio.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/core/network/paginated_response.dart';
import 'package:teletech_drivers/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:teletech_drivers/features/notification/data/models/notification_dto.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';

/// Laravel implementation of [NotificationRemoteDataSource].
class ApiNotificationRemoteDataSource implements NotificationRemoteDataSource {
  const ApiNotificationRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<NotificationPage> list({
    required int perPage,
    CancelToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      ApiPaths.notifications,
      queryParameters: {ApiJsonKeys.perPage: perPage, ApiJsonKeys.page: 1},
      cancelToken: cancelToken,
    );
    final page = PaginatedResponse.fromJson(
      ApiJsonParsers.requireMap(response.data),
      NotificationDto.fromJson,
    );
    return NotificationPage(
      items: [for (final dto in page.data) dto.toEntity()],
      total: page.total,
    );
  }

  @override
  Future<int> unreadCount({CancelToken? cancelToken}) async {
    final response = await apiClient.get(
      ApiPaths.notificationsUnreadCount,
      cancelToken: cancelToken,
    );
    final json = ApiJsonParsers.requireMap(response.data);
    return ApiJsonParsers.requireInt(json[ApiJsonKeys.count], 'count');
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final response = await apiClient.post(ApiPaths.notificationRead(id));
    return NotificationDto.fromJson(ApiJsonParsers.requireMap(response.data))
        .toEntity();
  }

  @override
  Future<int> markAllRead() async {
    final response = await apiClient.post(ApiPaths.notificationsReadAll);
    final json = ApiJsonParsers.requireMap(response.data);
    return ApiJsonParsers.requireInt(json[ApiJsonKeys.updated], 'updated');
  }
}
