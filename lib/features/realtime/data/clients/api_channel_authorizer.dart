import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';

/// Authorizes a private channel with the signed-in bearer token.
final class ApiChannelAuthorizer
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
          PrivateChannelAuthorizationData
        > {
  ApiChannelAuthorizer(this._api);

  final ApiClient _api;

  @override
  EndpointAuthFailedCallback? onAuthFailed;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    final response = await _api.post(
      ApiPaths.broadcastingAuth,
      data: {'socket_id': socketId, 'channel_name': channelName},
    );
    final body = response.data;
    final auth = body is Map ? body['auth'] : null;
    if (auth is! String || auth.isEmpty) {
      throw StateError('Channel authorization did not return a signature.');
    }
    return PrivateChannelAuthorizationData(authKey: auth);
  }
}
