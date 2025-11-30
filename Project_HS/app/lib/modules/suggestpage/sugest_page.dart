import 'package:flutter/material.dart';

class SuggestPage extends StatefulWidget {
  const SuggestPage({super.key});

  @override
  State<SuggestPage> createState() => _SuggestPageState();
}

class _SuggestPageState extends State<SuggestPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Home Info'),
            Tab(text: 'Club'),
            Tab(text: 'Reservation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Info Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Home Information'),
                // Add your home info content here
              ],
            ),
          ),
          
          // Club Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Club Information'),
                // Add your club content here
              ],
            ),
          ),
          
          // Reservation Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Reservation Information'),
                // Add your reservation content here
              ],
            ),
          ),
        ],
      ),
    );
  }
}
