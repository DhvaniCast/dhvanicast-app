import '../models/api_response.dart';
import '../models/group_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/http_client.dart';

class GroupRepository {
  final HttpClient _httpClient = HttpClient();

  /// Get user's groups
  Future<ApiResponse<List<GroupModel>>> getUserGroups({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('🔍 Step 1: Loading user groups...');
      final url = _buildUrl(ApiEndpoints.groups, {
        'page': page,
        'limit': limit,
      });
      print('🌐 Step 2: URL: $url');

      final response = await _httpClient.get<List<GroupModel>>(
        url,
        fromJson: (json) {
          print('🔧 Step 3: Processing groups JSON...');
          print('📦 Raw JSON type: ${json.runtimeType}');
          print('📦 Raw JSON: $json');

          // Backend returns: {groups: [...], pagination: {...}}
          // We need to extract the groups array
          if (json is Map<String, dynamic>) {
            print('✅ JSON is Map, extracting groups...');
            final groupsData = json['groups'];
            print('📊 Groups data type: ${groupsData?.runtimeType}');
            print('📊 Groups count: ${groupsData?.length ?? 0}');

            if (groupsData is List) {
              print('✅ Converting ${groupsData.length} groups...');
              final result = groupsData
                  .map((item) => GroupModel.fromJson(item))
                  .toList();
              print('✅ Conversion complete: ${result.length} groups');
              return result;
            }
          }

          print('❌ Unexpected JSON structure for groups');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Step 4: Groups response received successfully');
      return response;
    } catch (e) {
      print('❌ Error in getUserGroups: $e');
      rethrow;
    }
  }

  /// Get specific group by ID
  Future<ApiResponse<GroupModel>> getGroupById(String id) async {
    try {
      final response = await _httpClient.get<GroupModel>(
        ApiEndpoints.groupById(id),
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create new group
  Future<ApiResponse<GroupModel>> createGroup({
    required String name,
    String? description,
    String? avatar,
    String? frequencyId,
    bool isPublic = true,
    bool allowMemberInvites = true,
    bool requireApproval = false,
    int? maxMembers,
  }) async {
    try {
      final response = await _httpClient.post<GroupModel>(
        ApiEndpoints.groups,
        body: {
          'name': name,
          if (description != null) 'description': description,
          if (avatar != null) 'avatar': avatar,
          if (frequencyId != null) 'frequency': frequencyId,
          'settings': {
            'isPublic': isPublic,
            'allowMemberInvites': allowMemberInvites,
            'requireApproval': requireApproval,
            if (maxMembers != null) 'maxMembers': maxMembers,
          },
        },
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update group
  Future<ApiResponse<GroupModel>> updateGroup(
    String id, {
    String? name,
    String? description,
    String? avatar,
    String? frequencyId,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _httpClient.put<GroupModel>(
        ApiEndpoints.groupById(id),
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatar != null) 'avatar': avatar,
          if (frequencyId != null) 'frequency': frequencyId,
          if (settings != null) 'settings': settings,
        },
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete group
  Future<ApiResponse<void>> deleteGroup(String id) async {
    try {
      final response = await _httpClient.delete<void>(
        ApiEndpoints.groupById(id),
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Join group
  Future<ApiResponse<GroupModel>> joinGroup(String id) async {
    try {
      final response = await _httpClient.post<GroupModel>(
        ApiEndpoints.joinGroup(id),
        body: {},
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Leave group
  Future<ApiResponse<GroupModel>> leaveGroup(String id) async {
    try {
      final response = await _httpClient.post<GroupModel>(
        ApiEndpoints.leaveGroup(id),
        body: {},
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Invite user to group
  Future<ApiResponse<GroupModel>> inviteToGroup(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _httpClient.post<GroupModel>(
        ApiEndpoints.inviteToGroup(groupId),
        body: {'userId': userId},
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update member role
  Future<ApiResponse<GroupModel>> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    try {
      final response = await _httpClient.put<GroupModel>(
        ApiEndpoints.updateMemberRole(groupId),
        body: {'userId': userId, 'role': role},
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove member from group
  Future<ApiResponse<GroupModel>> removeMember(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _httpClient.delete<GroupModel>(
        _buildUrl(ApiEndpoints.removeMember(groupId), {'userId': userId}),
        fromJson: (json) => GroupModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get group statistics
  Future<ApiResponse<Map<String, dynamic>>> getGroupStats(String id) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        ApiEndpoints.groupStats(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Search groups
  Future<ApiResponse<List<GroupModel>>> searchGroups(String query) async {
    try {
      print('🔍 Searching groups with query: $query');
      final url = _buildUrl(ApiEndpoints.searchGroups, {'q': query});

      final response = await _httpClient.get<List<GroupModel>>(
        url,
        fromJson: (json) {
          print('🔧 Processing search groups JSON...');
          print('📦 Raw JSON type: ${json.runtimeType}');

          if (json is Map<String, dynamic>) {
            final groupsData = json['groups'];
            if (groupsData is List) {
              print('✅ Converting ${groupsData.length} search results...');
              return groupsData
                  .map((item) => GroupModel.fromJson(item))
                  .toList();
            }
          }

          print('❌ Unexpected JSON structure for search groups');
          throw Exception('Invalid response structure');
        },
      );

      print('✅ Search groups completed');
      return response;
    } catch (e) {
      print('❌ Error in searchGroups: $e');
      rethrow;
    }
  }

  /// Helper method to build URL with query parameters
  String _buildUrl(String baseUrl, Map<String, dynamic> params) {
    if (params.isEmpty) return baseUrl;

    final uri = Uri.parse(baseUrl);
    final queryParams = params.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return uri.replace(queryParameters: queryParams).toString();
  }
}
