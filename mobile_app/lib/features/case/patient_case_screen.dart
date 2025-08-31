import 'package:flutter/material.dart';
import 'package:mobile_app/features/case/oral_image_upload_page.dart';
import 'package:mobile_app/features/case/page_indicator.dart';
import 'package:mobile_app/features/case/patient_details_page.dart';

class PatientCaseScreen extends StatefulWidget {
  const PatientCaseScreen({super.key});

  @override
  State<PatientCaseScreen> createState() => _PatientCaseScreenState();
}

class _PatientCaseScreenState extends State<PatientCaseScreen>
    with AutomaticKeepAliveClientMixin<PatientCaseScreen>, TickerProviderStateMixin {
  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Case'), centerTitle: true),
      body: PageView(
        controller: _pageViewController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: <Widget>[PatientDetailsPage(), OralImageUploadPage()],
      ),
      persistentFooterButtons: [
        PageIndicator(
          tabController: _tabController,
          currentPageIndex: _currentPageIndex,
          onUpdateCurrentPageIndex: (index) {
            _tabController.index = index;
            _pageViewController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }
}
