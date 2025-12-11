import '../models/api_response.dart';
import '../models/frequency_model.dart';
import 'package:harborleaf_radio_app/shared/constants/api_endpoints.dart';
import 'package:harborleaf_radio_app/shared/services/http_client.dart';

class FrequencyRepository {
  final HttpClient _httpClient = HttpClient();

  // Cache for frequently accessed data
  static final Map<String, _CacheEntry<List<FrequencyModel>>> _frequencyCache =
      {};
  static final Map<String, _CacheEntry<FrequencyModel>> _singleFrequencyCache =
      {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Clear cache when needed (e.g., after join/leave/create/delete)
  void clearCache() {
    _frequencyCache.clear();
    _singleFrequencyCache.clear();
    print('🗑️ Frequency cache cleared');
  }

  Future<ApiResponse<List<FrequencyModel>>> getAllFrequencies({
    int page = 1,
    int limit = 50,
    String? band,
    bool? isPublic,
    String? search,
    double? minFrequency,
    double? maxFrequency,
    bool? hasActiveUsers, // NEW: Filter for active frequencies
    bool forceRefresh = false, // Force refresh to bypass cache
  }) async {
    try {
      print('🔍 Step 1: Building query parameters...');
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (band != null) 'band': band,
        if (isPublic != null) 'isPublic': isPublic,
        if (search != null) 'search': search,
        if (minFrequency != null) 'minFrequency': minFrequency,
        if (maxFrequency != null) 'maxFrequency': maxFrequency,
        if (hasActiveUsers != null) 'hasActiveUsers': hasActiveUsers, // NEW
      };
      print('📋 Query params: $queryParams');

      final url = _buildUrl(ApiEndpoints.frequencies, queryParams);
      print('🌐 Step 2: URL built: $url');

      // Check cache if not forcing refresh
      if (!forceRefresh) {
        final cached = _frequencyCache[url];
        if (cached != null && !cached.isExpired) {
          print('✅ Returning cached frequencies (${cached.data.length} items)');
          return ApiResponse(
            success: true,
            data: cached.data,
            message: 'Frequencies loaded from cache',
          );
        }
      }

      final response = await _httpClient.get<List<FrequencyModel>>(
        url,
        fromJson: (json) {
          print('🔧 Step 3: Processing JSON response...');
          print('📦 Raw JSON type: ${json.runtimeType}');
          print('📦 Raw JSON: $json');

          // Backend returns: {frequencies: [...], pagination: {...}}
          // We need to extract the frequencies array
          if (json is Map<String, dynamic>) {
            print('✅ JSON is Map, extracting frequencies...');
            final frequenciesData = json['frequencies'];
            print('📊 Frequencies data type: ${frequenciesData?.runtimeType}');
            print('📊 Frequencies count: ${frequenciesData?.length ?? 0}');

            if (frequenciesData is List) {
              print('✅ Converting ${frequenciesData.length} frequencies...');
              final result = frequenciesData
                  .map((item) => FrequencyModel.fromJson(item))
                  .toList();
              print('✅ Conversion complete: ${result.length} frequencies');
              return result;
            }
          }

          print('❌ Unexpected JSON structure');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Step 4: Response received successfully');

      // Cache the result
      if (response.success && response.data != null) {
        _frequencyCache[url] = _CacheEntry(response.data!);
        print('💾 Cached ${response.data!.length} frequencies');
      }

      return response;
    } catch (e) {
      print('❌ Error in getAllFrequencies: $e');
      rethrow;
    }
  }

  Future<ApiResponse<List<FrequencyModel>>> getPopularFrequencies({
    int limit = 10,
  }) async {
    try {
      print('🔍 Loading popular frequencies (limit: $limit)...');
      final url = _buildUrl(ApiEndpoints.popularFrequencies, {'limit': limit});

      final response = await _httpClient.get<List<FrequencyModel>>(
        url,
        fromJson: (json) {
          print('🔧 Processing popular frequencies JSON...');
          print('📦 Raw JSON type: ${json.runtimeType}');

          if (json is Map<String, dynamic>) {
            final frequenciesData = json['frequencies'];
            if (frequenciesData is List) {
              print(
                '✅ Converting ${frequenciesData.length} popular frequencies...',
              );
              return frequenciesData
                  .map((item) => FrequencyModel.fromJson(item))
                  .toList();
            }
          }

          print('❌ Unexpected JSON structure for popular frequencies');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Popular frequencies loaded');
      return response;
    } catch (e) {
      print('❌ Error in getPopularFrequencies: $e');
      rethrow;
    }
  }

  Future<ApiResponse<List<FrequencyModel>>> getFrequenciesByBand(
    String band,
  ) async {
    try {
      print('🔍 Loading frequencies by band: $band...');
      final response = await _httpClient.get<List<FrequencyModel>>(
        ApiEndpoints.frequenciesByBand(band),
        fromJson: (json) {
          print('🔧 Processing frequencies by band JSON...');
          print('📦 Raw JSON type: ${json.runtimeType}');

          if (json is Map<String, dynamic>) {
            final frequenciesData = json['frequencies'];
            if (frequenciesData is List) {
              print(
                '✅ Converting ${frequenciesData.length} frequencies for band $band...',
              );
              return frequenciesData
                  .map((item) => FrequencyModel.fromJson(item))
                  .toList();
            }
          }

          print('❌ Unexpected JSON structure for frequencies by band');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Frequencies by band loaded');
      return response;
    } catch (e) {
      print('❌ Error in getFrequenciesByBand: $e');
      rethrow;
    }
  }

  Future<ApiResponse<FrequencyModel>> getFrequencyById(String id) async {
    try {
      final response = await _httpClient.get<FrequencyModel>(
        ApiEndpoints.frequencyById(id),
        fromJson: (json) => FrequencyModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<FrequencyModel>> createFrequency({
    required String name,
    required String frequency,
    required String band,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final response = await _httpClient.post<FrequencyModel>(
        ApiEndpoints.frequencies,
        body: {
          'name': name,
          'frequency': frequency,
          'band': band,
          if (description != null) 'description': description,
          'isPublic': isPublic,
        },
        fromJson: (json) => FrequencyModel.fromJson(json),
      );

      // Clear cache to force refresh
      clearCache();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<FrequencyModel>> joinFrequency(String id) async {
    try {
      final response = await _httpClient.post<FrequencyModel>(
        ApiEndpoints.joinFrequency(id),
        body: {},
        fromJson: (json) => FrequencyModel.fromJson(json),
      );

      // Clear cache to force refresh
      clearCache();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<FrequencyModel>> leaveFrequency(String id) async {
    try {
      final response = await _httpClient.post<FrequencyModel>(
        ApiEndpoints.leaveFrequency(id),
        body: {},
        fromJson: (json) => FrequencyModel.fromJson(json),
      );

      // Clear cache to force refresh
      clearCache();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<FrequencyModel>> updateFrequency(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final response = await _httpClient.put<FrequencyModel>(
        ApiEndpoints.frequencyById(id),
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (isPublic != null) 'isPublic': isPublic,
        },
        fromJson: (json) => FrequencyModel.fromJson(json),
      );

      // Clear cache to force refresh
      clearCache();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<void>> deleteFrequency(String id) async {
    try {
      final response = await _httpClient.delete<void>(
        ApiEndpoints.frequencyById(id),
        fromJson: (json) => null,
      );

      // Clear cache to force refresh
      clearCache();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getFrequencyStats(String id) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        ApiEndpoints.frequencyStats(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<List<FrequencyModel>>> searchFrequencies(
    String query,
  ) async {
    try {
      print('🔍 Searching frequencies with query: $query');
      final url = _buildUrl(ApiEndpoints.searchFrequencies, {'q': query});

      final response = await _httpClient.get<List<FrequencyModel>>(
        url,
        fromJson: (json) {
          print('🔧 Processing search frequencies JSON...');
          print('📦 Raw JSON type: ${json.runtimeType}');

          if (json is Map<String, dynamic>) {
            final frequenciesData = json['frequencies'];
            if (frequenciesData is List) {
              print('✅ Converting ${frequenciesData.length} search results...');
              return frequenciesData
                  .map((item) => FrequencyModel.fromJson(item))
                  .toList();
            }
          }

          print('❌ Unexpected JSON structure for search frequencies');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Search frequencies completed');
      return response;
    } catch (e) {
      print('❌ Error in searchFrequencies: $e');
      rethrow;
    }
  }

  String _buildUrl(String baseUrl, Map<String, dynamic> params) {
    if (params.isEmpty) return baseUrl;

    final uri = Uri.parse(baseUrl);
    final queryParams = params.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return uri.replace(queryParameters: queryParams).toString();
  }
}

// Cache entry helper class
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp) >
        FrequencyRepository._cacheValidDuration;
  }
}
