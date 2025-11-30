import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerContainer extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? initialDate;
  final ValueChanged<bool>? onMatchOpenChanged;

  const DatePickerContainer({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.onMatchOpenChanged,
  });

  @override
  State<DatePickerContainer> createState() => _DatePickerContainerState();
}

class _DatePickerContainerState extends State<DatePickerContainer> {
  String selectedDateText = '';
  bool isMatchOpen = false;

  String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  @override
  void initState() {
    super.initState();
    // Use initialDate if provided, otherwise use today
    final DateTime initialDate = widget.initialDate ?? DateTime.now();
    selectedDateText = formatDate(initialDate);

    // Delay the callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(initialDate);
      // Inform parent of initial match open state
      widget.onMatchOpenChanged?.call(isMatchOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: widget.initialDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.black,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF202020),
                                  onSurface: Colors.white,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                  ),
                                ),
                                dialogTheme: DialogThemeData(
                                  backgroundColor: Color(0xFF121212),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setState(() {
                            selectedDateText = formatDate(picked);
                          });
                          widget.onDateSelected(picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                selectedDateText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),

              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Match Ouvert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: isMatchOpen,
                      onChanged: (value) {
                        setState(() {
                          isMatchOpen = value;
                        });
                        // Propagate match open toggle to parent
                        widget.onMatchOpenChanged?.call(isMatchOpen);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.grey,
                      inactiveThumbColor: Colors.black,
                      inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
