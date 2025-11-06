import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';

class DoctorRequestDetailScreen extends StatelessWidget {
  final String requestId;
  final String doctorName;

  const DoctorRequestDetailScreen(
      {super.key, required this.requestId, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDarkMode ? const Color(0xFF181A20) : const Color(0xFFF5F6FA);
    final cardColor = isDarkMode ? const Color(0xFF23272F) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0288D1),
        title: Text('Request Details'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('consultation_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('Request not found',
                  style: TextStyle(color: subTextColor)),
            );
          }

          final data = snapshot.data!.data() ?? {};
          final Timestamp? ts = data['createdAt'] as Timestamp?;
          final DateTime? createdAt = ts?.toDate();
          final String status = (data['status'] ?? '').toString();
          final String requestText =
              (data['symptoms'] ?? data['requestText'] ?? '').toString();
          final List<dynamic> symptomsArrayDyn = (data['symptomsArray'] is List)
              ? (data['symptomsArray'] as List)
              : const [];
          final List<String> symptomsArray =
              symptomsArrayDyn.map((e) => e.toString()).toList();
          final List<dynamic> predictionResultsDyn =
              (data['predictionResults'] is List)
                  ? (data['predictionResults'] as List)
                  : const [];
          // Normalize to {name, score} and sort top 5
          final List<Map<String, String>> normalized =
              predictionResultsDyn.map((e) {
            if (e is Map) {
              final String name = (e['disease'] ??
                      e['diseaseName'] ??
                      e['name'] ??
                      e['label'] ??
                      e['condition'] ??
                      e['result'] ??
                      e['prediction'] ??
                      '')
                  .toString()
                  .trim();
              final dynamic raw =
                  e['score'] ?? e['probability'] ?? e['confidence'];
              String? scoreStr;
              if (raw is num) {
                final num pct = raw <= 1 ? raw * 100 : raw;
                scoreStr = '${pct.toStringAsFixed(1)}%';
              } else if (raw is String) {
                scoreStr = raw;
              }
              return {
                'name': name.isNotEmpty ? name : 'Unknown disease',
                'score': scoreStr ?? ''
              };
            }
            return {'name': e.toString(), 'score': ''};
          }).toList();
          normalized.sort((a, b) {
            double parse(String s) {
              final t = s.replaceAll('%', '').trim();
              return double.tryParse(t) ?? -1;
            }

            return parse(b['score'] ?? '').compareTo(parse(a['score'] ?? ''));
          });
          final resultsTop5 = normalized.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          createdAt != null
                              ? _formatDateTime(createdAt)
                              : 'Unknown date',
                          style: TextStyle(color: subTextColor)),
                      const SizedBox(height: 8),
                      Text('Status: $status',
                          style: TextStyle(color: subTextColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient Request',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                          requestText.isNotEmpty
                              ? requestText
                              : 'No message provided',
                          style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Symptoms',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (symptomsArray.isEmpty)
                        Text('No structured symptoms',
                            style: TextStyle(color: subTextColor))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: symptomsArray
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0288D1)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFF0288D1)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(s,
                                        style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : const Color(0xFF01579B),
                                            fontWeight: FontWeight.w500)),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diagnosis Results',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (resultsTop5.isEmpty)
                        Text('No results attached',
                            style: TextStyle(color: subTextColor))
                      else
                        ...resultsTop5.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final r = entry.value;
                          final String scoreStr = r['score'] ?? '';
                          final double score = double.tryParse(
                                  scoreStr.replaceAll('%', '').trim()) ??
                              -1;
                          final double pct = score >= 0 ? score / 100 : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0288D1)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('$idx',
                                          style: const TextStyle(
                                              color: Color(0xFF0288D1),
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(r['name'] ?? 'Diagnosis',
                                          style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    if (scoreStr.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0288D1)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(scoreStr,
                                            style: const TextStyle(
                                                color: Color(0xFF0288D1),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    value: pct,
                                    backgroundColor: const Color(0xFF0288D1)
                                        .withOpacity(0.10),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF0288D1)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: cardColor,
                elevation: isDarkMode ? 0 : 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Doctor's Response",
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        final String response =
                            (data['doctorResponseText'] ?? '').toString();
                        if (response.isNotEmpty) {
                          return Text(response,
                              style: TextStyle(color: subTextColor));
                        }
                        // Fallback: construct from structured fields if present
                        final List<dynamic> meds =
                            (data['prescriptionMedicines'] as List?) ?? const [];
                        final List<dynamic> labs =
                            (data['prescriptionLabTests'] as List?) ?? const [];
                        final List<dynamic> gls =
                            (data['prescriptionGuidelines'] as List?) ?? const [];
                        if (meds.isEmpty && labs.isEmpty && gls.isEmpty) {
                          return Text('—', style: TextStyle(color: subTextColor));
                        }
                        final parts = <String>[];
                        if (meds.isNotEmpty) parts.add('Medicines: ' + meds.join(', '));
                        if (labs.isNotEmpty) parts.add('Lab tests: ' + labs.join(', '));
                        if (gls.isNotEmpty) parts.add('Advice: ' + gls.join(', '));
                        return Text(parts.join(' • '),
                            style: TextStyle(color: subTextColor));
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
