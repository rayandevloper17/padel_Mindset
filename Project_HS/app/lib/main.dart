import 'package:app/modules/match_day/ontroller_reserv_match.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/bindings/app_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  DependencyInjection.init();
  Get.put(ReservationMatchController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  Future<String> _getInitialRoute() async {
    // Check if token exists and is not expired
    final token = await ApiService.instance.getValidAccessToken();
    if (token == null || token.isEmpty) {
      return AppPages.routes[0].name; // Return login route if no token
    }

    try {
      // Verify token validity here if needed
      return await AppPages.getInitialRoute();
    } catch (e) {
      // If token verification fails or token is expired
      return AppPages.routes[0].name; // Return login route if no token
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking the token, show a splash or loading screen
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Padel-Invest',
          initialRoute:
              snapshot.data ??
              AppPages.routes[0].name, // Default to login if error
          getPages: AppPages.routes,
          initialBinding: AppBinding(),
        );
      },
    );
  }
}
