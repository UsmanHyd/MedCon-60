import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'result.dart';

class HeartDiseaseDetectionScreen extends StatelessWidget {
  const HeartDiseaseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F8FF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFBDBDBD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Heart Disease Detection',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload your medical reports or ECG and get AI-powered analysis of your heart health.',
                style: TextStyle(fontSize: 15, color: subTextColor),
              ),
              const SizedBox(height: 18),
              _mainCard(
                icon: Icons.file_upload_outlined,
                iconColor: const Color(0xFF7B61FF),
                title: 'Upload Report/ECG',
                description:
                    'Upload your medical reports or ECG recordings for AI analysis.',
                buttonText: 'Start',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UploadMedicalReportScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 18),
              _mainCard(
                icon: Icons.favorite_border,
                iconColor: const Color(0xFF0288D1),
                title: 'View Results',
                description:
                    'Check your heart health analysis and recommendations.',
                buttonText: 'Start',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HeartAnalysisResultScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isDarkMode,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(fontSize: 13, color: subTextColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadMedicalReportScreen extends StatefulWidget {
  const UploadMedicalReportScreen({super.key});

  @override
  State<UploadMedicalReportScreen> createState() =>
      _UploadMedicalReportScreenState();
}

class _UploadMedicalReportScreenState extends State<UploadMedicalReportScreen> {
  String? _fileName;
  PlatformFile? _pickedFile;
  final TextEditingController _notesController = TextEditingController();

  Future<void> _pickFile() async {
    print('Browse Files button pressed');

    try {
      print('Attempting to open basic file picker');
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      print('File picker result: $result');
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _fileName = _pickedFile!.name;
        });
        print('Picked file: ${_pickedFile!.name}');
      } else {
        print('No file selected or picker was canceled');
      }
    } catch (e) {
      print('Error picking file: $e');
      try {
        print('Trying alternative approach');
        await FilePicker.platform.clearTemporaryFiles();
        FilePickerResult? result = await FilePicker.platform.pickFiles();

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _pickedFile = result.files.first;
            _fileName = _pickedFile!.name;
          });
          print('Picked file with alternative approach: ${_pickedFile!.name}');
        }
      } catch (e2) {
        print('Alternative approach also failed: $e2');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Unable to open file picker. Please try restarting the app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F8FF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFBDBDBD);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            Text('Upload Medical Report', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE3E8F0),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.cloud_upload_outlined,
                        size: 40, color: Color(0xFF7B61FF)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fileName == null
                        ? 'Drag & drop or browse files'
                        : _fileName!,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supported formats: PDF, JPG, PNG (max 10MB)',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _pickFile,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    child: Text('Browse Files',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Additional Notes (Optional)',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Add any relevant information about your report...',
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalysisCompleteScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Upload & Analyze',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisCompleteScreen extends StatefulWidget {
  const AnalysisCompleteScreen({super.key});

  @override
  State<AnalysisCompleteScreen> createState() => _AnalysisCompleteScreenState();
}

class _AnalysisCompleteScreenState extends State<AnalysisCompleteScreen>
    with SingleTickerProviderStateMixin {
  bool _showSuccess = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSuccess = true;
      });
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F8FF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            Text('Upload Medical Report', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            if (!_showSuccess)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              )
            else
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A3D2E)
                              : const Color(0xFFD1FADF),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: const Icon(Icons.check,
                            color: Color(0xFF12B76A), size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Analysis Complete!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your report has been successfully analyzed',
                        style: TextStyle(fontSize: 14, color: subTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HeartAnalysisResultScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View Results',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
