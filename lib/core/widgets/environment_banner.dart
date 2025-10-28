import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';

/// Shows environment banner when not in production
/// Helps developers know which backend they're connected to
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hide banner in production
    if (ApiEndpoints.isProduction) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.orange.shade700,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ApiEndpoints.environmentName} MODE - ${ApiEndpoints.baseUrl}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              ApiEndpoints.isLocal ? Icons.computer : Icons.cloud,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Debug info widget showing current environment
class EnvironmentDebugInfo extends StatelessWidget {
  const EnvironmentDebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode and non-production
    if (ApiEndpoints.isProduction) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.orange.shade400, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Environment Config',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Environment', ApiEndpoints.environmentName),
            _buildInfoRow('API URL', ApiEndpoints.baseUrl),
            _buildInfoRow('Socket URL', ApiEndpoints.socketUrl),
            _buildInfoRow(
              'Mode',
              ApiEndpoints.isLocal ? 'Local Testing' : 'Production',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
