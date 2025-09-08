import 'package:flutter/material.dart';

class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // wrap with Align to allow the child to take its intrinsic size,
    // even PageView offers more space.
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
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Patient Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Full Name',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                DropdownMenu(
                  label: Text('ID Type'),
                  enableSearch: false,
                  dropdownMenuEntries: <DropdownMenuEntry<int>>[
                    DropdownMenuEntry(value: 1, label: 'IC'),
                    DropdownMenuEntry(value: 2, label: 'Passport'),
                  ],
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Patient ID',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date of Birth',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Age',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            DropdownMenu(
              width: double.infinity,
              label: Text('Gender'),
              enableSearch: false,
              dropdownMenuEntries: <DropdownMenuEntry<String>>[
                DropdownMenuEntry(value: 'Male', label: 'Male'),
                DropdownMenuEntry(value: 'Female', label: 'Female'),
              ],
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
              ),
            ),
          ],
        ),
      ),
    );
  }
}