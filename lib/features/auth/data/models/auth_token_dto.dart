import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

/// Login / register success payload.
final class AuthTokenDto extends Equatable {
  const AuthTokenDto({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final UserDto user;

  factory AuthTokenDto.fromJson(Map<String, dynamic> json) {
    final token = json[ApiJsonKeys.token];
    final tokenType = json[ApiJsonKeys.tokenType];
    final userRaw = json[ApiJsonKeys.user];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Invalid auth token');
    }
    if (tokenType is! String || tokenType.isEmpty) {
      throw const FormatException('Invalid token type');
    }
    if (userRaw is! Map) {
      throw const FormatException('Invalid auth user');
    }
    return AuthTokenDto(
      token: token,
      tokenType: tokenType,
      user: UserDto.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiJsonKeys.token: token,
      ApiJsonKeys.tokenType: tokenType,
      ApiJsonKeys.user: user.toJson(),
    };
  }

  @override
  List<Object?> get props => [token, tokenType, user];
}
