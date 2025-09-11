// Search and edit / add ground truth for existing case in database
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EditCaseScreen extends StatefulWidget {
  const EditCaseScreen({super.key});

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  final TextEditingController caseIdController = TextEditingController();
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
  final List<LesionType> _biopsyLesionTypes = List.filled(9, LesionType.NULL);
  final List<ClinicalDiagnosis> _biopsyClinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  final List<LesionType> _coeLesionTypes = List.filled(9, LesionType.NULL);
  final List<ClinicalDiagnosis> _coeClinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  final List<BiopsyAgreeWithCOE> _biopsyAgreeWithCOE = List.filled(
    9,
    BiopsyAgreeWithCOE.NULL,
  );
  final List<TextEditingController> _biopsyAgreeWithCOEController =
      List.generate(
        9,
        (index) => TextEditingController(text: BiopsyAgreeWithCOE.NULL.name),
      );
  final List<Map<String, dynamic>> _biopsyReports = List.generate(
    9,
    (_) => {"url": "NULL", "iv": "NULL"},
  );
  final List<File?> _biopsyReportFiles = List.filled(9, null);
  final List<LesionType> _aiLesionTypes = List.filled(9, LesionType.NULL);

  bool _isLoading = false;
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;

  Future<void> _searchCase() async {
    final caseId = caseIdController.text.trim();
    if (caseId.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a case ID";
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final result = await DbManagerService.searchCase(caseId: caseId);

      if (result.containsKey("error")) {
        setState(() {
          _errorMessage = "Case not found.";
          _searchResult = null;
        });
      } else {
        setState(() {
          _searchResult = result;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error searching case: $e";
        _searchResult = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCaseForm(Map<String, dynamic> result) {
    final CaseRetrieveModel caseData = result["case_data"];
    final caseIdController = TextEditingController(
      text: result["case_id"] ?? "",
    );
    final createdAtController = TextEditingController(text: caseData.createdAt);
    final submittedAtController = TextEditingController(
      text: caseData.submittedAt,
    );
    final createdByController = TextEditingController(text: caseData.createdBy);
    final nameController = TextEditingController(text: caseData.name);
    final idTypeController = TextEditingController(text: caseData.idtype);
    final idNumController = TextEditingController(text: caseData.idnum);
    final dobController = TextEditingController(text: caseData.dob);
    final ageController = TextEditingController(text: caseData.age);
    final genderController = TextEditingController(text: caseData.gender);
    final ethnicityController = TextEditingController(text: caseData.ethnicity);
    final phoneNumberController = TextEditingController(
      text: caseData.phonenum,
    );
    final addressController = TextEditingController(text: caseData.address);
    final attendingHospitalController = TextEditingController(
      text: caseData.attendingHospital,
    );
    final Uint8List consentForm = caseData.consentForm;
    Habit? smoking = caseData.smoking;
    final smokingDurationController = TextEditingController(
      text: caseData.smokingDuration,
    );
    Habit? betelQuid = caseData.betelQuid;
    final betelQuidDurationController = TextEditingController(
      text: caseData.betelQuidDuration,
    );
    Habit? alcohol = caseData.alcohol;
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
    bool? slsContainingToothpaste = caseData.slsContainingToothpaste;
    final slsContainingToothpasteUsedController = TextEditingController(
      text: caseData.slsContainingToothpasteUsed,
    );
    bool? oralHygieneProductsUsed = caseData.oralHygieneProductsUsed;
    final oralHygieneProductTypeUsedController = TextEditingController(
      text: caseData.oralHygieneProductTypeUsed,
    );
    final additionalCommentsController = TextEditingController(
      text: caseData.additionalComments,
    );
    final List<Uint8List> images = caseData.images;
    final List<Diagnosis> diagnoses = caseData.diagnoses;
    for (int i = 0; i < diagnoses.length && i < 9; i++) {
      _biopsyLesionTypes[i] = diagnoses[i].biopsyLesionType;
      _biopsyClinicalDiagnoses[i] = diagnoses[i].biopsyClinicalDiagnosis;
      _coeLesionTypes[i] = diagnoses[i].coeLesionType;
      _coeClinicalDiagnoses[i] = diagnoses[i].coeClinicalDiagnosis;
      _aiLesionTypes[i] = diagnoses[i].aiLesionType;

      final dynamic incomingReport = diagnoses[i].biopsyReport;
      if (incomingReport != null &&
          incomingReport is Map &&
          incomingReport.containsKey("url") &&
          incomingReport.containsKey("iv")) {
        _biopsyReports[i] = {
          "url": incomingReport["url"] ?? "NULL",
          "iv": incomingReport["iv"] ?? "NULL",
        };
      } else {
        _biopsyReports[i] = {"url": "NULL", "iv": "NULL"};
      }

      _updateBiopsyAgreeWithCOE(i);
    }

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

        _buildTextField(nameController, "Name"),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildTextField(
                idTypeController,
                "ID Type",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                idNumController,
                "ID Number",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 75,
              child: _buildTextField(
                dobController,
                "Date of Birth",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 25,
              child: _buildTextField(ageController, "Age", noExpand: true),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(genderController, "Gender"),
        const SizedBox(height: 8),

        _buildTextField(ethnicityController, "Ethnicity"),
        const SizedBox(height: 8),

        _buildTextField(phoneNumberController, "Phone Number"),
        const SizedBox(height: 8),

        _buildTextField(addressController, "Address"),
        const SizedBox(height: 8),

        _buildTextField(attendingHospitalController, "Attending Hospital"),
        const SizedBox(height: 8),

        Text("Consent Form"),
        ElevatedButton.icon(
          onPressed: consentForm.isEmpty
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text("No consent form available")),
                )
              : () => _viewFile(consentForm),
          icon: const Icon(Icons.remove_red_eye),
          label: const Text("View"),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildDropdown<Habit>(
                "Smoking",
                smoking,
                Habit.values,
                (val) => setState(() => smoking = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                smokingDurationController,
                "Duration",
                readOnly: false,
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
              child: _buildDropdown<Habit>(
                "Betel Quid",
                betelQuid,
                Habit.values,
                (val) => setState(() => betelQuid = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                betelQuidDurationController,
                "Duration",
                readOnly: false,
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
              child: _buildDropdown<Habit>(
                "Alcohol",
                alcohol,
                Habit.values,
                (val) => setState(() => alcohol = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                alcoholDurationController,
                "Duration",
                readOnly: false,
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
              child: _buildDropdown<bool>(
                "Used",
                slsContainingToothpaste,
                [true, false],
                (val) => setState(() => slsContainingToothpaste = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                slsContainingToothpasteUsedController,
                "Type",
                readOnly: false,
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
              child: _buildDropdown<bool>(
                "Used",
                oralHygieneProductsUsed,
                [true, false],
                (val) => setState(() => oralHygieneProductsUsed = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                oralHygieneProductTypeUsedController,
                "Type",
                readOnly: false,
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          additionalCommentsController,
          "Additional Comments",
          readOnly: false,
          multiline: true,
        ),
        const SizedBox(height: 8),

        Text("Oral Cavity Image"),
        DropdownButton<int>(
          value: _selectedImageIndex,
          isExpanded: true,
          items: List.generate(
            _imageNamesList.length,
            (i) => DropdownMenuItem(value: i, child: Text(_imageNamesList[i])),
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

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildDropdown(
                "COE - Lesion Type",
                _coeLesionTypes[_selectedImageIndex],
                LesionType.values,
                (val) => setState(() {
                  _coeLesionTypes[_selectedImageIndex] = val!;
                  _updateBiopsyAgreeWithCOE(_selectedImageIndex);
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildDropdown(
                "COE - Clinical Diagnosis",
                _coeClinicalDiagnoses[_selectedImageIndex],
                ClinicalDiagnosis.values,
                (val) => setState(() {
                  _coeClinicalDiagnoses[_selectedImageIndex] = val!;
                  _updateBiopsyAgreeWithCOE(_selectedImageIndex);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildDropdown(
                "Biopsy - Lesion Type",
                _biopsyLesionTypes[_selectedImageIndex],
                LesionType.values,
                (val) => setState(() {
                  _biopsyLesionTypes[_selectedImageIndex] = val!;
                  _updateBiopsyAgreeWithCOE(_selectedImageIndex);
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildDropdown(
                "Biopsy - Clinical Diagnosis",
                _biopsyClinicalDiagnoses[_selectedImageIndex],
                ClinicalDiagnosis.values,
                (val) => setState(() {
                  _biopsyClinicalDiagnoses[_selectedImageIndex] = val!;
                  _updateBiopsyAgreeWithCOE(_selectedImageIndex);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _biopsyAgreeWithCOEController[_selectedImageIndex],
          "Biopsy agree with COE diagnosis?",
        ),
        const SizedBox(height: 8),

        Text("Biopsy Report"),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickBiopsyReport(_selectedImageIndex),
              icon: _biopsyReportFiles[_selectedImageIndex] != null
                  ? const Icon(Icons.edit)
                  : (_biopsyReports[_selectedImageIndex]['url'] != 'NULL'
                        ? const Icon(Icons.edit)
                        : const Icon(Icons.upload_file)),
              label: _biopsyReportFiles[_selectedImageIndex] != null
                  ? Text(
                      "Replace: ${_biopsyReportFiles[_selectedImageIndex]!.path.split(Platform.pathSeparator).last}",
                    )
                  : (_biopsyReports[_selectedImageIndex]['url'] != 'NULL'
                        ? Text("Replace existing")
                        : const Text("Upload")),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await _viewBiopsyReport(_selectedImageIndex);
              },
              icon: const Icon(Icons.remove_red_eye),
              label: const Text("View"),
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

  void _viewFile(Uint8List fileBytes) {
    bool isImage = false;
    try {
      // Try decoding the bytes as an image
      final decoded = img.decodeImage(fileBytes);
      if (decoded != null) isImage = true;
    } catch (_) {
      isImage = false;
    }

    if (isImage) {
      // Show image in a dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("File"),
          content: SingleChildScrollView(child: Image.memory(fileBytes)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } else {
      // Attempt to render as PDF
      try {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SfPdfViewer.memory(fileBytes),
            ),
          ),
        );
      } catch (_) {
        // Cannot preview
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot preview file")));
      }
    }
  }

  void _updateBiopsyAgreeWithCOE(int index) {
    final coeLesion = _coeLesionTypes[index];
    final biopsyLesion = _biopsyLesionTypes[index];
    final coeDiagnosis = _coeClinicalDiagnoses[index];
    final biopsyDiagnosis = _biopsyClinicalDiagnoses[index];

    _biopsyAgreeWithCOE[index] = BiopsyAgreeWithCOE.NULL;

    if (biopsyLesion != LesionType.NULL && coeLesion != LesionType.NULL) {
      _biopsyAgreeWithCOE[index] = (biopsyLesion == coeLesion)
          ? BiopsyAgreeWithCOE.YES
          : BiopsyAgreeWithCOE.NO;
      if (biopsyDiagnosis != ClinicalDiagnosis.NULL &&
          coeDiagnosis != ClinicalDiagnosis.NULL) {
        _biopsyAgreeWithCOE[index] =
            (biopsyLesion == coeLesion && biopsyDiagnosis == coeDiagnosis)
            ? BiopsyAgreeWithCOE.YES
            : BiopsyAgreeWithCOE.NO;
      }
    }

    _biopsyAgreeWithCOEController[index].text = _biopsyAgreeWithCOE[index].name;
  }

  Future<void> _pickBiopsyReport(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _biopsyReportFiles[index] = File(result.files.single.path!);
      });
    }
  }

  Future<void> _viewBiopsyReport(int index) async {
    try {
      final local = _biopsyReportFiles[index];
      if (local != null) {
        final bytes = await local.readAsBytes();
        _viewFile(bytes);
        return;
      }

      final remote = _biopsyReports[index];
      final String url = (remote["url"] ?? "NULL") as String;
      final String iv = (remote["iv"] ?? "NULL") as String;

      if (url == 'NULL' || url.isEmpty || iv == 'NULL' || iv.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No biopsy report available")),
        );
        return;
      }

      final String encryptedB64 = await StorageService.download(url);

      final Uint8List aesKey = _searchResult!['aes'];
      final String decryptedB64 = CryptoUtils.decryptString(
        encryptedB64,
        iv,
        aesKey,
      );

      final Uint8List fileBytes = base64Decode(decryptedB64);
      _viewFile(fileBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open biopsy report: $e")),
      );
    }
  }

  void _cancelEditing() {
    _resetState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Editing cancelled, no changes are submitted."),
      ),
    );
  }

  void _resetState() {
    setState(() {
      caseIdController.clear();
      _searchResult = null;
      _errorMessage = null;
      _isLoading = false;

      // Reset form state
      _selectedImageIndex = 0;
      for (int i = 0; i < 9; i++) {
        _coeLesionTypes[i] = LesionType.NULL;
        _coeClinicalDiagnoses[i] = ClinicalDiagnosis.NULL;
        _biopsyLesionTypes[i] = LesionType.NULL;
        _biopsyClinicalDiagnoses[i] = ClinicalDiagnosis.NULL;
        _biopsyAgreeWithCOE[i] = BiopsyAgreeWithCOE.NULL;
        _biopsyAgreeWithCOEController[i].text = BiopsyAgreeWithCOE.NULL.name;
        _biopsyReports[i] = {"url": "NULL", "iv": "NULL"};
      }
    });
  }

  Future<void> _submitChanges() async {
    if (_searchResult == null) return;

    setState(() => _isLoading = true);

    try {
      final aesKey = _searchResult!['aes'] as Uint8List;
      final caseId = _searchResult!['case_id'] as String;
      final caseData = _searchResult!['case_data'] as CaseRetrieveModel;

      final List<Map<String, dynamic>> finalBiopsyReports = List.generate(
        9,
        (i) => Map<String, dynamic>.from(_biopsyReports[i]),
      );

      for (int i = 0; i < 9; i++) {
        final local = _biopsyReportFiles[i];
        if (local != null) {
          final bytes = await local.readAsBytes();
          final encrypted = CryptoUtils.encryptString(
            base64Encode(bytes),
            aesKey,
          );
          final uploadUrl = await StorageService.upload(
            encrypted: encrypted["ciphertext"],
            fileName: "${caseId}_$i.enc",
            path: "biopsy_reports",
          );
          finalBiopsyReports[i] = {
            "url": uploadUrl,
            "iv": encrypted["iv"] ?? "NULL",
          };
        }
      }

      final List<Diagnosis> diagnoses = List.generate(
        9,
        (index) => Diagnosis(
          aiLesionType: _aiLesionTypes[index],
          biopsyClinicalDiagnosis: _biopsyClinicalDiagnoses[index],
          biopsyLesionType: _biopsyLesionTypes[index],
          biopsyReport: finalBiopsyReports[index],
          coeClinicalDiagnosis: _coeClinicalDiagnoses[index],
          coeLesionType: _coeLesionTypes[index],
        ),
      );

      final CaseEditModel editCase = CaseEditModel(
        alcohol: caseData.alcohol,
        alcoholDuration: caseData.alcoholDuration,
        betelQuid: caseData.betelQuid,
        betelQuidDuration: caseData.betelQuidDuration,
        smoking: caseData.smoking,
        smokingDuration: caseData.smokingDuration,
        oralHygieneProductsUsed: caseData.oralHygieneProductsUsed,
        oralHygieneProductTypeUsed: caseData.oralHygieneProductTypeUsed,
        slsContainingToothpaste: caseData.slsContainingToothpaste,
        slsContainingToothpasteUsed: caseData.slsContainingToothpasteUsed,
        additionalComments: caseData.additionalComments,
        diagnoses: diagnoses,
        aesKey: aesKey,
      );

      final editResult = await DbManagerService.editCase(
        caseId: caseId,
        caseData: editCase,
      );

      if (editResult == caseId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case updated successfully")),
        );
        _resetState();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response from server")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting changes: $e")));
    } finally {
      setState(() => _isLoading = false);
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
  void dispose() {
    caseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Case")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: caseIdController,
                    decoration: const InputDecoration(
                      labelText: "Case ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchCase,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Align(
                alignment: Alignment.center,
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            if (_searchResult != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildCaseForm(_searchResult!),
                ),
              ),
            if (_searchResult != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Cancel Editing",
                        message: "Are you sure you want to cancel editing?",
                        onConfirm: _cancelEditing,
                      );
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Editing"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        title: "Submit Changes",
                        message: "Are you sure you want to submit the changes?",
                        onConfirm: _submitChanges,
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Submit Changes"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
