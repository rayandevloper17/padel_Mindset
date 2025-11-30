import 'package:app/global/constants/images.dart';
import 'package:app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabSelectClubePage extends StatefulWidget {
  const TabSelectClubePage({super.key});

  @override
  State<TabSelectClubePage> createState() => _TabSelectClubePageState();
}

class _TabSelectClubePageState extends State<TabSelectClubePage> {
  String? _selectedCity;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.home_background),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 15, left: 14, bottom: 14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir un club',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      dropdownColor: Colors.transparent,
                      isExpanded: true,
                      hint: const Text(
                        'Oran',
                        style: TextStyle(color: Colors.white),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 30,
                      ),
                      items:
                          ['Oran'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 1.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9.0,
                                  horizontal: 0.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                      selectedItemBuilder: (BuildContext context) {
                        return ['Oran'].map<Widget>((String item) {
                          return Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height:
                      screenSize.height *
                      0.8, // Increased height for vertical scroll
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 15),
                    itemCount: 1, // Replace with actual club data length
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Get.toNamed(Routes.PADEL);
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 16,
                          ), // Changed from right to bottom margin
                          height: 240, // Fixed height for each card
                          width: double.infinity, // Full width
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/club_image.jpg',
                              ), // Replace with actual club image
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Rating in top right

                              // Club info at bottom
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Central Padel Club', // Replace with actual club name
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Hussein Dey, Alger',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
