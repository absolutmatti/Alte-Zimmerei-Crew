import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'custom_text_field.dart';

class DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? initialValue;
  final Function(DateTime) onChanged;
  final bool showTime;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTimePicker({
    Key? key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.showTime = true,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: initialValue != null
          ? showTime
              ? DateFormat('dd.MM.yyyy HH:mm').format(initialValue!)
              : DateFormat('dd.MM.yyyy').format(initialValue!)
          : '',
    );

    return CustomTextField(
      controller: controller,
      label: label,
      enabled: false,
      suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
      onTap: () => _showPicker(context, controller),
    );
  }

  Future<void> _showPicker(
      BuildContext context, TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = initialValue ?? now;
    final DateTime firstPickerDate = firstDate ?? now.subtract(const Duration(days: 365));
    final DateTime lastPickerDate = lastDate ?? now.add(const Duration(days: 365 * 5));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstPickerDate,
      lastDate: lastPickerDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
            dialogBackgroundColor: AppColors.surface,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    TimeOfDay initialTime = TimeOfDay.fromDateTime(initialValue ?? now);
    
    if (showTime) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: AppColors.onPrimary,
                surface: AppColors.surface,
                onSurface: AppColors.onSurface,
              ),
              dialogBackgroundColor: AppColors.surface,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime == null) return;

      final DateTime result = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      controller.text = DateFormat('dd.MM.yyyy HH:mm').format(result);
      onChanged(result);
    } else {
      final DateTime result = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      controller.text = DateFormat('dd.MM.yyyy').format(result);
      onChanged(result);
    }
  }
}

