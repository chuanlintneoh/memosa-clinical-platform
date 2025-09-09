import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({super.key, this.title, this.imageFile, this.onTap});

  final String? title;
  final XFile? imageFile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
          ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.all(1.0),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: Radius.circular(12.0),
                  dashPattern: [5.0, 2.0],
                ),
                child: Center(
                  child: imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined),
                            Text(
                              'Tap to Add Image',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : Image.file(
                          File(imageFile!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
