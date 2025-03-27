import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? image;
  final Function(File) onImagePicked;
  final String label;
  final double height;
  final double width;
  final bool isCircular;

  const ImagePickerWidget({
    Key? key,
    this.image,
    required this.onImagePicked,
    required this.label,
    this.height = 200,
    this.width = double.infinity,
    this.isCircular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyText2,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceDialog(context),
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
                    child: Image.file(
                      image!,
                      fit: BoxFit.cover,
                      height: height,
                      width: width,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        color: AppColors.primary,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.inactive,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Select Image Source',
          style: AppTextStyles.headline3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Gallery', style: AppTextStyles.bodyText1),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Camera', style: AppTextStyles.bodyText1),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }
}

