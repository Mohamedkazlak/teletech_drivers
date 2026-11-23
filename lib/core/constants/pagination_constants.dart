/// Caps for client-side page aggregation of paginated list endpoints.
abstract final class PaginationConstants {
  /// Maximum pages fetched by [fetchAllPages] before stopping.
  static const maxPages = 50;

  /// Default page size requested from the API.
  static const defaultPerPage = 100;
}
