// Diagnose a case
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnoseCaseScreen extends StatefulWidget {
  final Map<String, dynamic> caseInfo;
  final int caseIndex;

  const DiagnoseCaseScreen({
    super.key,
    required this.caseInfo,
    required this.caseIndex,
  });

  @override
  State<DiagnoseCaseScreen> createState() => _DiagnoseCaseScreenState();
}

class _DiagnoseCaseScreenState extends State<DiagnoseCaseScreen> {
  late final CaseRetrieveModel _caseData;

  final TextEditingController _caseIdController = TextEditingController();
  final TextEditingController _createdAtController = TextEditingController();
  final TextEditingController _submittedAtController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ethnicityController = TextEditingController();
  final TextEditingController _smokingController = TextEditingController();
  final TextEditingController _smokingDurationController =
      TextEditingController();
  final TextEditingController _betelQuidController = TextEditingController();
  final TextEditingController _betelQuidDurationController =
      TextEditingController();
  final TextEditingController _alcoholController = TextEditingController();
  final TextEditingController _alcoholDurationController =
      TextEditingController();
  final TextEditingController _lesionClinicalPresentationController =
      TextEditingController();
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _presentingComplaintHistoryController =
      TextEditingController();
  final TextEditingController _medicationHistoryController =
      TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _slsContainingToothpasteController =
      TextEditingController();
  final TextEditingController _slsContainingToothpasteUsedController =
      TextEditingController();
  final TextEditingController _oralHygieneProductsUsedController =
      TextEditingController();
  final TextEditingController _oralHygieneProductTypeUsedController =
      TextEditingController();
  final TextEditingController _additionalCommentsController =
      TextEditingController();
  List<Uint8List> _images = [];

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final List<String> _imageNamesList = [
    "IMG1: Tongue",
    "IMG2: Below Tongue",
    "IMG3: Left of Tongue",
    "IMG4: Right of Tongue",
    "IMG5: Palate",
    "IMG6: Left Cheek",
    "IMG7: Right Cheek",
    "IMG8: Upper Lip / Gum",
    "IMG9: Lower Lip / Gum",
  ];
  int _selectedImageIndex = 0;
  final List<LesionType> _lesionTypes = List.filled(9, LesionType.NULL);
  final List<ClinicalDiagnosis> _clinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  final List<bool> _lowQualityFlags = List.filled(9, false);

  @override
  void initState() {
    super.initState();
    _populateData();
  }

  void _populateData() {
    _caseData = widget.caseInfo["case_data"];

    _caseIdController.text = widget.caseInfo["case_id"] ?? "";
    _createdAtController.text = _caseData.createdAt;
    _submittedAtController.text = _caseData.submittedAt;
    _createdByController.text = _caseData.createdBy;
    _ageController.text = _caseData.age;
    _genderController.text = _caseData.gender;
    _ethnicityController.text = _caseData.ethnicity;
    _smokingController.text = _caseData.smoking.toShortString;
    _smokingDurationController.text = _caseData.smokingDuration;
    _betelQuidController.text = _caseData.betelQuid.toShortString;
    _betelQuidDurationController.text = _caseData.betelQuidDuration;
    _alcoholController.text = _caseData.alcohol.toShortString;
    _alcoholDurationController.text = _caseData.alcoholDuration;
    _lesionClinicalPresentationController.text =
        _caseData.lesionClinicalPresentation;
    _chiefComplaintController.text = _caseData.chiefComplaint;
    _presentingComplaintHistoryController.text =
        _caseData.presentingComplaintHistory;
    _medicationHistoryController.text = _caseData.medicationHistory;
    _medicalHistoryController.text = _caseData.medicalHistory;
    _slsContainingToothpasteController.text = _caseData.slsContainingToothpaste
        ? "YES"
        : "NO";
    _slsContainingToothpasteUsedController.text =
        _caseData.slsContainingToothpasteUsed;
    _oralHygieneProductsUsedController.text = _caseData.oralHygieneProductsUsed
        ? "YES"
        : "NO";
    _oralHygieneProductTypeUsedController.text =
        _caseData.oralHygieneProductTypeUsed;
    _additionalCommentsController.text = _caseData.additionalComments;
    _images = _caseData.images;
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    _createdAtController.dispose();
    _submittedAtController.dispose();
    _createdByController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _ethnicityController.dispose();
    _smokingController.dispose();
    _smokingDurationController.dispose();
    _betelQuidController.dispose();
    _betelQuidDurationController.dispose();
    _alcoholController.dispose();
    _alcoholDurationController.dispose();
    _lesionClinicalPresentationController.dispose();
    _chiefComplaintController.dispose();
    _presentingComplaintHistoryController.dispose();
    _medicationHistoryController.dispose();
    _medicalHistoryController.dispose();
    _slsContainingToothpasteController.dispose();
    _slsContainingToothpasteUsedController.dispose();
    _oralHygieneProductsUsedController.dispose();
    _oralHygieneProductTypeUsedController.dispose();
    _additionalCommentsController.dispose();
    super.dispose();
  }

