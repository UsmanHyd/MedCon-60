import 'package:flutter/material.dart';
import '/doctor/modules/doctor_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';

class PrescriptionAssistantScreen extends StatefulWidget {
  const PrescriptionAssistantScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionAssistantScreen> createState() =>
      _PrescriptionAssistantScreenState();
}

class _PrescriptionAssistantScreenState
    extends State<PrescriptionAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final recommendedMeds = [
      {
        'name': 'Sumatriptan',
        'dose': '100mg tablet',
        'desc':
            'For acute migraine attacks. Take at onset of symptoms. Max 200mg per day.'
      },
      {
        'name': 'Rizatriptan',
        'dose': '10mg tablet',
        'desc':
            'For acute migraine attacks. Take at onset of symptoms. Max 30mg per day.'
      },
      {
        'name': 'Topiramate',
        'dose': '25mg tablet',
        'desc':
            'For migraine prevention. Start with 25mg daily, increase gradually. Max 100mg per day.'
      },
    ];
    final recentlyPrescribed = [
      {
        'name': 'Propranolol',
        'dose': '40mg tablet',
        'desc': 'For migraine prevention and hypertension. Take once daily.'
      },
      {
        'name': 'Metoclopramide',
        'dose': '10mg tablet',
        'desc': 'For nausea associated with migraine. Take as needed.'
      },
      {
        'name': 'Amitriptyline',
        'dose': '25mg tablet',
        'desc': 'For migraine prevention. Take at bedtime.'
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Assistant'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        elevation: 0.5,
        centerTitle: true,
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0288D1)),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: Column(
        children: [
          // Patient header
          Container(
            width: double.infinity,
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  child: const Text('HR',
                      style: TextStyle(
                          color: Color(0xFF0288D1),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harper Reynolds',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('42 years • Female • Migraine',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrescriptionDraftScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('View Draft'),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0288D1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0288D1),
              tabs: const [
                Tab(text: 'Medicines'),
                Tab(text: 'Lab Tests'),
                Tab(text: 'Guidelines'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Medicines Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.12)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search medications...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Recommended for Migraine',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...recommendedMeds.map((med) => _MedCard(
                          name: med['name']!,
                          dose: med['dose']!,
                          desc: med['desc']!,
                        )),
                    const SizedBox(height: 18),
                    const Text('Recently Prescribed',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...recentlyPrescribed.map((med) => _MedCard(
                          name: med['name']!,
                          dose: med['dose']!,
                          desc: med['desc']!,
                        )),
                  ],
                ),
                // Lab Tests Tab
                const Center(child: Text('Lab Tests (UI to be implemented)')),
                // Guidelines Tab
                const Center(child: Text('Guidelines (UI to be implemented)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final String name;
  final String dose;
  final String desc;
  const _MedCard({required this.name, required this.dose, required this.desc});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dose,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0288D1)),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

class PrescriptionDraftScreen extends StatelessWidget {
  const PrescriptionDraftScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final medicines = [
      {
        'name': 'Sumatriptan',
        'dose': '100mg tablet',
        'desc':
            'Take 1 tablet at onset of migraine. May repeat after 2 hours if needed. Maximum 2 tablets per 24 hours.',
        'qty': '6 tablets',
        'refills': '1',
      },
      {
        'name': 'Metoclopramide',
        'dose': '10mg tablet',
        'desc':
            'Take 1 tablet as needed for nausea, up to 3 times per day. Take 30 minutes before meals.',
        'qty': '30 tablets',
        'refills': '2',
      },
      {
        'name': 'Propranolol',
        'dose': '40mg tablet',
        'desc':
            'Take 1 tablet twice daily. Continue current regimen for hypertension and migraine prevention.',
        'qty': '60 tablets',
        'refills': '3',
      },
    ];
    final labTests = [
      {
        'name': 'Complete Blood Count (CBC)',
        'desc': 'Routine monitoring for medication effects',
      },
      {
        'name': 'Basic Metabolic Panel',
        'desc': 'To monitor kidney function and electrolytes',
      },
    ];
    const notes =
        "Patient should avoid triggers such as bright lights, loud noises, and alcohol during migraine episodes. Stay hydrated and maintain regular sleep.";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Draft'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient header
          Container(
            width: double.infinity,
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  child: const Text('HR',
                      style: TextStyle(
                          color: Color(0xFF0288D1),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harper Reynolds',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('42 years • Female • Migraine',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Medications
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medications',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...medicines.map((med) => _DraftMedItem(
                      name: med['name']!,
                      dose: med['dose']!,
                      desc: med['desc']!,
                      qty: med['qty']!,
                      refills: med['refills']!,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lab Tests
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lab Tests',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...labTests.map((test) => _DraftLabItem(
                      name: test['name']!,
                      desc: test['desc']!,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Notes & Instructions
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes & Instructions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Text(notes, style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrescriptionSummaryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Finalize Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFF0288D1)),
                  ),
                  child: const Text('+ Add More'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftMedItem extends StatelessWidget {
  final String name;
  final String dose;
  final String desc;
  final String qty;
  final String refills;
  const _DraftMedItem(
      {required this.name,
      required this.dose,
      required this.desc,
      required this.qty,
      required this.refills});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(dose,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text('Quantity: $qty   Refills: $refills',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF757575)),
                onPressed: () {},
              ),
              IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFF757575)),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftLabItem extends StatelessWidget {
  final String name;
  final String desc;
  const _DraftLabItem({required this.name, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF757575)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class PrescriptionSummaryScreen extends StatelessWidget {
  const PrescriptionSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final medicines = [
      {
        'name': 'Sumatriptan',
        'dose': '100mg tablet',
        'desc':
            'Take 1 tablet at onset of migraine. May repeat after 2 hours if needed. Maximum 2 tablets per 24 hours.',
        'qty': '6 tablets',
        'refills': '1',
      },
      {
        'name': 'Metoclopramide',
        'dose': '10mg tablet',
        'desc':
            'Take 1 tablet as needed for nausea, up to 3 times per day. Take 30 minutes before meals.',
        'qty': '30 tablets',
        'refills': '2',
      },
      {
        'name': 'Propranolol',
        'dose': '40mg tablet',
        'desc':
            'Take 1 tablet twice daily. Continue current regimen for hypertension and migraine prevention.',
        'qty': '60 tablets',
        'refills': '3',
      },
    ];
    final labTests = [
      'Complete Blood Count (CBC)',
      'Basic Metabolic Panel',
    ];
    const instructions =
        "Patient should avoid triggers such as bright lights, loud noises, and alcohol during migraine episodes. Stay hydrated and maintain regular sleep schedule. Schedule follow-up appointment in 2 weeks to assess medication efficacy.";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Summary'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: const Color(0xFF0288D1),
        surfaceTintColor: isDarkMode ? Colors.grey[850] : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFE6F3FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('MedCon',
                          style: TextStyle(
                              fontFamily: 'Pacifico',
                              color: Color(0xFF0288D1),
                              fontSize: 26)),
                      Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Dr. Sarah Chen',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Neurologist', style: TextStyle(fontSize: 13)),
                          Text('License #: NY12345678',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFE6F3FF)),
                  const Row(
                    children: [
                      Expanded(
                          child: Text('Patient:\nHarper Reynolds',
                              style: TextStyle(fontSize: 14))),
                      Expanded(
                          child: Text('Date:\nMay 21, 2025',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Expanded(
                          child: Text('DOB:\nMarch 15, 1983',
                              style: TextStyle(fontSize: 14))),
                      Expanded(
                          child: Text('Diagnosis:\nChronic Migraine',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 14))),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFE6F3FF)),
                  const Text('Rx',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...List.generate(medicines.length, (i) {
                    final med = medicines[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${med['name']} ${med['dose']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Sig: ${med['desc']}',
                              style: const TextStyle(fontSize: 13)),
                          Text('Disp: ${med['qty']}',
                              style: const TextStyle(fontSize: 13)),
                          Text('Refills: ${med['refills']}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text('Laboratory Tests',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ...labTests.map((test) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Text(test, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  const Text('Special Instructions',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, left: 2, right: 2),
                    child: Text(instructions, style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 18),
                  const Text('Electronically signed by',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      const Text('Dr. Sarah Chen, MD',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Image.asset('assets/signature.png',
                          height: 32,
                          width: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xFF0288D1), size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Prescription sent successfully!',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        backgroundColor: Colors.white,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Color(0xFFE6F3FF), width: 1),
                        ),
                        elevation: 8,
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const DoctorDashboard()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send to Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFF0288D1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
