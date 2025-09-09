// Used for create new case and edit case draft, can choose to delete draft / save draft / submit
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/case.dart';
import 'image_card.dart';
import '../../../core/services/dbmanager.dart';

class CreateCaseScreen extends StatefulWidget {
  final Map<String, dynamic>? draft;
  final int? draftIndex;

  const CreateCaseScreen({super.key, this.draft, this.draftIndex});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final String caseId;
  late final DateTime createdAt;

  final _nameController = TextEditingController();
  IdType? _idType;
  final _idNumController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;
  final _ethnicityController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _attendingHospitalController = TextEditingController();
  File? _consentForm;
  Habit? _smoking;
  final _smokingDurationController = TextEditingController();
  Habit? _betelQuid;
  final _betelQuidDurationController = TextEditingController();
  Habit? _alcohol;
  final _alcoholDurationController = TextEditingController();
  final _lesionClinicialPresentationController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _presentingComplaintHistoryController = TextEditingController();
  final _medicationHistoryController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  bool? _slsContainingToothpaste;
  final _slsContainingToothpasteUsedController = TextEditingController();
  bool? _oralHygieneProductsUsed;
  final _oralHygieneProductTypeUsedController = TextEditingController();
  final _additionalCommentsController = TextEditingController();
  final List<XFile?> _images = List.filled(9, null);

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    if (widget.draft != null) {
      final draft = widget.draft!;

      T? parseEnum<T extends Enum>(List<T> values, String? value) {
        if (value == null) return null;
        try {
          return values.firstWhere((e) => e.name == value);
        } catch (_) {
          return null;
        }
      }

      caseId = draft['caseId'];
      createdAt = DateTime.parse(draft['createdAt']);

      _nameController.text = draft['name'] ?? '';
      _idType = parseEnum<IdType>(IdType.values, draft['idType']);
      _idNumController.text = draft['idNum'] ?? '';
      _dobController.text = draft['dob'] ?? '';

      if (draft['dob'] != null && draft['dob'].isNotEmpty) {
        final dob = DateTime.tryParse(draft['dob']);
        if (dob != null) {
          final today = DateTime.now();
          int age = today.year - dob.year;
          if (today.month < dob.month ||
              (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          _ageController.text = age.toString();
        }
      }

      _gender = parseEnum<Gender>(Gender.values, draft['gender']);
      _ethnicityController.text = draft['ethnicity'] ?? '';
      _phoneNumberController.text = draft['phoneNumber'] ?? '';
      _addressController.text = draft['address'] ?? '';
      _attendingHospitalController.text = draft['attendingHospital'] ?? '';
      _consentForm = draft['consentForm'] != null
          ? File(draft['consentForm'])
          : null;
      _smoking = parseEnum<Habit>(Habit.values, draft['smoking']);
      _smokingDurationController.text = draft['smokingDuration'] ?? '';
      _betelQuid = parseEnum<Habit>(Habit.values, draft['betelQuid']);
      _betelQuidDurationController.text = draft['betelQuidDuration'] ?? '';
      _alcohol = parseEnum<Habit>(Habit.values, draft['alcohol']);
      _alcoholDurationController.text = draft['alcoholDuration'] ?? '';
      _lesionClinicialPresentationController.text =
          draft['lesionClinicalPresentation'] ?? '';
      _chiefComplaintController.text = draft['chiefComplaint'] ?? '';
      _presentingComplaintHistoryController.text =
          draft['presentingComplaintHistory'] ?? '';
      _medicationHistoryController.text = draft['medicationHistory'] ?? '';
      _medicalHistoryController.text = draft['medicalHistory'] ?? '';
      _slsContainingToothpaste = draft['slsContainingToothpaste'];
      _slsContainingToothpasteUsedController.text =
          draft['slsContainingToothpasteUsed'] ?? '';
      _oralHygieneProductsUsed = draft['oralHygieneProductsUsed'];
      _oralHygieneProductTypeUsedController.text =
          draft['oralHygieneProductTypeUsed'] ?? '';
      _additionalCommentsController.text = draft['additionalComments'] ?? '';

      final imagePaths = (draft['images'] as List?)?.cast<String?>();
      if (imagePaths != null) {
        for (int i = 0; i < imagePaths.length && i < _images.length; i++) {
          if (imagePaths[i] != null) {
            _images[i] = XFile(imagePaths[i]!);
          }
        }
      }
    } else {
      caseId = const Uuid().v4();
      createdAt = DateTime.now();
    }
  }

  void _deleteDraft() {
    Navigator.pop(context, {'action': 'delete', 'index': widget.draftIndex});
  }

  void _saveDraft() {
    Navigator.pop(context, {
      'action': 'save',
      'index': widget.draftIndex,
      'data': {
        'caseId': caseId,
        'createdAt': createdAt.toString(),
        'name': _nameController.text,
        'idType': _idType?.name,
        'idNum': _idNumController.text,
        'dob': _dobController.text,
        'gender': _gender?.name,
        'ethnicity': _ethnicityController.text,
        'phoneNumber': _phoneNumberController.text,
        'address': _addressController.text,
        'attendingHospital': _attendingHospitalController.text,
        'consentForm': _consentForm?.path,
        'smoking': _smoking?.name,
        'smokingDuration': _smokingDurationController.text,
        'betelQuid': _betelQuid?.name,
        'betelQuidDuration': _betelQuidDurationController.text,
        'alcohol': _alcohol?.name,
        'alcoholDuration': _alcoholDurationController.text,
        'lesionClinicalPresentation':
            _lesionClinicialPresentationController.text,
        'chiefComplaint': _chiefComplaintController.text,
        'presentingComplaintHistory':
            _presentingComplaintHistoryController.text,
        'medicationHistory': _medicationHistoryController.text,
        'medicalHistory': _medicalHistoryController.text,
        'slsContainingToothpaste': _slsContainingToothpaste,
        'slsContainingToothpasteUsed':
            _slsContainingToothpasteUsedController.text,
        'oralHygieneProductsUsed': _oralHygieneProductsUsed,
        'oralHygieneProductTypeUsed':
            _oralHygieneProductTypeUsedController.text,
        'additionalComments': _additionalCommentsController.text,
        'images': _images.map((e) => e?.path).toList(),
      },
    });
  }

  Future<void> _submitCase() async {
    if (_formKey.currentState!.validate()) {
      DateTime? dob = _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text)
          : null;

      Uint8List? consentBytes = _consentForm != null
          ? await _consentForm!.readAsBytes()
          : null;

      List<Uint8List?> imageBytes = [];
      for (var img in _images) {
        if (img != null) {
          imageBytes.add(await File(img.path).readAsBytes());
        } else {
          imageBytes.add(null);
        }
      }

      String? result = await DbManagerService.createCase(
        caseId: caseId,
        publicData: PublicCaseModel(
          createdAt: createdAt,
          createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          alcohol: _alcohol!,
          alcoholDuration: _alcoholDurationController.text,
          betelQuid: _betelQuid!,
          betelQuidDuration: _betelQuidDurationController.text,
          smoking: _smoking!,
          smokingDuration: _smokingDurationController.text,
          oralHygieneProductsUsed: _oralHygieneProductsUsed ?? false,
          oralHygieneProductTypeUsed:
              _oralHygieneProductTypeUsedController.text,
          slsContainingToothpaste: _slsContainingToothpaste ?? false,
          slsContainingToothpasteUsed:
              _slsContainingToothpasteUsedController.text,
          additionalComments: _additionalCommentsController.text,
        ),
        privateData: PrivateCaseModel(
          address: _addressController.text,
          age: _ageController.text,
          attendingHospital: _attendingHospitalController.text,
          chiefComplaint: _chiefComplaintController.text,
          consentForm: consentBytes ?? Uint8List(0),
          dob: dob!,
          ethnicity: _ethnicityController.text,
          gender: _gender!,
          idNum: _idNumController.text,
          idType: _idType!,
          lesionClinicalPresentation:
              _lesionClinicialPresentationController.text,
          medicalHistory: _medicalHistoryController.text,
          medicationHistory: _medicationHistoryController.text,
          name: _nameController.text,
          phoneNum: _phoneNumberController.text,
          presentingComplaintHistory:
              _presentingComplaintHistoryController.text,
          images: imageBytes.whereType<Uint8List>().toList(),
        ),
      );

      if (result == caseId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case submitted successfully')),
        );
        Navigator.pop(context, {
          'action': 'submit',
          'index': widget.draftIndex,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting case: $result')),
        );
      }
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirm();
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    bool multiline = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: multiline ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: readOnly
            ? IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("$label copied")));
                },
              )
            : null,
        border: readOnly ? const OutlineInputBorder() : null,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> values,
    void Function(T?) onChanged,
  ) {
    String displayValue(dynamic e) {
      if (e is Enum) return e.name;
      if (e is bool) return e ? "YES" : "NO";
      return e.toString();
    }

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((e) => DropdownMenuItem(value: e, child: Text(displayValue(e))))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Select $label" : null,
    );
  }

  Future<void> _pickDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = "${pickedDate.toLocal()}".split(' ')[0];

        // calculate age
        final today = DateTime.now();
        int age = today.year - pickedDate.year;
        if (today.month < pickedDate.month ||
            (today.month == pickedDate.month && today.day < pickedDate.day)) {
          age--;
        }

        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickConsentForm() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _consentForm = File(result.files.single.path!);
      });
    }
  }

  void _pickImage(int index) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedImage != null) {
      setState(() {
        _images[index] = pickedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Case")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField(
                      TextEditingController(text: caseId),
                      "Case ID",
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      TextEditingController(text: createdAt.toString()),
                      "Created At",
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(_nameController, "Full Name"),
                    const SizedBox(height: 8),

                    Text("ID"),
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildDropdown<IdType>(
                            "Type",
                            _idType,
                            IdType.values,
                            (val) => setState(() => _idType = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 65,
                          child: _buildTextField(_idNumController, "Number"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 65,
                          child: TextFormField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: "Date of Birth",
                            ),
                            readOnly: true,
                            onTap: _pickDateOfBirth,
                            validator: (value) => value == null || value.isEmpty
                                ? "Select Date of Birth"
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 35,
                          child: TextFormField(
                            controller: _ageController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Age",
                              // filled: true,
                              // fillColor: Colors.grey,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildDropdown<Gender>(
                      "Gender",
                      _gender,
                      Gender.values,
                      (val) => setState(() => _gender = val),
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(_ethnicityController, "Ethnicity"),
                    const SizedBox(height: 8),

                    _buildTextField(_phoneNumberController, "Phone Number"),
                    const SizedBox(height: 8),

                    _buildTextField(_addressController, "Address"),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _attendingHospitalController,
                      "Attending Hospital",
                    ),
                    const SizedBox(height: 8),

                    Text("Consent Form"),
                    ElevatedButton.icon(
                      onPressed: _pickConsentForm,
                      icon: _consentForm != null
                          ? const Icon(Icons.edit)
                          : const Icon(Icons.upload_file),
                      label: _consentForm != null
                          ? Text(
                              "Replace: ${_consentForm!.path.split('/').last}",
                            )
                          : const Text("Upload"),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildDropdown<Habit>(
                            "Smoking",
                            _smoking,
                            Habit.values,
                            (val) => setState(() => _smoking = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            _smokingDurationController,
                            "Duration",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildDropdown<Habit>(
                            "Betel Quid",
                            _betelQuid,
                            Habit.values,
                            (val) => setState(() => _betelQuid = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            _betelQuidDurationController,
                            "Duration",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildDropdown<Habit>(
                            "Alcohol",
                            _alcohol,
                            Habit.values,
                            (val) => setState(() => _alcohol = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            _alcoholDurationController,
                            "Duration",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _lesionClinicialPresentationController,
                      "Lesion Clinical Presentation",
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _chiefComplaintController,
                      "Chief Complaint",
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _presentingComplaintHistoryController,
                      "Presenting Complaint History",
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _medicationHistoryController,
                      "Medication History",
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _medicalHistoryController,
                      "Medical History",
                    ),
                    const SizedBox(height: 8),

                    Text("SLS Containing Toothpaste"),
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildDropdown<bool>(
                            "Used",
                            _slsContainingToothpaste,
                            [true, false],
                            (val) =>
                                setState(() => _slsContainingToothpaste = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 65,
                          child: _buildTextField(
                            _slsContainingToothpasteUsedController,
                            "Type",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text("Oral Hygiene Products"),
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildDropdown<bool>(
                            "Used",
                            _oralHygieneProductsUsed,
                            [true, false],
                            (val) =>
                                setState(() => _oralHygieneProductsUsed = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 65,
                          child: _buildTextField(
                            _oralHygieneProductTypeUsedController,
                            "Type",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _additionalCommentsController,
                      "Additional Comments",
                      multiline: true,
                    ),
                    const SizedBox(height: 8),

                    Align(
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
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16.0,
                              crossAxisSpacing: 16.0,
                              crossAxisCount: 2,
                              children: [
                                ImageCard(
                                  title: 'IMG1:\nTongue',
                                  imageFile: _images[0],
                                  onTap: () => _pickImage(0),
                                ),
                                ImageCard(
                                  title: 'IMG2:\nBelow Tongue',
                                  imageFile: _images[1],
                                  onTap: () => _pickImage(1),
                                ),
                                ImageCard(
                                  title: 'IMG3:\nLeft of Tongue',
                                  imageFile: _images[2],
                                  onTap: () => _pickImage(2),
                                ),
                                ImageCard(
                                  title: 'IMG4:\nRight of Tongue',
                                  imageFile: _images[3],
                                  onTap: () => _pickImage(3),
                                ),
                                ImageCard(
                                  title: 'IMG5:\nPalate',
                                  imageFile: _images[4],
                                  onTap: () => _pickImage(4),
                                ),
                                ImageCard(
                                  title: 'IMG6:\nLeft Cheek',
                                  imageFile: _images[5],
                                  onTap: () => _pickImage(5),
                                ),
                                ImageCard(
                                  title: 'IMG7:\nRight Cheek',
                                  imageFile: _images[6],
                                  onTap: () => _pickImage(6),
                                ),
                                ImageCard(
                                  title: 'IMG8:\nUpper Lip / Gum',
                                  imageFile: _images[7],
                                  onTap: () => _pickImage(7),
                                ),
                                ImageCard(
                                  title: 'IMG9:\nLower Lip / Gum',
                                  imageFile: _images[8],
                                  onTap: () => _pickImage(8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.draftIndex != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        _confirmAction(
                          title: "Delete Draft",
                          message:
                              "Are you sure you want to delete this draft?",
                          onConfirm: _deleteDraft,
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Save Draft",
                        message:
                            "Are you sure you want to save this draft? You can continue editing it later.",
                        onConfirm: _saveDraft,
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Save Draft"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Submit Case",
                        message: "Are you sure you want to submit this case?",
                        onConfirm: _submitCase,
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