  Widget _buildDiagnosisForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                _caseIdController,
                "Case ID",
                copiable: true,
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _createdByController,
                "Created By",
                copiable: true,
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(_createdAtController, "Created At", copiable: true),
        const SizedBox(height: 8),

        _buildTextField(_submittedAtController, "Submitted At", copiable: true),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(_ageController, "Age", noExpand: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _genderController,
                "Gender",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _ethnicityController,
                "Ethnicity",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                _smokingController,
                "Smoking",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _smokingDurationController,
                "Duration",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                _betelQuidController,
                "Betel Quid",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _betelQuidDurationController,
                "Duration",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                _alcoholController,
                "Alcohol",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _alcoholDurationController,
                "Duration",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _lesionClinicalPresentationController,
          "Lesion Clinical Presentation",
          copiable: true,
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _chiefComplaintController,
          "Chief Complaint",
          copiable: true,
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _presentingComplaintHistoryController,
          "Presenting Complaint History",
          copiable: true,
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _medicationHistoryController,
          "Medication History",
          copiable: true,
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _medicalHistoryController,
          "Medical History",
          copiable: true,
        ),
        const SizedBox(height: 8),

        Text("SLS Containing Toothpaste"),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildTextField(
                _slsContainingToothpasteController,
                "Used",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                _slsContainingToothpasteUsedController,
                "Type",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Text("Oral Hygiene Products"),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildTextField(
                _oralHygieneProductsUsedController,
                "Used",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                _oralHygieneProductTypeUsedController,
                "Type",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _additionalCommentsController,
          "Additional Comments",
          copiable: true,
        ),
        const SizedBox(height: 20),

        Text(
          "Oral Cavity Images of 9 Areas",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<int>(
          value: _selectedImageIndex,
          isExpanded: true,
          items: List.generate(_imageNamesList.length, (i) {
            final incomplete =
                _lesionTypes[i] == LesionType.NULL ||
                _clinicalDiagnoses[i] == ClinicalDiagnosis.NULL;

            return DropdownMenuItem(
              value: i,
              child: Text(
                incomplete ? '${_imageNamesList[i]} *' : _imageNamesList[i],
                style: TextStyle(
                  color: incomplete ? Colors.red : null,
                  fontWeight: incomplete ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) setState(() => _selectedImageIndex = val);
          },
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () {
            if (_images.isNotEmpty) {
              _showImageZoomDialog(_selectedImageIndex);
            }
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: _images.isNotEmpty
                      ? Image.memory(
                          _images[_selectedImageIndex],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : const Text("No image available"),
                ),
                if (_images.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Tap to zoom',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildDropdown(
          "Diagnosis - Lesion Type",
          _lesionTypes[_selectedImageIndex],
          LesionType.values,
          (val) => setState(() => _lesionTypes[_selectedImageIndex] = val!),
        ),
        const SizedBox(height: 8),

        _buildDropdown(
          "Diagnosis - Clinical Diagnosis",
          _clinicalDiagnoses[_selectedImageIndex],
          ClinicalDiagnosis.values,
          (val) =>
              setState(() => _clinicalDiagnoses[_selectedImageIndex] = val!),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Low Quality Image?"),
            Switch(
              value: _lowQualityFlags[_selectedImageIndex],
              onChanged: (val) {
                setState(() => _lowQualityFlags[_selectedImageIndex] = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        FormField<void>(
          initialValue: null,
          validator: (_) {
            final missingLesion = _lesionTypes
                .asMap()
                .entries
                .where((e) => e.value == LesionType.NULL)
                .map((e) => e.key + 1)
                .toList();
            final missingDiag = _clinicalDiagnoses
                .asMap()
                .entries
                .where((e) => e.value == ClinicalDiagnosis.NULL)
                .map((e) => e.key + 1)
                .toList();

            if (missingLesion.isNotEmpty || missingDiag.isNotEmpty) {
              final parts = <String>[];
              if (missingLesion.isNotEmpty) {
                parts.add('Lesion type missing: ${missingLesion.join(', ')}');
              }
              if (missingDiag.isNotEmpty) {
                parts.add(
                  'Clinical diagnosis missing: ${missingDiag.join(', ')}',
                );
              }
              return parts.join('. ');
            }
            return null;
          },
          builder: (field) {
            return field.hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool readOnly = true,
    bool copiable = false,
    bool multiline = false,
    bool noExpand = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      minLines: noExpand ? 1 : (multiline ? 4 : 1),
      maxLines: noExpand ? 1 : 4,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: readOnly && copiable
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

  void _showImageZoomDialog(int imageIndex) {
    if (_images.isEmpty || imageIndex >= _images.length) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Zoomable image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image.memory(_images[imageIndex], fit: BoxFit.contain),
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
                    _imageNamesList[imageIndex],
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
                      'Pinch to zoom • Double-tap to zoom • Drag to pan',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _cancelDiagnosis() {
    Navigator.pop(context, {'action': 'cancel', 'index': widget.caseIndex});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Diagnosis cancelled, no changes are submitted."),
      ),
    );
  }

  Future<void> _submitDiagnosis() async {
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

      int firstMissingLesion = _lesionTypes.indexWhere(
        (t) => t == LesionType.NULL,
      );
      int firstMissingDiag = _clinicalDiagnoses.indexWhere(
        (d) => d == ClinicalDiagnosis.NULL,
      );

      int firstMissing = -1;
      if (firstMissingLesion != -1 && firstMissingDiag != -1) {
        firstMissing = (firstMissingLesion < firstMissingDiag)
            ? firstMissingLesion
            : firstMissingDiag;
      } else if (firstMissingLesion != -1) {
        firstMissing = firstMissingLesion;
      } else if (firstMissingDiag != -1) {
        firstMissing = firstMissingDiag;
      }

      if (firstMissing != -1) {
        setState(() {
          _selectedImageIndex = firstMissing;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill lesion type and clinical diagnosis for all 9 images. Jumped to first missing.',
            ),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submitting Diagnosis"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Your diagnosis is being submitted at the moment."),
            ],
          ),
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

      if (widget.caseInfo["case_id"] == null) {
        throw Exception("Case ID is missing. Please refresh and try again.");
      }
      String caseId = widget.caseInfo["case_id"];

      final List<ClinicianDiagnosis> clinicianDiagnoses = List.generate(
        9,
        (index) => ClinicianDiagnosis(
          clinicianID: userId,
          clinicalDiagnosis: _clinicalDiagnoses[index],
          lesionType: _lesionTypes[index],
          lowQuality: _lowQualityFlags[index],
        ),
      );

      final CaseDiagnosisModel diagnoseCase = CaseDiagnosisModel(
        clinicianDiagnoses: clinicianDiagnoses,
      );

      final result = await DbManagerService.diagnoseCase(
        caseId: caseId,
        diagnoses: diagnoseCase,
      );

      if (result == caseId) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context, {
          'action': 'diagnosed',
          'index': widget.caseIndex,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Diagnosis submitted successfully.")),
        );
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response from server")),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit diagnosis: $e")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diagnose Case")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: _buildDiagnosisForm(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Cancel Diagnosis",
                        message: "Are you sure you want to cancel diagnosis?",
                        onConfirm: _cancelDiagnosis,
                      );
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Diagnosis"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Submit Diagnosis",
                        message: "Are you sure you want to submit diagnosis?",
                        onConfirm: _submitDiagnosis,
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Submit Diagnosis"),
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
