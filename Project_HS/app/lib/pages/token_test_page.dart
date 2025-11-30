import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';

class TokenTestPage extends StatelessWidget {
  const TokenTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ApiService apiService = Get.find<ApiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authentication Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Logged in: ${authController.isLoggedIn.value}'),
                      Text('Loading: ${authController.isLoading.value}'),
                      if (authController.currentUser.value != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'User: ${authController.currentUser.value!['nom']} ${authController.currentUser.value!['prenom']}',
                        ),
                        Text(
                          'Email: ${authController.currentUser.value!['email']}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await apiService.get(
                    '/utilisateurs/profile',
                  );
                  Get.snackbar(
                    'Success',
                    'Profile fetched successfully: ${response.statusCode}',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to fetch profile: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Test API Call (Protected Route)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await authController.refreshTokenIfNeeded();
                Get.snackbar(
                  'Token Refresh',
                  authController.isLoggedIn.value
                      ? 'Token is valid/refreshed'
                      : 'Token refresh failed',
                  backgroundColor: authController.isLoggedIn.value ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              },
              child: const Text('Check/Refresh Token'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await authController.logout();
                Get.snackbar(
                  'Logout',
                  'Logged out successfully',
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'Testing Instructions:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Login first using the login page\n'
              '2. Use "Test API Call" to make authenticated requests\n'
              '3. The token will automatically refresh if expired\n'
              '4. Use "Check/Refresh Token" to manually test refresh\n'
              '5. Use logout to clear all tokens',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
