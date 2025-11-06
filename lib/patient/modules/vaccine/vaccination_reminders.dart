import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcon30/services/firestore_service.dart';
import 'package:medcon30/services/app_history_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../api_config.dart';

class VaccinationReminder extends StatefulWidget {
  const VaccinationReminder({Key? key}) : super(key: key);

  @override
  State<VaccinationReminder> createState() => _VaccinationReminderState();
}

class _VaccinationReminderState extends State<VaccinationReminder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // _updateExistingReminders(); // Removed debug/update logic at start
  }

  // Removed unused _updateExistingReminders to satisfy linter

  Color statusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Missed":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddVaccinationDialog(BuildContext rootContext) {
    final isDarkMode = Theme.of(rootContext).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    // Colors used in details dialog
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    final formKey = GlobalKey<FormState>();
    String name = '';
    String dateGiven = '';
    String nextDoseDate = '';
    String notes = '';
    TimeOfDay reminderTime = TimeOfDay.now();
    final reminderTimeController =
        TextEditingController(text: reminderTime.format(rootContext));
    final dateGivenController = TextEditingController();
    final nextDoseDateController = TextEditingController();

    Future<void> pickDate(BuildContext context, Function(String) onPicked,
        TextEditingController controller) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        final dateString = picked.toIso8601String().substring(0, 10);
        onPicked(dateString);
        controller.text = dateString;
      }
    }

    showDialog(
      context: rootContext,
      builder: (context) {
        return Dialog(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Vaccination',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: textColor)),
                    const SizedBox(height: 20),
                    Text('Vaccine Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    TextFormField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter vaccine name',
                        hintStyle: TextStyle(color: subTextColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF7B61FF))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter vaccine name'
                          : null,
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Text('Date Given',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: dateGivenController,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onTap: () => pickDate(context, (val) {
                            dateGiven = val;
                          }, dateGivenController),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 20, color: subTextColor),
                          onPressed: () => pickDate(context, (val) {
                            dateGiven = val;
                          }, dateGivenController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Next Dose Date *',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: nextDoseDateController,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Next dose date is required'
                              : null,
                          onTap: () => pickDate(context, (val) {
                            nextDoseDate = val;
                          }, nextDoseDateController),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 20, color: subTextColor),
                          onPressed: () => pickDate(context, (val) {
                            nextDoseDate = val;
                          }, nextDoseDateController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Reminder Time *',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: reminderTimeController,
                          decoration: InputDecoration(
                            hintText: 'Select reminder time',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Reminder time is required'
                              : null,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (picked != null) {
                              reminderTime = picked;
                              reminderTimeController.text =
                                  reminderTime.format(rootContext);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time,
                              size: 20, color: subTextColor),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (picked != null) {
                              reminderTime = picked;
                              reminderTimeController.text =
                                  reminderTime.format(rootContext);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Setting reminder time helps you track your schedule',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7B61FF)),
                    ),
                    const SizedBox(height: 16),
                    Text('Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    TextFormField(
                      style: TextStyle(color: textColor),
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes',
                        hintStyle: TextStyle(color: subTextColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF7B61FF))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => notes = value,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;

                                final reminderData = {
                                  'name': name,
                                  'dates': [dateGiven, nextDoseDate],
                                  'status': 'Pending',
                                  'notes': notes,
                                  'userId': currentUser?.uid,
                                  'reminderTime':
                                      '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
                                  'createdAt': FieldValue.serverTimestamp(),
                                };

                                // Close dialog immediately and show quick feedback
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saving reminder...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );

                                // Background save to avoid UI blocking
                                Future.microtask(() async {
                                  try {
                                    await FirestoreService()
                                        .addVaccinationReminder(reminderData);

                                    ScaffoldMessenger.of(rootContext)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Vaccination reminder added successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Track the activity (non-blocking)
                                    AppHistoryService().trackVaccineReminder(
                                      vaccineName: name,
                                      dates: [dateGiven, nextDoseDate]
                                          .where((date) => date.isNotEmpty)
                                          .toList(),
                                      notes: notes,
                                    );

                                    // Fire-and-forget server scheduling
                                    if (nextDoseDate.isNotEmpty ||
                                        dateGiven.isNotEmpty) {
                                      final List<String> dates = [];
                                      if (dateGiven.isNotEmpty) {
                                        dates.add(dateGiven);
                                      }
                                      if (nextDoseDate.isNotEmpty) {
                                        dates.add(nextDoseDate);
                                      }
                                      // ignore: unawaited_futures
                                      sendReminderToServer(
                                        dates,
                                        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(rootContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error:  ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            child: const Text('Save',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditVaccinationDialog(
      BuildContext rootContext, Map<String, dynamic> rec) {
    final isDarkMode = Theme.of(rootContext).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    final formKey = GlobalKey<FormState>();
    String name = rec['name'] ?? '';
    String dateGiven = (rec['dates'] != null && rec['dates'].isNotEmpty)
        ? rec['dates'][0]
        : '';
    String nextDoseDate = (rec['dates'] != null && rec['dates'].length > 1)
        ? rec['dates'][1]
        : '';
    String notes = rec['notes'] ?? '';
    String status = rec['status'] ?? 'Pending';
    TimeOfDay reminderTime = TimeOfDay.now();
    if (rec['reminderTime'] != null) {
      final timeParts = rec['reminderTime'].split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    final reminderTimeController =
        TextEditingController(text: reminderTime.format(rootContext));

    Future<void> pickDate(
        BuildContext context, Function(String) onPicked, String initial) async {
      final picked = await showDatePicker(
        context: context,
        initialDate:
            initial.isNotEmpty ? DateTime.parse(initial) : DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        onPicked(picked.toIso8601String().substring(0, 10));
      }
    }

    showDialog(
      context: rootContext,
      builder: (context) {
        return Dialog(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Vaccination',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: textColor)),
                    const SizedBox(height: 20),
                    Text('Vaccine Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: name,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter vaccine name',
                        hintStyle: TextStyle(color: subTextColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF7B61FF))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter vaccine name'
                          : null,
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Text('Date Given',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: TextEditingController(text: dateGiven),
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onTap: () => pickDate(context, (val) {
                            dateGiven = val;
                            (context as Element).markNeedsBuild();
                          }, dateGiven),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 20, color: subTextColor),
                          onPressed: () => pickDate(context, (val) {
                            dateGiven = val;
                            (context as Element).markNeedsBuild();
                          }, dateGiven),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Next Dose Date *',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: TextEditingController(text: nextDoseDate),
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Next dose date is required'
                              : null,
                          onTap: () => pickDate(context, (val) {
                            nextDoseDate = val;
                            (context as Element).markNeedsBuild();
                          }, nextDoseDate),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 20, color: subTextColor),
                          onPressed: () => pickDate(context, (val) {
                            nextDoseDate = val;
                            (context as Element).markNeedsBuild();
                          }, nextDoseDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Reminder Time *',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          style: TextStyle(color: textColor),
                          readOnly: true,
                          controller: reminderTimeController,
                          decoration: InputDecoration(
                            hintText: 'Select reminder time',
                            hintStyle: TextStyle(color: subTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF7B61FF))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Reminder time is required'
                              : null,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (picked != null) {
                              reminderTime = picked;
                              reminderTimeController.text =
                                  reminderTime.format(rootContext);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.access_time,
                              size: 20, color: subTextColor),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (picked != null) {
                              reminderTime = picked;
                              reminderTimeController.text =
                                  reminderTime.format(rootContext);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Setting reminder time helps you track your schedule',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7B61FF)),
                    ),
                    const SizedBox(height: 16),
                    Text('Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: notes,
                      style: TextStyle(color: textColor),
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes',
                        hintStyle: TextStyle(color: subTextColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF7B61FF))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => notes = value,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                await FirestoreService()
                                    .updateVaccinationReminder(
                                  rec['id'],
                                  {
                                    'name': name,
                                    'dates': [dateGiven, nextDoseDate],
                                    'status': status,
                                    'notes': notes,
                                    'reminderTime':
                                        '${reminderTime.hour}:${reminderTime.minute}',
                                  },
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(rootContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Vaccination reminder updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Save',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVaccinationDetailsDialog(
      BuildContext context, Map<String, dynamic> rec) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('Vaccination Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: textColor)),
                ),
                const SizedBox(height: 18),
                Text('Vaccine Name',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Text(rec['name'] ?? '',
                    style: TextStyle(fontSize: 15, color: textColor)),
                const SizedBox(height: 10),
                Text('Date Given',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Text(
                    (rec['dates'] != null && rec['dates'].isNotEmpty)
                        ? rec['dates'][0]
                        : '',
                    style: TextStyle(fontSize: 15, color: textColor)),
                const SizedBox(height: 10),
                Text('Next Dose Date',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Text(
                    (rec['dates'] != null && rec['dates'].length > 1)
                        ? rec['dates'][1]
                        : '-',
                    style: TextStyle(fontSize: 15, color: textColor)),
                const SizedBox(height: 10),
                Text('Reminder Time',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Text(rec['reminderTime'] ?? '-',
                    style: TextStyle(fontSize: 15, color: textColor)),
                const SizedBox(height: 10),
                // Removed Reminder Time field
                Text('Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(rec['status'] ?? ''),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec['status'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                Text(rec['notes'] ?? '-',
                    style: TextStyle(fontSize: 15, color: textColor)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditVaccinationDialog(context, rec);
                        },
                        child: const Text('Edit',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          try {
                            await FirestoreService()
                                .deleteVaccinationReminder(rec['id']);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vaccination reminder deleted'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this function to send reminder data to Node.js server
  Future<void> sendReminderToServer(
      List<String> dates, String reminderTime) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      try {
        // Use the API config for reminder server with fallbacks
        final List<String> hosts = [
          ApiConfig.reminderServer,
          'http://10.0.2.2:3000', // Android emulator fallback
          'http://127.0.0.1:3000', // Localhost fallback
        ];

        http.Response? response;
        for (final host in hosts) {
          try {
            final r = await http
                .post(
                  Uri.parse('$host/schedule'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'token': token,
                    'dates': dates,
                    'reminderTime': reminderTime,
                  }),
                )
                .timeout(const Duration(seconds: 10));
            if (r.statusCode == 200) {
              debugPrint('Reminder scheduled via host: $host');
              response = r;
              break;
            }
          } catch (e) {
            debugPrint('Failed to reach $host: $e');
          }
        }
        if (response == null) {
          throw Exception('Could not reach reminder server on local hosts');
        }
      } catch (e) {
        debugPrint('Failed to send reminder to server: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    // Debug: Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Debug: Current user: ${currentUser?.uid}');
    print('Debug: User authenticated: ${currentUser != null}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Vaccination Reminder',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // How to Use Vaccination Records info section
                Text(
                  "ℹ️ How to Use Vaccination Records",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep track of your immunization history and upcoming vaccination schedules. Tap on any record to view details or make updates.",
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  "• Green badge indicates completed vaccinations",
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
                Text(
                  "• Yellow badge shows pending vaccinations",
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
                Text(
                  "• Red badge indicates missed appointments",
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
                const SizedBox(height: 18),
                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showAddVaccinationDialog(context),
                    child: const Text(
                      "+ Add New Vaccination",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your Vaccination Records",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentUser == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: subTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please log in to view vaccination records.',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('vaccination_reminders')
                        .where('userId',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      print(
                          'Debug: StreamBuilder state: ${snapshot.connectionState}');
                      print('Debug: Has data: ${snapshot.hasData}');
                      print(
                          'Debug: Current user: ${FirebaseAuth.instance.currentUser?.uid}');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B61FF),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('Debug: StreamBuilder error: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print('Debug: No data found');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.vaccines_outlined,
                                size: 64,
                                color: subTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No vaccination records found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first vaccination reminder to get started.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      print(
                          'Debug: Found ${snapshot.data!.docs.length} records');
                      final records = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: records.length,
                        itemBuilder: (context, idx) {
                          final rec =
                              records[idx].data() as Map<String, dynamic>;
                          rec['id'] = records[idx].id;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _showVaccinationDetailsDialog(context, rec),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: borderColor),
                              ),
                              color: bgColor,
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rec["name"] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (rec["dates"] != null &&
                                                  (rec["dates"] as List)
                                                      .isNotEmpty)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Start date: ${rec["dates"][0]}",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: subTextColor,
                                                      ),
                                                    ),
                                                    if ((rec["dates"] as List)
                                                            .length >
                                                        1)
                                                      Text(
                                                        "End date: ${rec["dates"][1]}",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: subTextColor,
                                                        ),
                                                      ),
                                                    if (rec["reminderTime"] !=
                                                        null)
                                                      Text(
                                                        "Time: ${rec["reminderTime"]}",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: subTextColor,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor(
                                                rec["status"] ?? ''),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            rec["status"] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await FirestoreService()
                                                  .updateVaccinationReminder(
                                                rec['id'],
                                                {'status': 'Completed'},
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Vaccination marked as completed'),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Completed',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await FirestoreService()
                                                  .updateVaccinationReminder(
                                                rec['id'],
                                                {'status': 'Missed'},
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Vaccination marked as missed'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Missed',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20), // Add bottom padding
        ],
      ),
    );
  }
}
