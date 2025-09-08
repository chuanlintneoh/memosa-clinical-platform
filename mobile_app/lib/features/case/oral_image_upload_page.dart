import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_card.dart';

class OralImageUploadPage extends StatefulWidget {
  const OralImageUploadPage({super.key});

  @override
  State<OralImageUploadPage> createState() => _OralImageUploadPageState();
}

class _OralImageUploadPageState extends State<OralImageUploadPage> {
  final List<XFile?> _images = List.filled(9, null);
  final ImagePicker _picker = ImagePicker();

  void _pickImage(int index) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedImage != null) {
      setState(() {
        _images[0] = pickedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oral Cavity Images of 9 Areas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.0),
            Text(
              'Upload images for each designated region of the mouth.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: GridView.count(
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                crossAxisCount: 2,
                children: [
                  ImageCard(
                    title: 'IMG1: Tongue',
                    imageFile: _images[0],
                    onTap: () => _pickImage(0),
                  ),
                  ImageCard(
                    title: 'IMG2: Below Tongue',
                    imageFile: _images[1],
                    onTap: () => _pickImage(1),
                  ),
                  ImageCard(
                    title: 'IMG3: Left of Tongue',
                    imageFile: _images[2],
                    onTap: () => _pickImage(2),
                  ),
                  ImageCard(
                    title: 'IMG4: Right of Tongue',
                    imageFile: _images[3],
                    onTap: () => _pickImage(3),
                  ),
                  ImageCard(
                    title: 'IMG5: Palate',
                    imageFile: _images[4],
                    onTap: () => _pickImage(4),
                  ),
                  ImageCard(
                    title: 'IMG6: Left Cheek',
                    imageFile: _images[5],
                    onTap: () => _pickImage(5),
                  ),
                  ImageCard(
                    title: 'IMG7: Right Cheek',
                    imageFile: _images[6],
                    onTap: () => _pickImage(6),
                  ),
                  ImageCard(
                    title: 'IMG8: Upper Lip / Gum',
                    imageFile: _images[7],
                    onTap: () => _pickImage(7),
                  ),
                  ImageCard(
                    title: 'IMG9: Lower Lip / Gum',
                    imageFile: _images[8],
                    onTap: () => _pickImage(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
