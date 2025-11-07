// Used for create new case and edit case draft, can choose to delete draft / save draft / submit
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:mobile_app/features/roles/study_coordinator/image_card.dart';
import 'package:nanoid2/nanoid2.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CreateCaseScreen extends StatefulWidget {
  final Map<String, dynamic>? draft;
  final int? draftIndex;

  const CreateCaseScreen({super.key, this.draft, this.draftIndex});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  late final String caseId;
  late final DateTime createdAt;

  final _nameController = TextEditingController();
  IdType? _idType;
  final _idNumController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;
  Ethnicity? _ethnicity;
  final _ethnicityOthersController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _attendingHospitalController = TextEditingController();
  File? _consentForm;
  Habit? _smoking;
  final _smokingDurationController = TextEditingController();
  DurationUnit? _smokingDurationUnit;
  Habit? _betelQuid;
  final _betelQuidDurationController = TextEditingController();
  DurationUnit? _betelQuidDurationUnit;
  Habit? _alcohol;
  final _alcoholDurationController = TextEditingController();
  DurationUnit? _alcoholDurationUnit;
  final _lesionClinicalPresentationController = TextEditingController();
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

      // Parse ethnicity - check if it's an enum value or "OTHERS"
      final ethnicityStr = draft['ethnicity'] ?? '';
      final parsedEthnicity = parseEnum<Ethnicity>(
        Ethnicity.values,
        ethnicityStr,
      );
      if (parsedEthnicity != null) {
        _ethnicity = parsedEthnicity;
        if (parsedEthnicity == Ethnicity.OTHERS) {
          _ethnicityOthersController.text = draft['ethnicityOthers'] ?? '';
        }
      } else if (ethnicityStr.isNotEmpty) {
        // It's a custom ethnicity string, set to OTHERS
        _ethnicity = Ethnicity.OTHERS;
        _ethnicityOthersController.text = ethnicityStr;
      }

      _phoneNumberController.text = draft['phoneNumber'] ?? '';
      _addressController.text = draft['address'] ?? '';
      _attendingHospitalController.text = draft['attendingHospital'] ?? '';
      _consentForm = draft['consentForm'] != null
          ? File(draft['consentForm'])
          : null;
      _smoking = parseEnum<Habit>(Habit.values, draft['smoking']);
      _parseDuration(
        draft['smokingDuration'],
        _smokingDurationController,
        (unit) => _smokingDurationUnit = unit,
      );
      _betelQuid = parseEnum<Habit>(Habit.values, draft['betelQuid']);
      _parseDuration(
        draft['betelQuidDuration'],
        _betelQuidDurationController,
        (unit) => _betelQuidDurationUnit = unit,
      );
      _alcohol = parseEnum<Habit>(Habit.values, draft['alcohol']);
      _parseDuration(
        draft['alcoholDuration'],
        _alcoholDurationController,
        (unit) => _alcoholDurationUnit = unit,
      );
      _lesionClinicalPresentationController.text =
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
      caseId = nanoid(length: 8);
      createdAt = DateTime.now();
    }
  }

  void _parseDuration(
    String? durationStr,
    TextEditingController controller,
    Function(DurationUnit?) setUnit,
  ) {
    if (durationStr == null || durationStr.isEmpty) {
      controller.text = '';
      setUnit(null);
      return;
    }

    // Parse format: "2 YEARS" into number and unit
    final parts = durationStr.trim().split(' ');
    if (parts.length >= 2) {
      controller.text = parts[0];
      final unitStr = parts.sublist(1).join(' ');
      try {
        final unit = DurationUnit.values.firstWhere(
          (e) => e.name == unitStr,
          orElse: () => DurationUnit.YEARS,
        );
        setUnit(unit);
      } catch (_) {
        setUnit(DurationUnit.YEARS);
      }
    } else {
      controller.text = durationStr;
      setUnit(null);
    }
  }

  String _combineDuration(String number, DurationUnit? unit) {
    if (number.isEmpty || unit == null) {
      return '';
    }
    return '$number ${unit.name}';
  }

  void _deriveAndSetDobFromNric(String idNum) {
    // Only process if ID type is NRIC and we have at least 6 digits
    if (_idType != IdType.NRIC || idNum.length < 6) {
      return;
    }

    try {
      // Extract first 6 digits (YYMMDD)
      final yearStr = idNum.substring(0, 2);
      final monthStr = idNum.substring(2, 4);
      final dayStr = idNum.substring(4, 6);

      final year = int.parse(yearStr);
      final month = int.parse(monthStr);
      final day = int.parse(dayStr);

      // Validate month and day ranges
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        setState(() {
          _dobController.clear();
          _ageController.clear();
        });
        return;
      }

      // Get current date in Malaysia timezone (UTC+8)
      final nowUtc = DateTime.now().toUtc();
      final malaysiaOffset = const Duration(hours: 8);
      final today = nowUtc.add(malaysiaOffset);

      final currentYearTwoDigit = today.year % 100;
      final currentMonth = today.month;
      final currentDay = today.day;

      int fullYear;

      // If the year from NRIC is greater than current year's last two digits,
      // it must be from the previous century (1900s)
      if (year > currentYearTwoDigit) {
        fullYear = 1900 + year;
      } else if (year < currentYearTwoDigit) {
        // If year is less than current year, it could be 2000s
        fullYear = 2000 + year;
      } else {
        // Same year - check month and day
        if (month > currentMonth ||
            (month == currentMonth && day > currentDay)) {
          // Date hasn't occurred yet this year, must be from 1900s
          fullYear = 1900 + year;
        } else {
          // Date has occurred or is today, could be from 2000s
          fullYear = 2000 + year;
        }
      }

      // Try to create the date to validate it
      final dob = DateTime(fullYear, month, day);

      // Check if the date is valid and not in the future (compared to Malaysia time)
      if (dob.isAfter(today)) {
        setState(() {
          _dobController.clear();
          _ageController.clear();
        });
        return;
      }

      // Set the DOB
      setState(() {
        _dobController.text = "${dob.toLocal()}".split(' ')[0];

        // Calculate age
        int age = today.year - dob.year;
        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          age--;
        }

        _ageController.text = age.toString();
      });
    } catch (e) {
      // If any parsing fails or date is invalid, clear the DOB
      setState(() {
        _dobController.clear();
        _ageController.clear();
      });
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
        'ethnicity': _ethnicity == Ethnicity.OTHERS
            ? _ethnicityOthersController.text
            : (_ethnicity?.name ?? ''),
        'ethnicityOthers': _ethnicity == Ethnicity.OTHERS
            ? _ethnicityOthersController.text
            : '',
        'phoneNumber': _phoneNumberController.text,
        'address': _addressController.text,
        'attendingHospital': _attendingHospitalController.text,
        'consentForm': _consentForm?.path,
        'smoking': _smoking?.name,
        'smokingDuration': _combineDuration(
          _smokingDurationController.text,
          _smokingDurationUnit,
        ),
        'betelQuid': _betelQuid?.name,
        'betelQuidDuration': _combineDuration(
          _betelQuidDurationController.text,
          _betelQuidDurationUnit,
        ),
        'alcohol': _alcohol?.name,
        'alcoholDuration': _combineDuration(
          _alcoholDurationController.text,
          _alcoholDurationUnit,
        ),
        'lesionClinicalPresentation':
            _lesionClinicalPresentationController.text,
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
    if (!_formKey.currentState!.validate()) {
      // Enable autovalidation so errors persist when scrolling
      // Wait for the next frame to avoid ChangeNotifier disposal issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _autovalidateMode = AutovalidateMode.always;
          });
        }
      });
      return;
    }

    String dialogMessage = "The case is being submitted at the moment.";
    bool inProgress = true;
    String? returnedCaseId;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: const Text("Submitting Case"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inProgress) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(dialogMessage),
                  if (returnedCaseId != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            returnedCaseId!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: returnedCaseId!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Case ID copied")),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                if (!inProgress)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (returnedCaseId != null) {
                        Navigator.pop(context, {
                          'action': 'submit',
                          'index': widget.draftIndex,
                        });
                      }
                    },
                    child: const Text("Close"),
                  ),
              ],
            );
          },
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId =
          prefs.getString("userId") ??
          FirebaseAuth.instance.currentUser?.uid ??
          "unknown";
      if (userId == "unknown") {
        throw Exception("User ID not found. Please log in and try again.");
      }

      DateTime? dob = _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text)
          : null;

      String consentFormType = _consentForm != null
          ? _consentForm!.path.split('.').last.toLowerCase()
          : "NULL";
      String consentBytes = "NULL";
      if (_consentForm != null) {
        final bytes = await _consentForm!.readAsBytes();
        consentBytes = base64Encode(bytes);
      }
      final consentForm = {
        "fileType": consentFormType,
        "fileBytes": consentBytes,
      };

      List<Uint8List> imageBytes = [];
      for (var img in _images) {
        imageBytes.add(await File(img!.path).readAsBytes());
      }

      final publicData = PublicCaseModel(
        createdAt: createdAt,
        createdBy: userId,
        alcohol: _alcohol!,
        alcoholDuration: _combineDuration(
          _alcoholDurationController.text,
          _alcoholDurationUnit,
        ),
        betelQuid: _betelQuid!,
        betelQuidDuration: _combineDuration(
          _betelQuidDurationController.text,
          _betelQuidDurationUnit,
        ),
        smoking: _smoking!,
        smokingDuration: _combineDuration(
          _smokingDurationController.text,
          _smokingDurationUnit,
        ),
        oralHygieneProductsUsed: _oralHygieneProductsUsed ?? false,
        oralHygieneProductTypeUsed: _oralHygieneProductTypeUsedController.text,
        slsContainingToothpaste: _slsContainingToothpaste ?? false,
        slsContainingToothpasteUsed:
            _slsContainingToothpasteUsedController.text,
        additionalComments: _additionalCommentsController.text,
      );

      final privateData = PrivateCaseModel(
        address: _addressController.text,
        age: _ageController.text,
        attendingHospital: _attendingHospitalController.text,
        chiefComplaint: _chiefComplaintController.text,
        consentForm: consentForm,
        dob: dob!,
        ethnicity: _ethnicity == Ethnicity.OTHERS
            ? _ethnicityOthersController.text
            : (_ethnicity?.name ?? ''),
        gender: _gender!,
        idNum: _idNumController.text,
        idType: _idType!,
        lesionClinicalPresentation: _lesionClinicalPresentationController.text,
        medicalHistory: _medicalHistoryController.text,
        medicationHistory: _medicationHistoryController.text,
        name: _nameController.text,
        phoneNum: _phoneNumberController.text,
        presentingComplaintHistory: _presentingComplaintHistoryController.text,
        images: imageBytes,
      );

      String? result = await DbManagerService.createCase(
        caseId: caseId,
        publicData: publicData,
        privateData: privateData,
      );

      dialogSetState?.call(() {
        inProgress = false;
        returnedCaseId = result;
        if (result == null) {
          dialogMessage = "Failed to submit case, please try again.";
          returnedCaseId = null;
        } else if (result == caseId) {
          dialogMessage = "Case submitted successfully with the same Case ID:";
        } else {
          dialogMessage =
              "Case submitted successfully with a new unique Case ID generated by server:";
        }
      });
    } catch (e) {
      dialogSetState?.call(() {
        inProgress = false;
        returnedCaseId = null;
        dialogMessage = "Error submitting case: $e";
      });
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
    bool required = true,
    RegExp? allowedChars,
    bool readOnly = false,
    bool multiline = false,
    String? Function(String?)? extraValidator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: multiline ? 4 : 1,
      inputFormatters: allowedChars != null
          ? [FilteringTextInputFormatter.allow(allowedChars)]
          : null,
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
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return "Enter $label";
        }
        if (extraValidator != null) {
          return extraValidator(value);
        }
        return null;
      },
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> values,
    void Function(T?) onChanged, {
    bool required = true,
  }) {
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
      validator: (val) {
        if (required && val == null) {
          return "Select $label";
        }
        return null;
      },
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

  Future<void> _viewConsentForm() async {
    if (_consentForm == null) return;

    try {
      final fileBytes = await _consentForm!.readAsBytes();
      final fileType = _consentForm != null
          ? _consentForm!.path.split('.').last
          : "NULL";
      switch (fileType.toLowerCase()) {
        case "jpg":
        case "jpeg":
        case "png":
        // case "gif":
        case "webp":
        case "bmp":
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // Zoomable image
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: Image.memory(fileBytes, fit: BoxFit.cover),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  // Image title
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "File as ${fileType.toLowerCase()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Zoom instructions
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Pinch to zoom • Drag to pan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case "pdf":
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("File as ${fileType.toLowerCase()}"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: SfPdfViewer.memory(fileBytes),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
          break;

        case "doc":
        case "docx":
          final tempDir = await getTemporaryDirectory();
          final filePath = "${tempDir.path}/temp.$fileType";
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);
          final result = await OpenFilex.open(filePath);
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "No app available to open ${fileType.toUpperCase()} file",
                ),
              ),
            );
          }
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Cannot preview file, unsupported file type ${fileType.toLowerCase()}",
              ),
            ),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to open file: $e")));
    }
  }

  Future<void> _showConsentFormSourceActionSheet([
    FormFieldState<File?>? fieldState,
  ]) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo of the consent form'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickConsentFormFromCamera(fieldState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Select an image from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickConsentFormFromGallery(fieldState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Files'),
                subtitle: const Text('Browse for PDF, DOC, or image files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickConsentFormFromFiles(fieldState);
                },
              ),
              if (_consentForm != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Consent Form',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _consentForm = null);
                    fieldState?.didChange(null);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickConsentFormFromCamera([
    FormFieldState<File?>? fieldState,
  ]) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (pickedImage != null) {
        final file = File(pickedImage.path);
        setState(() {
          _consentForm = file;
        });
        fieldState?.didChange(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
    }
  }

  Future<void> _pickConsentFormFromGallery([
    FormFieldState<File?>? fieldState,
  ]) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedImage != null) {
        final file = File(pickedImage.path);
        setState(() {
          _consentForm = file;
        });
        fieldState?.didChange(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _pickConsentFormFromFiles([
    FormFieldState<File?>? fieldState,
  ]) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          // 'gif',
          'webp',
          'bmp',
          'pdf',
          'doc',
          'docx',
        ],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _consentForm = file;
        });
        fieldState?.didChange(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<void> _showImageSourceActionSheet(int index) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromSource(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromSource(index, ImageSource.gallery);
                },
              ),
              if (_images[index] != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _images[index] = null);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(int index, ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Restrict to JPG only
      );

      if (pickedImage != null) {
        setState(() {
          _images[index] = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final maxWidth = isTablet ? 1200.0 : double.infinity;

        if (isTablet) {
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _buildTabletLayout(),
            ),
          );
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBasicInfoSection(),
        _buildPersonalDetailsSection(),
        _buildConsentFormSection(),
        _buildHabitsSection(),
        _buildClinicalInfoSection(),
        _buildOralHygieneSection(),
        _buildImagesSection(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  _buildPersonalDetailsSection(),
                  _buildConsentFormSection(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildHabitsSection(),
                  _buildClinicalInfoSection(),
                  _buildOralHygieneSection(),
                ],
              ),
            ),
          ],
        ),
        _buildImagesSection(),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      title: 'Case Information',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          TextEditingController(text: caseId),
          "Case ID",
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          TextEditingController(text: createdAt.toString()),
          "Created At",
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsSection() {
    return _buildSectionCard(
      title: 'Personal Details',
      icon: Icons.person_outline,
      children: [
        _buildTextField(
          _nameController,
          "Full Name",
          allowedChars: RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ'\- ]"),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildDropdown<IdType>("ID Type", _idType, IdType.values, (
                val,
              ) {
                setState(() {
                  _idType = val;
                  // Try to derive DOB when ID type changes to NRIC
                  if (val == IdType.NRIC && _idNumController.text.isNotEmpty) {
                    _deriveAndSetDobFromNric(_idNumController.text);
                  }
                });
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: TextFormField(
                controller: _idNumController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    _idType == IdType.NRIC
                        ? RegExp(r"[0-9]")
                        : RegExp(r"[A-Z0-9]"),
                  ),
                ],
                decoration: const InputDecoration(labelText: "ID Number"),
                onChanged: (value) {
                  // Auto-derive DOB from NRIC when user types
                  if (_idType == IdType.NRIC) {
                    _deriveAndSetDobFromNric(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter ID Number";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 65,
              child: TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  suffixIcon: Icon(Icons.calendar_today),
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
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown<Gender>(
          "Gender",
          _gender,
          Gender.values,
          (val) => setState(() => _gender = val),
        ),
        const SizedBox(height: 16),
        _buildDropdown<Ethnicity>("Ethnicity", _ethnicity, Ethnicity.values, (
          val,
        ) {
          setState(() {
            _ethnicity = val;
            // Clear the others field if not OTHERS
            if (val != Ethnicity.OTHERS) {
              _ethnicityOthersController.clear();
            }
          });
        }),
        if (_ethnicity == Ethnicity.OTHERS) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _ethnicityOthersController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z ]")),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return TextEditingValue(
                  text: newValue.text.toUpperCase(),
                  selection: newValue.selection,
                );
              }),
            ],
            decoration: const InputDecoration(
              labelText: "Specify Ethnicity",
              hintText: "Enter exact ethnicity",
            ),
            validator: (value) {
              if (_ethnicity == Ethnicity.OTHERS &&
                  (value == null || value.isEmpty)) {
                return "Enter exact ethnicity";
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          _phoneNumberController,
          "Phone Number",
          allowedChars: RegExp(r"[0-9]"),
        ),
        const SizedBox(height: 16),
        _buildTextField(_addressController, "Address"),
        const SizedBox(height: 16),
        _buildTextField(_attendingHospitalController, "Attending Hospital"),
      ],
    );
  }

  Widget _buildConsentFormSection() {
    return _buildSectionCard(
      title: 'Consent Form',
      icon: Icons.description_outlined,
      children: [
        FormField<File?>(
          initialValue: _consentForm,
          validator: (file) {
            if (file == null) return "Upload consent form";

            final maxMb = 5;
            try {
              final size = file.lengthSync();
              if (size > maxMb * 1024 * 1024) {
                return "File too large (max $maxMb MB)";
              }
            } catch (e) {
              return "Cannot access file";
            }
            return null;
          },
          builder: (fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _consentForm != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _consentForm != null ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _consentForm != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        size: 48,
                        color: _consentForm != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _consentForm != null
                            ? "Consent form uploaded"
                            : "No consent form uploaded",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showConsentFormSourceActionSheet(fieldState),
                        icon: _consentForm != null
                            ? const Icon(Icons.edit)
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _consentForm != null ? "Replace" : "Upload",
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _consentForm == null
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No consent form available"),
                                ),
                              )
                            : _viewConsentForm,
                        icon: const Icon(Icons.remove_red_eye),
                        label: const Text("View"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                if (fieldState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      fieldState.errorText ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHabitsSection() {
    return _buildSectionCard(
      title: 'Habits & Lifestyle',
      icon: Icons.smoking_rooms_outlined,
      children: [
        _buildDropdown<Habit>("Smoking", _smoking, Habit.values, (val) {
          setState(() {
            _smoking = val;
            if (val == Habit.NO) {
              _smokingDurationController.clear();
              _smokingDurationUnit = null;
            }
          });
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 45,
              child: TextFormField(
                controller: _smokingDurationController,
                enabled: _smoking != Habit.NO,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Duration (Number)",
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                validator: (value) {
                  if (_smoking != Habit.NO &&
                      (value == null || value.isEmpty)) {
                    return "Enter Number";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 55,
              child: IgnorePointer(
                ignoring: _smoking == Habit.NO,
                child: DropdownButtonFormField<DurationUnit>(
                  value: _smokingDurationUnit,
                  decoration: InputDecoration(
                    labelText: "Duration Unit",
                    filled: _smoking == Habit.NO,
                    fillColor: _smoking == Habit.NO
                        ? Colors.grey.withValues(alpha: 0.1)
                        : null,
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: DurationUnit.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: _smoking != Habit.NO
                      ? (val) => setState(() => _smokingDurationUnit = val)
                      : null,
                  validator: (val) {
                    if (_smoking != Habit.NO && val == null) {
                      return "Select Unit";
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown<Habit>("Betel Quid", _betelQuid, Habit.values, (val) {
          setState(() {
            _betelQuid = val;
            if (val == Habit.NO) {
              _betelQuidDurationController.clear();
              _betelQuidDurationUnit = null;
            }
          });
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 45,
              child: TextFormField(
                controller: _betelQuidDurationController,
                enabled: _betelQuid != Habit.NO,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Duration (Number)",
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                validator: (value) {
                  if (_betelQuid != Habit.NO &&
                      (value == null || value.isEmpty)) {
                    return "Enter Number";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 55,
              child: IgnorePointer(
                ignoring: _betelQuid == Habit.NO,
                child: DropdownButtonFormField<DurationUnit>(
                  value: _betelQuidDurationUnit,
                  decoration: InputDecoration(
                    labelText: "Duration Unit",
                    filled: _betelQuid == Habit.NO,
                    fillColor: _betelQuid == Habit.NO
                        ? Colors.grey.withValues(alpha: 0.1)
                        : null,
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: DurationUnit.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: _betelQuid != Habit.NO
                      ? (val) => setState(() => _betelQuidDurationUnit = val)
                      : null,
                  validator: (val) {
                    if (_betelQuid != Habit.NO && val == null) {
                      return "Select Unit";
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown<Habit>("Alcohol", _alcohol, Habit.values, (val) {
          setState(() {
            _alcohol = val;
            if (val == Habit.NO) {
              _alcoholDurationController.clear();
              _alcoholDurationUnit = null;
            }
          });
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 45,
              child: TextFormField(
                controller: _alcoholDurationController,
                enabled: _alcohol != Habit.NO,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Duration (Number)",
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                validator: (value) {
                  if (_alcohol != Habit.NO &&
                      (value == null || value.isEmpty)) {
                    return "Enter Number";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 55,
              child: IgnorePointer(
                ignoring: _alcohol == Habit.NO,
                child: DropdownButtonFormField<DurationUnit>(
                  value: _alcoholDurationUnit,
                  decoration: InputDecoration(
                    labelText: "Duration Unit",
                    filled: _alcohol == Habit.NO,
                    fillColor: _alcohol == Habit.NO
                        ? Colors.grey.withValues(alpha: 0.1)
                        : null,
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: DurationUnit.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: _alcohol != Habit.NO
                      ? (val) => setState(() => _alcoholDurationUnit = val)
                      : null,
                  validator: (val) {
                    if (_alcohol != Habit.NO && val == null) {
                      return "Select Unit";
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClinicalInfoSection() {
    return _buildSectionCard(
      title: 'Clinical Information',
      icon: Icons.medical_information_outlined,
      children: [
        _buildTextField(
          _lesionClinicalPresentationController,
          "Lesion Clinical Presentation",
        ),
        const SizedBox(height: 16),
        _buildTextField(_chiefComplaintController, "Chief Complaint"),
        const SizedBox(height: 16),
        _buildTextField(
          _presentingComplaintHistoryController,
          "Presenting Complaint History",
        ),
        const SizedBox(height: 16),
        _buildTextField(_medicationHistoryController, "Medication History"),
        const SizedBox(height: 16),
        _buildTextField(_medicalHistoryController, "Medical History"),
      ],
    );
  }

  Widget _buildOralHygieneSection() {
    return _buildSectionCard(
      title: 'Oral Hygiene',
      icon: Icons.clean_hands_outlined,
      children: [
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildDropdown<bool>(
                "SLS Toothpaste",
                _slsContainingToothpaste,
                [true, false],
                (val) {
                  setState(() {
                    _slsContainingToothpaste = val;
                    if (val == false) {
                      _slsContainingToothpasteUsedController.clear();
                    }
                  });
                },
                required: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: TextFormField(
                controller: _slsContainingToothpasteUsedController,
                enabled: _slsContainingToothpaste != false,
                decoration: InputDecoration(
                  labelText: "Type",
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildDropdown<bool>(
                "Other Products",
                _oralHygieneProductsUsed,
                [true, false],
                (val) {
                  setState(() {
                    _oralHygieneProductsUsed = val;
                    if (val == false) {
                      _oralHygieneProductTypeUsedController.clear();
                    }
                  });
                },
                required: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: TextFormField(
                controller: _oralHygieneProductTypeUsedController,
                enabled: _oralHygieneProductsUsed != false,
                decoration: InputDecoration(
                  labelText: "Type",
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _additionalCommentsController,
          "Additional Comments",
          required: false,
          multiline: true,
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return _buildSectionCard(
      title: 'Oral Cavity Images',
      icon: Icons.photo_camera_outlined,
      children: [
        FormField<List<XFile?>>(
          initialValue: _images,
          validator: (value) {
            if (value == null || value.any((img) => img == null)) {
              return "Please upload all 9 oral cavity images";
            }
            return null;
          },
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload images for each designated region of the mouth.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      crossAxisCount: isWide ? 3 : 2,
                      children: [
                        ImageCard(
                          title: 'IMG1:\nTongue',
                          imageFile: _images[0],
                          onTap: () => _showImageSourceActionSheet(0),
                        ),
                        ImageCard(
                          title: 'IMG2:\nBelow Tongue',
                          imageFile: _images[1],
                          onTap: () => _showImageSourceActionSheet(1),
                        ),
                        ImageCard(
                          title: 'IMG3:\nLeft of Tongue',
                          imageFile: _images[2],
                          onTap: () => _showImageSourceActionSheet(2),
                        ),
                        ImageCard(
                          title: 'IMG4:\nRight of Tongue',
                          imageFile: _images[3],
                          onTap: () => _showImageSourceActionSheet(3),
                        ),
                        ImageCard(
                          title: 'IMG5:\nPalate',
                          imageFile: _images[4],
                          onTap: () => _showImageSourceActionSheet(4),
                        ),
                        ImageCard(
                          title: 'IMG6:\nLeft Cheek',
                          imageFile: _images[5],
                          onTap: () => _showImageSourceActionSheet(5),
                        ),
                        ImageCard(
                          title: 'IMG7:\nRight Cheek',
                          imageFile: _images[6],
                          onTap: () => _showImageSourceActionSheet(6),
                        ),
                        ImageCard(
                          title: 'IMG8:\nUpper Lip / Gum',
                          imageFile: _images[7],
                          onTap: () => _showImageSourceActionSheet(7),
                        ),
                        ImageCard(
                          title: 'IMG9:\nLower Lip / Gum',
                          imageFile: _images[8],
                          onTap: () => _showImageSourceActionSheet(8),
                        ),
                      ],
                    );
                  },
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Case"), centerTitle: true),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          children: [
            Expanded(child: _buildResponsiveForm()),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.draftIndex != null) ...[
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
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
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                _confirmAction(
                                  title: "Submit Case",
                                  message:
                                      "Are you sure you want to submit this case?",
                                  onConfirm: _submitCase,
                                );
                              },
                              icon: const Icon(Icons.send),
                              label: const Text("Submit"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.draftIndex != null)
                          Expanded(
                            child: ElevatedButton.icon(
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
                          ),
                        if (widget.draftIndex != null) const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _confirmAction(
                                title: "Save Draft",
                                message:
                                    "Are you sure you want to save this draft? You can continue editing it later.",
                                onConfirm: _saveDraft,
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Save"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _confirmAction(
                                title: "Submit Case",
                                message:
                                    "Are you sure you want to submit this case?",
                                onConfirm: _submitCase,
                              );
                            },
                            icon: const Icon(Icons.send),
                            label: const Text("Submit"),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
