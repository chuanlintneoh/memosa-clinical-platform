import 'package:flutter/material.dart';

import 'image_card.dart';

class OralImageUploadPage extends StatelessWidget {
  const OralImageUploadPage({super.key});

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
                    onTap: () {
                      debugPrint('Tapped on IMG1: Tongue');
                    },
                  ),
                  ImageCard(title: 'IMG2: Below Tongue'),
                  ImageCard(title: 'IMG3: Left of Tongue'),
                  ImageCard(title: 'IMG4: Right of Tongue'),
                  ImageCard(title: 'IMG5: Palate'),
                  ImageCard(title: 'IMG6: Left Cheek'),
                  ImageCard(title: 'IMG7: Right Cheek'),
                  ImageCard(title: 'IMG8: Upper Lip / Gum'),
                  ImageCard(title: 'IMG9: Lower Lip / Gum'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
