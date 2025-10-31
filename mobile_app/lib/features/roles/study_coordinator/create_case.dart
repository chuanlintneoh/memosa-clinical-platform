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
        alcoholDuration: _alcoholDurationController.text,
        betelQuid: _betelQuid!,
        betelQuidDuration: _betelQuidDurationController.text,
        smoking: _smoking!,
        smokingDuration: _smokingDurationController.text,
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
        ethnicity: _ethnicityController.text,
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
            builder: (_) => AlertDialog(
              title: Text("File as ${fileType.toLowerCase()}"),
              content: SingleChildScrollView(child: Image.memory(fileBytes)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Case")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 5.0),
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

                    _buildTextField(
                      _nameController,
                      "Full Name",
                      allowedChars: RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ'\- ]"),
                    ),
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
                          child: _buildTextField(
                            _idNumController,
                            "Number",
                            allowedChars: RegExp(r"[A-Za-z0-9]"),
                          ),
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

                    _buildTextField(
                      _phoneNumberController,
                      "Phone Number",
                      allowedChars: RegExp(r"[0-9]"),
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(_addressController, "Address"),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _attendingHospitalController,
                      "Attending Hospital",
                    ),
                    const SizedBox(height: 8),

                    Text("Consent Form"),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showConsentFormSourceActionSheet(
                                        fieldState,
                                      ),
                                  icon: _consentForm != null
                                      ? const Icon(Icons.edit)
                                      : const Icon(Icons.upload_file),
                                  label: _consentForm != null
                                      ? const Text("Replace")
                                      : const Text("Upload"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _consentForm == null
                                      ? () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "No consent form available",
                                                ),
                                              ),
                                            )
                                      : _viewConsentForm,
                                  icon: const Icon(Icons.remove_red_eye),
                                  label: const Text("View"),
                                ),
                              ],
                            ),

                            if (fieldState.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  left: 4.0,
                                ),
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
                      _lesionClinicalPresentationController,
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
                            required: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 65,
                          child: _buildTextField(
                            _slsContainingToothpasteUsedController,
                            "Type",
                            required: false,
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
                            required: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 65,
                          child: _buildTextField(
                            _oralHygieneProductTypeUsedController,
                            "Type",
                            required: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      _additionalCommentsController,
                      "Additional Comments",
                      required: false,
                      multiline: true,
                    ),
                    const SizedBox(height: 8),

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
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                margin: const EdgeInsets.all(8.0),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Oral Cavity Images of 9 Areas',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16.0),
                                    Text(
                                      'Upload images for each designated region of the mouth.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16.0),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 16.0,
                                      crossAxisSpacing: 16.0,
                                      crossAxisCount: 2,
                                      children: [
                                        ImageCard(
                                          title: 'IMG1:\nTongue',
                                          imageFile: _images[0],
                                          onTap: () =>
                                              _showImageSourceActionSheet(0),
                                        ),
                                        ImageCard(
                                          title: 'IMG2:\nBelow Tongue',
                                          imageFile: _images[1],
                                          onTap: () =>
                                              _showImageSourceActionSheet(1),
                                        ),
                                        ImageCard(
                                          title: 'IMG3:\nLeft of Tongue',
                                          imageFile: _images[2],
                                          onTap: () =>
                                              _showImageSourceActionSheet(2),
                                        ),
                                        ImageCard(
                                          title: 'IMG4:\nRight of Tongue',
                                          imageFile: _images[3],
                                          onTap: () =>
                                              _showImageSourceActionSheet(3),
                                        ),
                                        ImageCard(
                                          title: 'IMG5:\nPalate',
                                          imageFile: _images[4],
                                          onTap: () =>
                                              _showImageSourceActionSheet(4),
                                        ),
                                        ImageCard(
                                          title: 'IMG6:\nLeft Cheek',
                                          imageFile: _images[5],
                                          onTap: () =>
                                              _showImageSourceActionSheet(5),
                                        ),
                                        ImageCard(
                                          title: 'IMG7:\nRight Cheek',
                                          imageFile: _images[6],
                                          onTap: () =>
                                              _showImageSourceActionSheet(6),
                                        ),
                                        ImageCard(
                                          title: 'IMG8:\nUpper Lip / Gum',
                                          imageFile: _images[7],
                                          onTap: () =>
                                              _showImageSourceActionSheet(7),
                                        ),
                                        ImageCard(
                                          title: 'IMG9:\nLower Lip / Gum',
                                          imageFile: _images[8],
                                          onTap: () =>
                                              _showImageSourceActionSheet(8),
                                        ),
                                      ],
                                    ),
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          field.errorText!,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
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
