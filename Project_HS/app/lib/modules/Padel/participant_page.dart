import 'package:app/global/constants/images.dart';
import 'package:app/modules/Padel/controller/controller_participant.dart';
import 'package:app/modules/Padel/widgets/join_match_dialog.dart';
import 'package:app/modules/Padel/widgets/join_confirmation_dialog.dart';
import 'package:app/modules/match_day/ontroller_reserv_match.dart'
    show ReservationMatchController;
import 'package:app/modules/Padel/controller_user_padel.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Padel-inspired palette constants
const Color kPadelAccent = Color(0xFFD0E200); // neon lime accent
const Color kPadelDeep = Color(0xFF0F261E); // deep green-teal
const Color kPadelBlack = Color(0xFF0B0B0B); // rich dark background

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchController controller = Get.put(MatchController());
    const int idUtilisateur = 1;
    // Initialize selected date in initState or onInit instead of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedDate.value = DateTime.now();
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.home_background),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Date Picker Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Obx(
                      () => GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: controller.selectedDate.value,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: kPadelAccent,
                                    surface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            controller.selectedDate.value = picked;
                            // If it's the same date but no reservations loaded yet, still fetch
                            if (!controller.dateSelected.value ||
                                picked != controller.selectedDate.value) {
                              controller.getReservationsByDate(picked);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kPadelAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${controller.selectedDate.value.day.toString().padLeft(2, '0')}/'
                                '${controller.selectedDate.value.month.toString().padLeft(2, '0')}/'
                                '${controller.selectedDate.value.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Time Filter Section with dropdown and toggle
              Obx(
                () =>
                    controller.dateSelected.value
                        ? Column(
                          children: [
                            // Toggle switch for "Heure disponibles seulement"
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 16.0,
                            //   ),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.end,
                            //     children: [
                            //       const Text(
                            //         'Filtrer par créneau horaire',
                            //         style: TextStyle(
                            //           color: Colors.white,
                            //           fontSize: 12,
                            //         ),
                            //       ),
                            //       const SizedBox(width: 8),
                            //       Obx(
                            //         () => Switch(
                            //           value:
                            //               controller
                            //                   .showAvailableHoursOnly
                            //                   .value,
                            //           onChanged: (value) {
                            //             controller
                            //                 .showAvailableHoursOnly
                            //                 .value = value;
                            //             // Refresh time slots based on toggle
                            //             controller.filterReservationsByTime(
                            //               controller.selectedTime.value,
                            //             );
                            //           },
                            //           activeColor: const Color(0xFFFFD700),
                            //           activeTrackColor: const Color(0xFF1A1A1A),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            // Dropdown for time-based filtering
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: TimeFilterDropdown(controller: controller),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              // Matches List - Only show after date is selected
              Expanded(
                child: Obx(
                  () =>
                      !controller.dateSelected.value
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a date to view available matches',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                          : controller.isLoading.value
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: kPadelAccent,
                              strokeWidth: 2,
                            ),
                          )
                          : controller.errorMessage.isNotEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                                // Print error to console
                                () {
                                  print(
                                    'Error loading reservations: ${controller.errorMessage.value}',
                                  );
                                  return const SizedBox.shrink();
                                }(),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      0,
                                      0,
                                      0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      () => controller.getReservationsByDate(
                                        controller.selectedDate.value,
                                      ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : controller.filteredReservations.isEmpty
                          ? Center(
                            child: Text(
                              'Aucun match disponible pour l’heure sélectionnée',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          )
                          : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              // Prevent stacking old ListViews which can create huge textures and key collisions
                              return currentChild ?? const SizedBox.shrink();
                            },
                            child: RefreshIndicator(
                              color: const Color(0xFFFFD700),
                              backgroundColor: const Color(0xFF121212),
                              onRefresh: () async {
                                await controller.getReservationsByDate(
                                  controller.selectedDate.value,
                                );
                              },
                              child: ListView.builder(
                                key: ValueKey(
                                  '${controller.selectedDate.value.toIso8601String()}-${controller.selectedTime.value}-${controller.filteredReservations.length}',
                                ),
                                padding: const EdgeInsets.all(8.0),
                                itemCount:
                                    controller.filteredReservations.length,
                                itemBuilder: (context, index) {
                                  final reservation =
                                      controller.filteredReservations[index];
                                  return MatchCard(
                                    key: ValueKey<int>(reservation.id),
                                    reservation: reservation,
                                    controller: controller,
                                  );
                                },
                              ),
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.refresh, color: Colors.black),
        label: const Text(
          'Refresh',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFD700),
        elevation: 2,
        onPressed: () async {
          await controller.getReservationsByDate(controller.selectedDate.value);
        },
      ),
    );
  }

  // Normalize image URL for web: handle http(s), file://, and bare paths
  String _normalizeImageUrl(String? url) {
    if (url == null) return '';
    final raw = url.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    String path = raw;
    if (raw.startsWith('file://')) {
      path = raw.substring('file://'.length);
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    try {
      final api = Get.find<ApiService>();
      final base = api.baseUrl;
      final host =
          base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
      final normalizedHost =
          host.endsWith('/') ? host.substring(0, host.length - 1) : host;
      return '$normalizedHost$path';
    } catch (_) {
      return 'http://127.0.0.1:300$path';
    }
  }

  // Helper method to format time from API format to display format
  String _formatTimeForDisplay(String apiTime) {
    // If the time is already in HH:MM format, return it
    if (apiTime.isEmpty || apiTime.length <= 5) {
      return apiTime;
    }

    // Extract hours and minutes from the API time format
    try {
      final parts = apiTime.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    } catch (e) {
      print('Error formatting time: $e');
    }

    return apiTime;
  }

  Widget _buildTimeSlot(MatchController controller, String time) {
    return Obx(
      () => GestureDetector(
        onTap: () {
          controller.selectedTime.value = time;
          controller.filterReservationsByTime(time);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                controller.selectedTime.value == time
                    ? Colors.black.withOpacity(0.7)
                    : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  controller.selectedTime.value == time
                      ? const Color.fromARGB(70, 255, 217, 0)
                      : Colors.grey.withOpacity(0.5),
              width: controller.selectedTime.value == time ? 2.0 : 1.0,
            ),
          ),
          child: Text(
            time.isEmpty ? 'All' : time,
            style: TextStyle(
              color:
                  controller.selectedTime.value == time
                      ? Colors.white
                      : Colors.grey.shade400,
              fontWeight:
                  controller.selectedTime.value == time
                      ? FontWeight.bold
                      : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable dropdown component for time slot filtering
class TimeFilterDropdown extends StatelessWidget {
  final MatchController controller;
  const TimeFilterDropdown({super.key, required this.controller});

  // Formats API time values like 'HH:mm:ss' to display-friendly 'HH:mm'.
  // If the input is already short (<=5), returns it unchanged.
  String _formatTimeForDisplay(String apiTime) {
    if (apiTime.isEmpty || apiTime.length <= 5) {
      return apiTime;
    }
    try {
      final parts = apiTime.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    } catch (_) {}
    return apiTime;
  }

  String _labelForReservation(Reservation r) {
    String start = _formatTimeForDisplay(r.plageHoraire.startTime);
    String end = _formatTimeForDisplay(r.plageHoraire.endTime);
    if (start.isEmpty) return '';
    if (end.isEmpty) return start; // fallback to single time
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Build unique options from available reservations
      final options =
          controller.allReservations
              .map(_labelForReservation)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (options.isEmpty) {
        return Semantics(
          label: 'Aucun créneau disponible',
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Text(
              'Aucun créneau disponible pour cette date',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        );
      }

      // Prepend an "All" option
      final dropdownItems = ['All', ...options];

      return Semantics(
        label: 'Filtre par créneau horaire',
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(102, 255, 217, 0)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(63, 255, 217, 0).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  controller.selectedTime.value.isEmpty
                      ? 'All'
                      : controller.selectedTime.value,
              items:
                  dropdownItems
                      .map(
                        (label) => DropdownMenuItem<String>(
                          value: label,
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                final selected = value ?? 'All';
                controller.selectedTime.value =
                    selected == 'All' ? '' : selected;
                controller.filterReservationsByTime(
                  controller.selectedTime.value,
                );
              },
              dropdownColor: const Color(0xFF121212),
              icon: const Icon(Icons.expand_more, color: Color(0xFFFFD700)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    });
  }
}

class MatchCard extends StatelessWidget {
  final Reservation reservation;
  final MatchController controller;

  const MatchCard({
    super.key,
    required this.reservation,
    required this.controller,
  });

  // Normalize image URL for web contexts: supports http(s), file:// and bare paths
  String _normalizeImageUrl(String? url) {
    if (url == null) return '';
    final raw = url.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    String path = raw;
    if (raw.startsWith('file://')) {
      path = raw.substring('file://'.length);
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    try {
      final api = Get.find<ApiService>();
      final base = api.baseUrl;
      final host =
          base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
      final normalizedHost =
          host.endsWith('/') ? host.substring(0, host.length - 1) : host;
      return '$normalizedHost$path';
    } catch (_) {
      return 'http://127.0.0.1:300$path';
    }
  }

  int? _parseEtat(dynamic etat) {
    try {
      if (etat == null) return null;
      if (etat is int) return etat;
      if (etat is String) {
        final trimmed = etat.trim();
        final asInt = int.tryParse(trimmed);
        if (asInt != null) return asInt;
        final lower = trimmed.toLowerCase();
        if (lower.contains('attente') || lower.contains('pending')) return 0;
        if (lower.contains('valid')) return 1; // valid / validé
        if (lower.contains('termin') || lower.contains('over'))
          return 2; // terminé / match over
        if (lower.contains('annul') || lower.contains('cancel'))
          return 3; // annulé / cancel
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _statusMeta(int? code) {
    switch (code) {
      case 0:
        return {
          'label': 'En attente',
          'colors': [kPadelAccent.withOpacity(0.85), kPadelDeep],
          'icon': Icons.schedule,
        };
      case 1:
        return {
          'label': 'Match Valid',
          'colors': [kPadelAccent, kPadelAccent.withOpacity(0.6)],
          'icon': Icons.check_circle,
        };
      case 2:
        return {
          'label': 'Terminé',
          'colors': [kPadelDeep, Colors.black],
          'icon': Icons.flag,
        };
      case 3:
        return {
          'label': 'Match annulé',
          'colors': [kPadelBlack, kPadelDeep],
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': 'Inconnu',
          'colors': [kPadelDeep, Colors.black],
          'icon': Icons.help_outline,
        };
    }
  }

  int? _parseTyper(dynamic typer) {
    try {
      if (typer == null) return null;
      if (typer is int) return typer;
      if (typer is String) {
        final t = typer.trim().toLowerCase();
        final asInt = int.tryParse(t);
        if (asInt != null) return asInt;
        if (t.contains('ouvert')) return 2; // match ouvert
        if (t.contains('prv') || t.contains('priv') || t.contains('private')) {
          return 1; // private
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildStatusChip(
    Reservation reservation,
    List<Participant> participants,
  ) {
    // Rule: For Match Ouvert (typer == 2), show 'Player missing' only.
    // Else, map etat to status labels.
    final typerCode = _parseTyper(reservation.typer);
    String? overrideLabel;

    if (typerCode == 2) {
      // Optionally, only show when spots are available
      final creatorId = reservation.utilisateur.id;
      final isCreatorCounted = participants.any(
        (p) => p.idUtilisateur == creatorId,
      );
      final count =
          isCreatorCounted ? participants.length : (participants.length + 1);
      if (count < 4) {
        overrideLabel = 'Player missing';
      } else {
        // If full, fall back to etat mapping
        overrideLabel = null;
      }
    }

    final code = _parseEtat(reservation.etat);
    final meta = _statusMeta(code);
    String label = overrideLabel ?? meta['label'] as String;
    final List<Color> colors = meta['colors'] as List<Color>;
    IconData icon;
    if (overrideLabel == 'Player missing') {
      icon = Icons.person_add_alt_1;
      // Use a blue-teal gradient for visibility
      label = 'Player missing';
    }
    icon =
        overrideLabel == 'Player missing'
            ? Icons.person_add_alt_1
            : meta['icon'] as IconData;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        // Avoid duplicate keys and stacking which can trigger overflow in web
        return currentChild ?? const SizedBox.shrink();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                overrideLabel == 'Player missing'
                    ? const [Color(0xFF00BCD4), Color(0xFF26C6DA)]
                    : colors,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (overrideLabel == 'Player missing'
                      ? const Color(0xFF00BCD4)
                      : colors.first)
                  .withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              overrideLabel ?? label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printPlayerRatings(
    Reservation reservation,
    Map<int, Participant> slotMap,
  ) {
    final UserPadelController userController =
        Get.isRegistered<UserPadelController>()
            ? Get.find<UserPadelController>()
            : Get.put(UserPadelController());

    slotMap.forEach((slotIndex, participant) {
      final uid = participant.idUtilisateur.toString();
      // Prefer embedded utilisateur.note if available, else fetch rating via public endpoint
      final embeddedNote = participant.utilisateur?.note;
      if (embeddedNote != null) {
        print(
          'Reservation ${reservation.id} | Slot $slotIndex | User $uid | Rating ${embeddedNote.toStringAsFixed(1)}',
        );
      } else {
        userController
            .getRating(userId: uid)
            .then((fetchedNote) {
              print(
                'Reservation ${reservation.id} | Slot $slotIndex | User $uid | Rating ${fetchedNote.toStringAsFixed(1)}',
              );
            })
            .catchError((e) {
              print('Failed to fetch rating for user $uid: $e');
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Participants are prefetched by the controller; avoid fetching in build

    String formatTime(String time) {
      // If it's a full datetime string: "2025-09-15T09:00:00"
      if (time.length >= 16 && time.contains("T")) {
        return time.substring(11, 16); // → "09:00"
      }
      // If it's already just "09:00"
      return time;
    }

    // Format date for display
    final matchDate = reservation.date;

    // Get time slots
    final startTime = reservation.plageHoraire.startTime;
    final endTime = reservation.plageHoraire.endTime;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [kPadelDeep, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(width: 1.2, color: kPadelAccent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: kPadelAccent.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: 0.5,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          reservation.terrain.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.workspace_premium_outlined,
                        color: kPadelAccent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status chip + missing players chip + count
                Obx(() {
                  final participants =
                      controller.participantsByReservation[reservation.id] ??
                      [];
                  final creatorId = reservation.utilisateur.id;
                  final isCreatorCounted = participants.any(
                    (p) => p.idUtilisateur == creatorId,
                  );
                  final count =
                      isCreatorCounted
                          ? participants.length
                          : (participants.length + 1);
                  final missing = (4 - count).clamp(0, 4);

                  return Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildStatusChip(reservation, participants),
                      _buildUnifiedChip(
                        icon: Icons.person_add_alt,
                        label: missing > 0 ? 'Manquants: $missing' : 'Complet',
                        bg: const Color(0xFF00E5FF).withOpacity(0.12),
                        border: const Color(0xFF00E5FF).withOpacity(0.6),
                        textColor: Colors.white,
                      ),
                      // _buildUnifiedChip(
                      //   icon: Icons.groups_2,
                      //   label: '$count/4 joueurs',
                      //   bg: Colors.white.withOpacity(0.06),
                      //   border: Colors.white.withOpacity(0.18),
                      //   textColor: Colors.white70,
                      // ),
                    ],
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // Chips row: date, time, ID
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildUnifiedChip(
                  icon: Icons.calendar_today,
                  label: matchDate,
                  bg: Colors.white.withOpacity(0.06),
                  border: Colors.white.withOpacity(0.18),
                  textColor: Colors.white70,
                ),
                _buildUnifiedChip(
                  icon: Icons.access_time,
                  label: '${formatTime(startTime)} - ${formatTime(endTime)}',
                  bg: Colors.white.withOpacity(0.06),
                  border: Colors.white.withOpacity(0.18),
                  textColor: Colors.white70,
                ),
                _buildUnifiedChip(
                  icon: Icons.confirmation_number_outlined,
                  label: 'ID: ${reservation.id}',
                  bg: Colors.white.withOpacity(0.06),
                  border: Colors.white.withOpacity(0.18),
                  textColor: Colors.white70,
                ),
              ],
            ),

            const SizedBox(height: 22),

            // // Rating badge
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: _buildRatingBadge(reservation.utilisateur.note ?? 0.0),
            // ),
            const SizedBox(height: 20),

            // Players section
            // Inside Obx in MatchCard
            Obx(() {
              // Build slots based on exact teamIndex (0–3)
              List<Participant> participants = List.from(
                controller.participantsByReservation[reservation.id] ?? [],
              );

              // Ensure creator is displayed even if backend didn't add them yet
              final creatorUser = reservation.utilisateur;
              final isCreatorPresent = participants.any(
                (p) => p.idUtilisateur == creatorUser.id,
              );
              if (!isCreatorPresent) {
                // Determine first free slot, preferring Team A (0,1) then Team B (2,3)
                final occupied =
                    participants
                        .where((p) => p.teamIndex != null)
                        .map((p) => p.teamIndex!)
                        .toSet();
                int? creatorSlot;
                for (final s in const [0, 1]) {
                  if (!occupied.contains(s)) {
                    creatorSlot = s;
                    break;
                  }
                }
                if (creatorSlot == null) {
                  for (final s in const [2, 3]) {
                    if (!occupied.contains(s)) {
                      creatorSlot = s;
                      break;
                    }
                  }
                }

                if (creatorSlot != null) {
                  final syntheticCreator = Participant(
                    id: 0,
                    idUtilisateur: creatorUser.id,
                    idReservation: reservation.id,
                    estCreateur: true,
                    utilisateur: creatorUser,
                    team: creatorSlot < 2 ? 'A' : 'B',
                    teamIndex: creatorSlot,
                  );
                  participants = [syntheticCreator, ...participants];
                }
              }

              // Map of slot index -> participant
              final Map<int, Participant> slotMap = {};

              // 1) Assign participants that already have an exact teamIndex
              for (final p in participants.where((p) => p.teamIndex != null)) {
                final idx = p.teamIndex!;
                if (!slotMap.containsKey(idx) && idx >= 0 && idx <= 3) {
                  slotMap[idx] = p;
                }
              }

              // 2) Fallback: assign legacy participants with team label only
              for (final p in participants.where((p) => p.teamIndex == null)) {
                if (p.team == 'A') {
                  for (final s in const [0, 1]) {
                    if (!slotMap.containsKey(s)) {
                      slotMap[s] = Participant(
                        id: p.id,
                        idUtilisateur: p.idUtilisateur,
                        idReservation: p.idReservation,
                        estCreateur: p.estCreateur,
                        utilisateur: p.utilisateur,
                        team: 'A',
                        teamIndex: s,
                      );
                      break;
                    }
                  }
                } else if (p.team == 'B') {
                  for (final s in const [2, 3]) {
                    if (!slotMap.containsKey(s)) {
                      slotMap[s] = Participant(
                        id: p.id,
                        idUtilisateur: p.idUtilisateur,
                        idReservation: p.idReservation,
                        estCreateur: p.estCreateur,
                        utilisateur: p.utilisateur,
                        team: 'B',
                        teamIndex: s,
                      );
                      break;
                    }
                  }
                }
              }

              // Build 4 slots exactly mapped to indices 0..3
              final slots = List.generate(4, (slotIndex) {
                final pAtSlot = slotMap[slotIndex];
                if (pAtSlot != null) {
                  return _buildPlayerAvatar(
                    // pAtSlot.utilisateur?.note ?? 0.0,
                    pAtSlot.utilisateur?.imageUrl,
                    isCreator: pAtSlot.estCreateur,
                    name: pAtSlot.utilisateur?.nom ?? '',
                    isCurrentUser:
                        (pAtSlot.utilisateur?.id?.toString() ?? '') ==
                        controller.currentUserId.value,
                    rating: pAtSlot.utilisateur?.note ?? 0.0,
                    participant: pAtSlot,
                    avatarContext: context,
                  );
                } else {
                  return PlayerSlotEmpty(
                    reservation: reservation,
                    teamLabel: slotIndex < 2 ? 'A' : 'B',
                    slotIndex: slotIndex,
                    positionNumber: slotIndex,
                  );
                }
              });

              // Print ratings in console for each occupied slot using user IDs
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _printPlayerRatings(reservation, slotMap);
              });

              return Column(
                children: [
                  // Team labelsxs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Club A label
                      _buildUnifiedChip(
                        icon: Icons.sports_tennis,
                        label: 'CLUB A',
                        bg: kPadelDeep.withOpacity(0.14),
                        border: kPadelAccent.withOpacity(0.6),
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 24),
                      // Club B label
                      _buildUnifiedChip(
                        icon: Icons.sports_tennis,
                        label: 'CLUB B',
                        bg: kPadelDeep.withOpacity(0.14),
                        border: kPadelAccent.withOpacity(0.6),
                        textColor: Colors.white,
                      ),
                    ],
                  ),

                  // Show user's current team and position when in reservation
                  if (controller.isUserInReservation(
                    controller.currentUserId.value,
                    reservation.id,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Builder(
                        builder: (context) {
                          final currentId = controller.currentUserId.value;
                          // Find the user's exact position by teamIndex
                          Participant? myParticipant;
                          for (final p in slotMap.values) {
                            if ((p.utilisateur?.id?.toString() ?? '') ==
                                currentId) {
                              myParticipant = p;
                              break;
                            }
                          }

                          String teamInfo;
                          if (myParticipant != null &&
                              myParticipant.teamIndex != null) {
                            final ti = myParticipant.teamIndex!;
                            final teamLabel = ti < 2 ? 'CLUB A' : 'CLUB B';
                            final posLabel = ti < 2 ? ti : (ti);
                            teamInfo =
                                'Vous êtes dans $teamLabel • Position $posLabel';
                          } else {
                            teamInfo = 'Vous n’êtes pas encore dans une équipe';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C63FF),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              teamInfo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 360;
                      if (narrow) {
                        return Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              children: [
                                slots[0],
                                const SizedBox(width: 8),
                                slots[1],
                              ],
                            ),
                            _buildUnifiedChip(
                              icon: Icons.sports,
                              label: 'VS',
                              bg: kPadelDeep.withOpacity(0.18),
                              border: kPadelAccent.withOpacity(0.8),
                              textColor: Colors.white,
                            ),
                            Row(
                              children: [
                                slots[2],
                                const SizedBox(width: 8),
                                slots[3],
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              slots[0],
                              const SizedBox(width: 8),
                              slots[1],
                            ],
                          ),
                          _buildUnifiedChip(
                            icon: Icons.sports,
                            label: 'VS',
                            bg: kPadelDeep.withOpacity(0.18),
                            border: kPadelAccent.withOpacity(0.8),
                            textColor: Colors.white,
                          ),
                          Row(
                            children: [
                              slots[2],
                              const SizedBox(width: 8),
                              slots[3],
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // // Join button (big, full width, gradient border). Hidden if already in.
                  // if (!controller.isUserInReservation(
                  //       controller.currentUserId.value,
                  //       reservation.id,
                  //     ) &&
                  //     controller.currentUserId.value !=
                  //         reservation.utilisateur.id.toString())
                  //   _buildJoinButton(context, reservation, slotMap),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to build time slot buttons
  Widget _buildTimeSlot(String time, bool isActive, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? kPadelAccent.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? kPadelAccent : kPadelDeep.withOpacity(0.4),
          width: 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: kPadelAccent.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  // Helper method to build player avatar with modern design
  Widget _buildPlayerAvatar(
    String? imageUrl, {
    bool isCreator = false,
    bool isCurrentUser = false,
    String name = '',
    double rating = 0.0,
    Participant? participant,
    BuildContext? avatarContext,
  }) {
    final scale = ValueNotifier<double>(1.0);
    final UserPadelController userController =
        Get.isRegistered<UserPadelController>()
            ? Get.find<UserPadelController>()
            : Get.put(UserPadelController());
    final hover = ValueNotifier<bool>(false);
    return GestureDetector(
      onTapDown: (_) => scale.value = 0.96,
      onTapCancel: () => scale.value = 1.0,
      onTapUp: (_) {
        scale.value = 1.0;
        if (participant != null &&
            participant.utilisateur != null &&
            avatarContext != null) {
          _showProfilePreview(participant.utilisateur!, avatarContext);
        }
      },
      child: ValueListenableBuilder<double>(
        valueListenable: scale,
        builder:
            (context, v, child) => AnimatedScale(
              scale: v,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: child,
            ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main avatar container with modern styling and hover color animation
              ValueListenableBuilder<bool>(
                valueListenable: hover,
                builder: (context, isHovered, _) {
                  final Color animColor =
                      Color.lerp(
                        const Color(0xFF0F261E),
                        const Color(0xFFD0E200),
                        isHovered ? 1.0 : 0.0,
                      ) ??
                      const Color(0xFFD0E200);
                  return MouseRegion(
                    onEnter: (_) => hover.value = true,
                    onExit: (_) => hover.value = false,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.7),
                        border: Border.all(
                          color:
                              isCurrentUser
                                  ? const Color(0xFFFFD700)
                                  : animColor,
                          width: isCurrentUser ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: animColor.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        image:
                            imageUrl != null && imageUrl.isNotEmpty
                                ? DecorationImage(
                                  image: NetworkImage(
                                    _normalizeImageUrl(imageUrl),
                                  ),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          imageUrl == null || imageUrl.isEmpty
                              ? (
                              // Only attempt fetching via protected route for the current user
                              (isCurrentUser &&
                                      participant?.idUtilisateur != null)
                                  ? FutureBuilder<Map<String, dynamic>>(
                                    future: userController.getUserInfo(
                                      userId:
                                          participant!.idUtilisateur.toString(),
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState !=
                                          ConnectionState.done) {
                                        return const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFD0E200),
                                                  ),
                                            ),
                                          ),
                                        );
                                      }
                                      final data = snapshot.data ?? {};
                                      final dynamic fetchedRaw =
                                          data['image_url'] ??
                                          data['imageUrl'] ??
                                          data['image'] ??
                                          data['photo'];
                                      final fetched =
                                          fetchedRaw?.toString() ?? '';
                                      if (fetched.isNotEmpty) {
                                        return ClipOval(
                                          child: Image.network(
                                            _normalizeImageUrl(fetched),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return Icon(
                                        Icons.person,
                                        color: Colors.grey.shade400,
                                        size: 32,
                                      );
                                    },
                                  )
                                  : Icon(
                                    Icons.person,
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ))
                              : null,
                    ),
                  );
                },
              ),

              // Rating badge – modern overlay above the avatar
              Positioned(
                top: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kPadelBlack.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPadelAccent, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: kPadelAccent.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: kPadelAccent, size: 14),
                        const SizedBox(width: 4),
                        if (rating > 0)
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (participant?.idUtilisateur != null)
                          FutureBuilder<double>(
                            future: userController.getRating(
                              userId: participant!.idUtilisateur.toString(),
                            ),
                            builder: (context, snapshot) {
                              final fetched = snapshot.data ?? 0.0;
                              return Text(
                                fetched > 0 ? fetched.toStringAsFixed(1) : '—',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          )
                        else
                          const Text(
                            '—',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Creator badge with modern design
              if (isCreator)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(
                        //   color: const Color.fromARGB(
                        //     34,
                        //     205,
                        //     211,
                        //     137,
                        //   ).withOpacity(0.9),
                        //   width: 2.5,
                        // ),
                        boxShadow: [
                          BoxShadow(
                            color: kPadelAccent.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Name tag with modern styling
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kPadelDeep.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPadelDeep.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (rating > 0) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                          size: 10,
                        ),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format time for display
  String _formatTimeForDisplay(String time) {
    // Assuming time is in HH:MM format, return as is
    return time;
  }

  // Helper method to show profile preview dialog
  void _showProfilePreview(User user, BuildContext context) {
    final UserPadelController userController =
        Get.isRegistered<UserPadelController>()
            ? Get.find<UserPadelController>()
            : Get.put(UserPadelController());
    // Determine if the requested profile is the current user (protected route)
    final MatchController matchController =
        Get.isRegistered<MatchController>()
            ? Get.find<MatchController>()
            : Get.put(MatchController());
    final bool isCurrentUserProfile =
        user.id.toString() == matchController.currentUserId.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F261E), Color(0xFF0F261E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD0E200), width: 2),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // User avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD0E200),
                      width: 3,
                    ),
                    image:
                        user.imageUrl != null && user.imageUrl!.isNotEmpty
                            ? DecorationImage(
                              image: NetworkImage(
                                _normalizeImageUrl(user.imageUrl),
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      user.imageUrl == null || user.imageUrl!.isEmpty
                          ? (isCurrentUserProfile
                              ? FutureBuilder<Map<String, dynamic>>(
                                future: userController.getUserInfo(
                                  userId: user.id.toString(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFFD0E200),
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                  final data = snapshot.data ?? {};
                                  final dynamic fetchedRaw =
                                      data['image_url'] ??
                                      data['imageUrl'] ??
                                      data['image'] ??
                                      data['photo'];
                                  final fetched = fetchedRaw?.toString() ?? '';
                                  if (fetched.isNotEmpty) {
                                    return ClipOval(
                                      child: Image.network(
                                        _normalizeImageUrl(fetched),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return Icon(
                                    Icons.person,
                                    color: Colors.grey.shade400,
                                    size: 40,
                                  );
                                },
                              )
                              : Icon(
                                Icons.person,
                                color: Colors.grey.shade400,
                                size: 40,
                              ))
                          : null,
                ),

                const SizedBox(height: 16),

                // User name
                Text(
                  '${user.nom} ${user.prenom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // User rating: prefer embedded utilisateur.note, otherwise fetch via rating endpoint
                FutureBuilder<double>(
                  future:
                      user.note != null
                          ? Future.value(user.note!)
                          : userController.getRating(
                            userId: user.id.toString(),
                          ),
                  builder: (context, snapshot) {
                    final noteVal =
                        snapshot.hasData
                            ? (snapshot.data ?? 0.0)
                            : (user.note ?? 0.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          noteVal.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Additional details
                if (user.numeroTelephone != null) ...[
                  _buildProfileDetail('Phone', user.numeroTelephone!),
                  const SizedBox(height: 8),
                ],
                if (user.email != null) ...[
                  _buildProfileDetail('Email', user.email!),
                  const SizedBox(height: 8),
                ],
                if (user.dateNaissance != null) ...[
                  _buildProfileDetail('Birth Date', user.dateNaissance!),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build profile detail row
  Widget _buildProfileDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build empty player slot
  Widget _buildUnifiedChip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color border,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: border.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildRatingBadge(double rating) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(14),
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFF7B61FF), Color(0xFFA18CFF)],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF7B61FF).withOpacity(0.35),
  //           blurRadius: 12,
  //           offset: const Offset(0, 6),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.star, color: Color(0xFFFFD600), size: 18),
  //         const SizedBox(width: 6),
  //         Text(
  //           rating > 0 ? rating.toStringAsFixed(1) : '—',
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 14,
  //             fontWeight: FontWeight.w800,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildJoinButton(
    BuildContext context,
    Reservation reservation,
    Map<int, Participant> slotMap,
  ) {
    return GestureDetector(
      onTap: () async {
        final controller = Get.find<MatchController>();
        if (controller.isUserInReservation(
          controller.currentUserId.value,
          reservation.id,
        )) {
          return;
        }
        // Find first free slot index
        int? free;
        for (int i = 0; i < 4; i++) {
          if (!slotMap.containsKey(i)) {
            free = i;
            break;
          }
        }
        if (free == null) return; // no slot

        // Conflict pre-check
        try {
          final api =
              Get.isRegistered<ApiService>()
                  ? ApiService.instance
                  : Get.put(ApiService());
          final plageId = reservation.plageHoraire.id.toString();
          final resp = await api.get(
            '/reservations/check-date-time-conflict/${reservation.date}/$plageId',
          );
          if (resp.statusCode == 200) {
            final data = resp.data;
            final hasConflict =
                data is Map<String, dynamic>
                    ? (data['hasConflict'] == true)
                    : (data['hasConflict'] ?? false);
            if (hasConflict) {
              Get.snackbar(
                'Conflit',
                'Vous avez déjà un match prévu à la même date et heure',
                backgroundColor: Colors.red.withOpacity(0.85),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              return;
            }
          }
        } catch (_) {}

        final confirmed = await showJoinConfirmationDialog(
          context,
          title: 'Confirmer la réservation',
          message: 'Voulez-vous confirmer votre participation à ce match ?',
        );
        if (!confirmed) return;

        showDialog(
          context: context,
          builder:
              (context) => JoinMatchDialog(
                reservationId: reservation.id,
                matchPrice: reservation.prixTotal ?? 0.0,
                matchTime:
                    '${_formatTimeForDisplay(reservation.plageHoraire.startTime)} - ${_formatTimeForDisplay(reservation.plageHoraire.endTime)}',
                matchDate: reservation.date,
                terrainName: reservation.terrain.name,
                plageId: reservation.plageHoraire.id,
                selectedPosition: free!,
              ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD600).withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient border effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD600), Color(0xFF4A5FFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              height: 52,
            ),
            // Container(
            //   height: 52,
            //   margin: const EdgeInsets.all(2),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF1C1C1E),
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: const Center(
            //     child: Text(
            //       'Rejoindre ce match',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 16,
            //         fontWeight: FontWeight.w700,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// Pulsing glow + tap-scale empty slot widget (UI only)
class PlayerSlotEmpty extends StatefulWidget {
  final Reservation reservation;
  final String teamLabel;
  final int slotIndex;
  final int positionNumber;

  const PlayerSlotEmpty({
    Key? key,
    required this.reservation,
    required this.teamLabel,
    required this.slotIndex,
    required this.positionNumber,
  }) : super(key: key);

  @override
  State<PlayerSlotEmpty> createState() => _PlayerSlotEmptyState();
}

class _PlayerSlotEmptyState extends State<PlayerSlotEmpty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  double _scale = 1.0;

  String _formatTimeForDisplayLocal(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    } catch (_) {
      return time;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleJoinTap(BuildContext context) async {
    final controller = Get.find<MatchController>();
    if (!controller.isUserInReservation(
      controller.currentUserId.value,
      widget.reservation.id,
    )) {
      try {
        final api =
            Get.isRegistered<ApiService>()
                ? ApiService.instance
                : Get.put(ApiService());
        final plageId = widget.reservation.plageHoraire.id.toString();
        final resp = await api.get(
          '/reservations/check-date-time-conflict/${widget.reservation.date}/$plageId',
        );
        if (resp.statusCode == 200) {
          final data = resp.data;
          final hasConflict =
              data is Map<String, dynamic>
                  ? (data['hasConflict'] == true)
                  : (data['hasConflict'] ?? false);
          if (hasConflict) {
            Get.snackbar(
              'Conflit',
              'Vous avez déjà un match prévu à la même date et heure',
              backgroundColor: Colors.red.withOpacity(0.85),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
            return;
          }
        }
      } catch (_) {}

      final confirmed = await showJoinConfirmationDialog(
        context,
        title: 'Confirmer la réservation',
        message: 'Voulez-vous confirmer votre participation à ce match ?',
      );
      if (!confirmed) return;

      showDialog(
        context: context,
        builder:
            (context) => JoinMatchDialog(
              reservationId: widget.reservation.id,
              matchPrice: widget.reservation.prixTotal ?? 0.0,
              matchTime:
                  '${_formatTimeForDisplayLocal(widget.reservation.plageHoraire.startTime)} - ${_formatTimeForDisplayLocal(widget.reservation.plageHoraire.endTime)}',
              matchDate: widget.reservation.date,
              terrainName: widget.reservation.terrain.name,
              plageId: widget.reservation.plageHoraire.id,
              selectedPosition: widget.slotIndex,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glow = ColorTween(
      begin: const Color(0xFFFFD600).withOpacity(0.15),
      end: const Color(0xFF4A5FFF).withOpacity(0.35),
    ).animate(_pulse);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: () => _handleJoinTap(context),
      child: Hero(
        tag: 'join-slot-${widget.reservation.id}-${widget.slotIndex}',
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: glow,
                builder: (context, _) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1C1C1E), Color(0xFF111111)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD600),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glow.value!,
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: const Color(0xFFFFD600),
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5FFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '${widget.positionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
