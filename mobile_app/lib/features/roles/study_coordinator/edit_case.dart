// Search and edit / add ground truth for existing case in database
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EditCaseScreen extends StatefulWidget {
  const EditCaseScreen({super.key});

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  CaseRetrieveModel? _caseData;
  final _caseIdController = TextEditingController();
  final _createdAtController = TextEditingController();
  final _submittedAtController = TextEditingController();
  final _createdByController = TextEditingController();
  final _nameController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _idNumController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _ethnicityController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _attendingHospitalController = TextEditingController();
  String _consentFormType = "NULL";
  Uint8List _consentFormBytes = Uint8List(0);
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
  List<Uint8List> _images = List.generate(9, (_) => Uint8List(0));
  List<Diagnosis> _diagnoses = List.generate(9, (_) => Diagnosis.empty());

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
  List<LesionType> _biopsyLesionTypes = List.filled(9, LesionType.NULL);
  List<ClinicalDiagnosis> _biopsyClinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  List<LesionType> _coeLesionTypes = List.filled(9, LesionType.NULL);
  List<ClinicalDiagnosis> _coeClinicalDiagnoses = List.filled(
    9,
    ClinicalDiagnosis.NULL,
  );
  List<BiopsyAgreeWithCOE> _biopsyAgreeWithCOE = List.filled(
    9,
    BiopsyAgreeWithCOE.NULL,
  );
  List<TextEditingController> _biopsyAgreeWithCOEController = List.generate(
    9,
    (index) => TextEditingController(text: BiopsyAgreeWithCOE.NULL.name),
  );
  List<Map<String, dynamic>> _biopsyReports = List.generate(
    9,
    (_) => {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
  ); // report from database
  List<File?> _biopsyReportFiles = List.filled(
    9,
    null,
  ); // recently picked file pending to upload to storage upon case changes submission
  List<LesionType> _aiLesionTypes = List.filled(9, LesionType.NULL);

  void _resetState() {
    setState(() {
      _isLoading = false;
      _searchResult = null;
      _errorMessage = null;

      _searchController.clear();

      _caseData = null;
      _caseIdController.clear();
      _createdAtController.clear();
      _submittedAtController.clear();
      _createdByController.clear();
      _nameController.clear();
      _idTypeController.clear();
      _idNumController.clear();
      _dobController.clear();
      _ageController.clear();
      _genderController.clear();
      _ethnicityController.clear();
      _phoneNumberController.clear();
      _addressController.clear();
      _attendingHospitalController.clear();
      _consentFormType = "NULL";
      _consentFormBytes = Uint8List(0);
      _smoking = null;
      _smokingDurationController.clear();
      _betelQuid = null;
      _betelQuidDurationController.clear();
      _alcohol = null;
      _alcoholDurationController.clear();
      _lesionClinicalPresentationController.clear();
      _chiefComplaintController.clear();
      _presentingComplaintHistoryController.clear();
      _medicationHistoryController.clear();
      _medicalHistoryController.clear();
      _slsContainingToothpaste = null;
      _slsContainingToothpasteUsedController.clear();
      _oralHygieneProductsUsed = null;
      _oralHygieneProductTypeUsedController.clear();
      _additionalCommentsController.clear();
      _images = List.generate(9, (_) => Uint8List(0));
      _diagnoses = List.generate(9, (_) => Diagnosis.empty());

      _selectedImageIndex = 0;
      _biopsyLesionTypes = List.filled(9, LesionType.NULL);
      _biopsyClinicalDiagnoses = List.filled(9, ClinicalDiagnosis.NULL);
      _coeLesionTypes = List.filled(9, LesionType.NULL);
      _coeClinicalDiagnoses = List.filled(9, ClinicalDiagnosis.NULL);
      _biopsyAgreeWithCOE = List.filled(9, BiopsyAgreeWithCOE.NULL);
      _biopsyAgreeWithCOEController = List.generate(
        9,
        (index) => TextEditingController(text: BiopsyAgreeWithCOE.NULL.name),
      );
      _biopsyReports = List.generate(
        9,
        (_) => {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
      );
      _biopsyReportFiles = List.filled(9, null);
      _aiLesionTypes = List.filled(9, LesionType.NULL);
    });
  }

  void _populateData() {
    if (_searchResult == null) return;

    setState(() {
      final result = _searchResult!;
      _caseData = result["case_data"];
      _caseIdController.text = result["case_id"] ?? "";
      _createdAtController.text = _caseData!.createdAt;
      _submittedAtController.text = _caseData!.submittedAt;
      _createdByController.text = _caseData!.createdBy;
      _nameController.text = _caseData!.name;
      _idTypeController.text = _caseData!.idtype;
      _idNumController.text = _caseData!.idnum;
      _dobController.text = _caseData!.dob;
      _ageController.text = _caseData!.age;
      _genderController.text = _caseData!.gender;
      _ethnicityController.text = _caseData!.ethnicity;
      _phoneNumberController.text = _caseData!.phonenum;
      _addressController.text = _caseData!.address;
      _attendingHospitalController.text = _caseData!.attendingHospital;
      _consentFormType = _caseData!.consentForm["fileType"] ?? "NULL";
      _consentFormBytes = _caseData!.consentForm["fileBytes"] ?? Uint8List(0);
      _smoking = _caseData!.smoking;
      _smokingDurationController.text = _caseData!.smokingDuration;
      _betelQuid = _caseData!.betelQuid;
      _betelQuidDurationController.text = _caseData!.betelQuidDuration;
      _alcohol = _caseData!.alcohol;
      _alcoholDurationController.text = _caseData!.alcoholDuration;
      _lesionClinicalPresentationController.text =
          _caseData!.lesionClinicalPresentation;
      _chiefComplaintController.text = _caseData!.chiefComplaint;
      _presentingComplaintHistoryController.text =
          _caseData!.presentingComplaintHistory;
      _medicationHistoryController.text = _caseData!.medicationHistory;
      _medicalHistoryController.text = _caseData!.medicalHistory;
      _slsContainingToothpaste = _caseData!.slsContainingToothpaste;
      _slsContainingToothpasteUsedController.text =
          _caseData!.slsContainingToothpasteUsed;
      _oralHygieneProductsUsed = _caseData!.oralHygieneProductsUsed;
      _oralHygieneProductTypeUsedController.text =
          _caseData!.oralHygieneProductTypeUsed;
      _additionalCommentsController.text = _caseData!.additionalComments;
      _images = _caseData!.images;
      _diagnoses = _caseData!.diagnoses;
      for (int i = 0; i < _diagnoses.length && i < 9; i++) {
        _biopsyLesionTypes[i] = _diagnoses[i].biopsyLesionType;
        _biopsyClinicalDiagnoses[i] = _diagnoses[i].biopsyClinicalDiagnosis;
        _coeLesionTypes[i] = _diagnoses[i].coeLesionType;
        _coeClinicalDiagnoses[i] = _diagnoses[i].coeClinicalDiagnosis;
        _aiLesionTypes[i] = _diagnoses[i]
            .aiLesionType; // for creation of CaseEditModel, not submitted for editing to server

        final dynamic incomingReport = _diagnoses[i].biopsyReport;
        if (incomingReport != null &&
            incomingReport is Map &&
            incomingReport.containsKey("url") &&
            incomingReport.containsKey("iv") &&
            incomingReport.containsKey("fileType")) {
          _biopsyReports[i] = {
            "url": incomingReport["url"] ?? "NULL",
            "iv": incomingReport["iv"] ?? "NULL",
            "fileType": incomingReport["fileType"] ?? "NULL",
          };
        } else {
          _biopsyReports[i] = {"url": "NULL", "iv": "NULL", "fileType": "NULL"};
        }

        _updateBiopsyAgreeWithCOE(i);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _caseIdController.dispose();
    _createdAtController.dispose();
    _submittedAtController.dispose();
    _createdByController.dispose();
    _nameController.dispose();
    _idTypeController.dispose();
    _idNumController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _ethnicityController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _attendingHospitalController.dispose();
    _smokingDurationController.dispose();
    _betelQuidDurationController.dispose();
    _alcoholDurationController.dispose();
    _lesionClinicalPresentationController.dispose();
    _chiefComplaintController.dispose();
    _presentingComplaintHistoryController.dispose();
    _medicationHistoryController.dispose();
    _medicalHistoryController.dispose();
    _slsContainingToothpasteUsedController.dispose();
    _oralHygieneProductTypeUsedController.dispose();
    _additionalCommentsController.dispose();
    for (var controller in _biopsyAgreeWithCOEController) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _searchCase() async {
    final caseId = _searchController.text.trim();
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
        _populateData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _searchResult = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCaseForm(Map<String, dynamic> result) {
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
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                _createdByController,
                "Created By",
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(_createdAtController, "Created At"),
        const SizedBox(height: 8),

        _buildTextField(_submittedAtController, "Submitted At"),
        const SizedBox(height: 20),

        _buildTextField(_nameController, "Name"),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 35,
              child: _buildTextField(
                _idTypeController,
                "ID Type",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                _idNumController,
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
                _dobController,
                "Date of Birth",
                noExpand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 25,
              child: _buildTextField(_ageController, "Age", noExpand: true),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(_genderController, "Gender"),
        const SizedBox(height: 8),

        _buildTextField(_ethnicityController, "Ethnicity"),
        const SizedBox(height: 8),

        _buildTextField(_phoneNumberController, "Phone Number"),
        const SizedBox(height: 8),

        _buildTextField(_addressController, "Address"),
        const SizedBox(height: 8),

        _buildTextField(_attendingHospitalController, "Attending Hospital"),
        const SizedBox(height: 8),

        Text("Consent Form"),
        ElevatedButton.icon(
          onPressed: _consentFormBytes.isEmpty
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text("No consent form available")),
                )
              : () => _viewFile(_consentFormBytes, fileType: _consentFormType),
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
                readOnly: false,
                noExpand: true,
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

        _buildTextField(_chiefComplaintController, "Chief Complaint"),
        const SizedBox(height: 8),

        _buildTextField(
          _presentingComplaintHistoryController,
          "Presenting Complaint History",
        ),
        const SizedBox(height: 8),

        _buildTextField(_medicationHistoryController, "Medication History"),
        const SizedBox(height: 8),

        _buildTextField(_medicalHistoryController, "Medical History"),
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
                (val) => setState(() => _slsContainingToothpaste = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                _slsContainingToothpasteUsedController,
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
                _oralHygieneProductsUsed,
                [true, false],
                (val) => setState(() => _oralHygieneProductsUsed = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 65,
              child: _buildTextField(
                _oralHygieneProductTypeUsedController,
                "Type",
                readOnly: false,
                noExpand: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildTextField(
          _additionalCommentsController,
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
            child: _images.isNotEmpty
                ? Image.memory(
                    _images[_selectedImageIndex],
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
                  ? Text("Replace")
                  : (_biopsyReports[_selectedImageIndex]['url'] != 'NULL'
                        ? Text("Replace")
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
    bool required = false,
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
      validator: (val) {
        if (required && val == null) {
          return "Select $label";
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
    bool required = false,
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

  Future<void> _viewFile(
    Uint8List fileBytes, {
    String fileType = "NULL",
  }) async {
    try {
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

    setState(
      () => _biopsyAgreeWithCOEController[index].text =
          _biopsyAgreeWithCOE[index].name,
    );
  }

  Future<void> _pickBiopsyReport(int index) async {
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
        _viewFile(bytes, fileType: local.path.split('.').last.toLowerCase());
        return;
      }

      final remote = _biopsyReports[index];
      final String url = (remote["url"] ?? "NULL") as String;
      final String iv = (remote["iv"] ?? "NULL") as String;
      final String fileType = (remote["fileType"] ?? "NULL") as String;

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
      _viewFile(fileBytes, fileType: fileType);
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

  Future<void> _submitChanges() async {
    if (_searchResult == null) return;
    if (_isLoading) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submitting Case Changes"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("The case is being submitted at the moment."),
            ],
          ),
        );
      },
    );

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
            "fileType": local.path.split('.').last.toLowerCase(),
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
        alcohol: _alcohol ?? caseData.alcohol,
        alcoholDuration: _alcoholDurationController.text.isNotEmpty
            ? _alcoholDurationController.text
            : caseData.alcoholDuration,
        betelQuid: _betelQuid ?? caseData.betelQuid,
        betelQuidDuration: _betelQuidDurationController.text.isNotEmpty
            ? _betelQuidDurationController.text
            : caseData.betelQuidDuration,
        smoking: _smoking ?? caseData.smoking,
        smokingDuration: _smokingDurationController.text.isNotEmpty
            ? _smokingDurationController.text
            : caseData.smokingDuration,
        oralHygieneProductsUsed:
            _oralHygieneProductsUsed ?? caseData.oralHygieneProductsUsed,
        oralHygieneProductTypeUsed:
            _oralHygieneProductTypeUsedController.text.isNotEmpty
            ? _oralHygieneProductTypeUsedController.text
            : caseData.oralHygieneProductTypeUsed,
        slsContainingToothpaste:
            _slsContainingToothpaste ?? caseData.slsContainingToothpaste,
        slsContainingToothpasteUsed:
            _slsContainingToothpasteUsedController.text.isNotEmpty
            ? _slsContainingToothpasteUsedController.text
            : caseData.slsContainingToothpasteUsed,
        additionalComments: _additionalCommentsController.text.isNotEmpty
            ? _additionalCommentsController.text
            : caseData.additionalComments,
        diagnoses: diagnoses,
        aesKey: aesKey,
      );

      final editResult = await DbManagerService.editCase(
        caseId: caseId,
        caseData: editCase,
      );

      if (editResult == caseId) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case updated successfully")),
        );
        _resetState();
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Case submitted but server returned different Case ID: $editResult",
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting changes: $e")));
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
      appBar: AppBar(title: const Text("Edit Case")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
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
