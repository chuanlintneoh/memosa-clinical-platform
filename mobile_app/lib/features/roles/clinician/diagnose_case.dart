// Diagnose a case
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/dbmanager.dart';

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
  int _selectedImageIndex = 0;
  final List<LesionType> lesionTypes = List.filled(9, LesionType.NULL);
  final List<ClinicalDiagnosis> clinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  final List<bool> lowQualityFlags = List.filled(9, false);

  Widget _buildDiagnosisForm(Map<String, dynamic> caseInfo) {
    final CaseRetrieveModel caseData = caseInfo["case_data"];
    final caseIdController = TextEditingController(
      text: caseInfo["case_id"] ?? "",
    );
    final createdAtController = TextEditingController(text: caseData.createdAt);
    final submittedAtController = TextEditingController(
      text: caseData.submittedAt,
    );
    final createdByController = TextEditingController(text: caseData.createdBy);
    final ageController = TextEditingController(text: caseData.age);
    final genderController = TextEditingController(text: caseData.gender);
    final ethnicityController = TextEditingController(text: caseData.ethnicity);
    final smokingController = TextEditingController(
      text: caseData.smoking.toShortString,
    );
    final smokingDurationController = TextEditingController(
      text: caseData.smokingDuration,
    );
    final betelQuidController = TextEditingController(
      text: caseData.betelQuid.toShortString,
    );
    final betelQuidDurationController = TextEditingController(
      text: caseData.betelQuidDuration,
    );
    final alcoholController = TextEditingController(
      text: caseData.alcohol.toShortString,
    );
    final alcoholDurationController = TextEditingController(
      text: caseData.alcoholDuration,
    );
    final lesionClinicialPresentationController = TextEditingController(
      text: caseData.lesionClinicalPresentation,
    );
    final chiefComplaintController = TextEditingController(
      text: caseData.chiefComplaint,
    );
    final presentingComplaintHistoryController = TextEditingController(
      text: caseData.presentingComplaintHistory,
    );
    final medicationHistoryController = TextEditingController(
      text: caseData.medicationHistory,
    );
    final medicalHistoryController = TextEditingController(
      text: caseData.medicalHistory,
    );
    final slsContainingToothpasteController = TextEditingController(
      text: caseData.slsContainingToothpaste ? "YES" : "NO",
    );
    final slsContainingToothpasteUsedController = TextEditingController(
      text: caseData.slsContainingToothpasteUsed,
    );
    final oralHygieneProductsUsedController = TextEditingController(
      text: caseData.oralHygieneProductsUsed ? "YES" : "NO",
    );
    final oralHygieneProductTypeUsedController = TextEditingController(
      text: caseData.oralHygieneProductTypeUsed,
    );
    final additionalCommentsController = TextEditingController(
      text: caseData.additionalComments,
    );
    final List<Uint8List> images = caseData.images;

    final List<String> imageNamesList = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                caseIdController,
                "Case ID",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                createdByController,
                "Created By",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(createdAtController, "Created At"),
        const SizedBox(height: 8),

        _buildTextField(submittedAtController, "Submitted At"),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(ageController, "Age", noExpand: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                genderController,
                "Gender",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                ethnicityController,
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
                smokingController,
                "Smoking",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                smokingDurationController,
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
                betelQuidController,
                "Betel Quid",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                betelQuidDurationController,
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
                alcoholController,
                "Alcohol",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                alcoholDurationController,
                "Duration",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          lesionClinicialPresentationController,
          "Lesion Clinical Presentation",
        ),
        const SizedBox(height: 8),

        _buildTextField(chiefComplaintController, "Chief Complaint"),
        const SizedBox(height: 8),

        _buildTextField(
          presentingComplaintHistoryController,
          "Presenting Complaint History",
        ),
        const SizedBox(height: 8),

        _buildTextField(medicationHistoryController, "Medication History"),
        const SizedBox(height: 8),

        _buildTextField(medicalHistoryController, "Medical History"),
        const SizedBox(height: 8),

        Text("SLS Containing Toothpaste"),
        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildTextField(
                slsContainingToothpasteController,
                "Used",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                slsContainingToothpasteUsedController,
                "Type",
                noExpand: true,
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
              child: _buildTextField(
                oralHygieneProductsUsedController,
                "Used",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                oralHygieneProductTypeUsedController,
                "Type",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(additionalCommentsController, "Additional Comments"),
        const SizedBox(height: 8),

        Text("Oral Cavity Image"),
        DropdownButton<int>(
          value: _selectedImageIndex,
          isExpanded: true,
          items: List.generate(
            imageNamesList.length,
            (i) => DropdownMenuItem(value: i, child: Text(imageNamesList[i])),
          ),
          onChanged: (val) {
            if (val != null) setState(() => _selectedImageIndex = val);
          },
        ),
        const SizedBox(height: 8),

        Container(
          height: 200,
          color: Colors.grey[300],
          child: Center(
            child: images.isNotEmpty
                ? Image.memory(
                    images[_selectedImageIndex],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : const Text("No image available"),
          ),
        ),
        const SizedBox(height: 20),

        _buildDropdown(
          "Diagnosis - Lesion Type",
          lesionTypes[_selectedImageIndex],
          LesionType.values,
          (val) => setState(() => lesionTypes[_selectedImageIndex] = val!),
        ),
        const SizedBox(height: 8),

        _buildDropdown(
          "Diagnosis - Clinical Diagnosis",
          clinicalDiagnoses[_selectedImageIndex],
          ClinicalDiagnosis.values,
          (val) =>
              setState(() => clinicalDiagnoses[_selectedImageIndex] = val!),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Low Quality Image?"),
            Switch(
              value: lowQualityFlags[_selectedImageIndex],
              onChanged: (val) {
                setState(() => lowQualityFlags[_selectedImageIndex] = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = true,
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

  void _cancelDiagnosis() {
    Navigator.pop(context, {'action': 'cancel', 'index': widget.caseIndex});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Diagnosis cancelled, no changes are submitted."),
      ),
    );
  }

  Future<void> _submitDiagnosis() async {
    try {
      final List<ClinicianDiagnosis> clinicianDiagnoses = List.generate(
        9,
        (index) => ClinicianDiagnosis(
          clinicianID: FirebaseAuth.instance.currentUser?.uid ?? "unknown",
          clinicalDiagnosis: clinicalDiagnoses[index],
          lesionType: lesionTypes[index],
          lowQuality: lowQualityFlags[index],
        ),
      );

      final CaseDiagnosisModel diagnoseCase = CaseDiagnosisModel(
        clinicianDiagnoses: clinicianDiagnoses,
      );

      final result = await DbManagerService.diagnoseCase(
        caseId: widget.caseInfo["case_id"],
        diagnoses: diagnoseCase,
      );

      if (result == widget.caseInfo["case_id"]) {
        Navigator.pop(context, {
          'action': 'diagnosed',
          'index': widget.caseIndex,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Diagnosis submitted successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response from server")),
        );
      }
    } catch (e) {
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildDiagnosisForm(widget.caseInfo),
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
                      onConfirm: _cancelDiagnosis, // TODO: Cancel diagnosis
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
                      onConfirm: _submitDiagnosis, // TODO: Submit diagnosis
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
    );
  }
}
