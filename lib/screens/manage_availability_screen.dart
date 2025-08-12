import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final List<bool> _selectedDays = List.generate(7, (index) => false);
  final List<TimeOfDay> _startTimes =
      List.generate(7, (index) => const TimeOfDay(hour: 9, minute: 0));
  final List<TimeOfDay> _endTimes =
      List.generate(7, (index) => const TimeOfDay(hour: 17, minute: 0));
  bool _isLoading = false;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['availability'] != null) {
          final availability =
              doc.data()!['availability'] as Map<String, dynamic>;
          for (var i = 0; i < 7; i++) {
            final day = _weekDays[i].toLowerCase();
            if (availability[day] != null) {
              final dayData = availability[day] as Map<String, dynamic>;
              setState(() {
                _selectedDays[i] = dayData['available'] as bool;
                if (dayData['startTime'] != null) {
                  final startTime = dayData['startTime'] as String;
                  final parts = startTime.split(':');
                  _startTimes[i] = TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  );
                }
                if (dayData['endTime'] != null) {
                  final endTime = dayData['endTime'] as String;
                  final parts = endTime.split(':');
                  _endTimes[i] = TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading availability: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final availability = <String, dynamic>{};
        for (var i = 0; i < 7; i++) {
          availability[_weekDays[i].toLowerCase()] = {
            'available': _selectedDays[i],
            'startTime': '${_startTimes[i].hour}:${_startTimes[i].minute}',
            'endTime': '${_endTimes[i].hour}:${_endTimes[i].minute}',
          };
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'availability': availability});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability saved successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error saving availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving availability: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(
      BuildContext context, int index, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTimes[index] : _endTimes[index],
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[index] = picked;
        } else {
          _endTimes[index] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _weekDays[index],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: _selectedDays[index],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDays[index] = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_selectedDays[index]) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _selectTime(context, index, true),
                                  icon: const Icon(Icons.access_time),
                                  label: Text(
                                    'Start: ${_startTimes[index].format(context)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _selectTime(context, index, false),
                                  icon: const Icon(Icons.access_time),
                                  label: Text(
                                    'End: ${_endTimes[index].format(context)}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAvailability,
            child: const Text('Save Availability'),
          ),
        ),
      ),
    );
  }
}
