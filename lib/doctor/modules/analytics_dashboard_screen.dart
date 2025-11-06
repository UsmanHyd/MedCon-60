import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medcon30/theme/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final bgColor = isDarkMode ? Colors.grey[900] : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: cardColor,
        foregroundColor: const Color(0xFF0288D1),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: cardColor,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF0288D1)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top stats
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                icon: Icons.person,
                label: 'Total Patients',
                value: '1,248',
                change: '+8.2%',
                changeColor: Colors.green,
                iconColor: Colors.blue,
                isDarkMode: isDarkMode,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                icon: Icons.calendar_today,
                label: 'Appointments',
                value: '342',
                change: '+12.5%',
                changeColor: Colors.green,
                iconColor: Colors.green,
                isDarkMode: isDarkMode,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                icon: Icons.star,
                label: 'Rating',
                value: '4.8',
                change: '+0.3',
                changeColor: Colors.green,
                iconColor: Colors.orange,
                isDarkMode: isDarkMode,
              )),
            ],
          ),
          const SizedBox(height: 18),
          // Appointment Trends
          _SectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appointment Trends',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _ChipToggle(
                        options: ['Week', 'Month', 'Year'], selected: 0),
                    Spacer(),
                    Text('Export',
                        style: TextStyle(
                            color: Color(0xFF0288D1),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData:
                          const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 28),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              return Text(days[value.toInt() % 7],
                                  style: TextStyle(
                                      fontSize: 11, color: subTextColor));
                            },
                            reservedSize: 24,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 25,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 12),
                            const FlSpot(1, 15),
                            const FlSpot(2, 18),
                            const FlSpot(3, 22),
                            const FlSpot(4, 21),
                            const FlSpot(5, 10),
                            const FlSpot(6, 2),
                          ],
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                              show: true, color: Colors.blue.withOpacity(0.12)),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Patient Statistics
          _SectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Patient Statistics',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Spacer(),
                    Text('View All',
                        style: TextStyle(
                            color: Color(0xFF0288D1),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 10),
                        child: _PieStatCard(
                          title: 'Patient Type',
                          labels: const ['New', 'Returning'],
                          values: const [30, 70],
                          colors: const [Colors.blue, Colors.grey],
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 10),
                        child: _BarStatCard(
                          title: 'Age Distribution',
                          values: const [10, 25, 35, 15],
                          labels: const ['0-18', '19-40', '41-65', '65+'],
                          color: Colors.blue,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: _PieStatCard(
                          title: 'Gender Ratio',
                          labels: const ['Male', 'Female'],
                          values: const [45, 55],
                          colors: const [Colors.blue, Colors.pink],
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Top Conditions Treated
          _SectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Conditions Treated',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...[
                  {'label': 'Hypertension', 'percent': 0.24},
                  {'label': 'Diabetes', 'percent': 0.18},
                  {'label': 'Respiratory Infections', 'percent': 0.15},
                  {'label': 'Anxiety/Depression', 'percent': 0.12},
                  {'label': 'Allergies', 'percent': 0.09},
                ].map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 120,
                              child: Text(c['label'] as String,
                                  style: TextStyle(color: textColor))),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: c['percent'] as double,
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              color: Colors.blue,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${((c['percent'] as double) * 100).toInt()}%',
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Key Insights
          _SectionCard(
            isDarkMode: isDarkMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Insights',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _InsightRow(
                  icon: Icons.lightbulb,
                  color: Colors.blue,
                  text:
                      'AI-Powered Insights\nBased on your practice data from the last 30 days',
                  isDarkMode: isDarkMode,
                ),
                _InsightRow(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  text:
                      'Patient retention has improved by 14% this month, likely due to your new follow-up protocol.',
                  isDarkMode: isDarkMode,
                ),
                _InsightRow(
                  icon: Icons.video_call,
                  color: Colors.blue,
                  text:
                      'Telemedicine consultations have increased by 23%, contributing to higher overall efficiency.',
                  isDarkMode: isDarkMode,
                ),
                _InsightRow(
                  icon: Icons.warning,
                  color: Colors.orange,
                  text:
                      'Procedure bookings have decreased by 2.3%. Consider reviewing pricing or promoting these services.',
                  isDarkMode: isDarkMode,
                ),
                _InsightRow(
                  icon: Icons.access_time,
                  color: Colors.red,
                  text:
                      'Peak appointment times are reaching capacity. Consider extending hours on Tuesdays and Thursdays.',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets and functions for the dashboard UI

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color changeColor;
  final Color iconColor;
  final bool isDarkMode;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.change,
      required this.changeColor,
      required this.iconColor,
      required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.18)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            isDarkMode ? Colors.grey[300] : Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                        changeColor == Colors.green
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: changeColor,
                        size: 16),
                    const SizedBox(width: 2),
                    Text(change,
                        style: TextStyle(
                            color: changeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  const _SectionCard({required this.child, required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.18)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final List<String> options;
  final int selected;
  const _ChipToggle({required this.options, required this.selected});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      children: List.generate(
          options.length,
          (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(options[i]),
                  selected: i == selected,
                  selectedColor: const Color(0xFF0288D1),
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  labelStyle: TextStyle(
                      color: i == selected
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black)),
                ),
              )),
    );
  }
}

class _PieStatCard extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final bool isDarkMode;
  const _PieStatCard(
      {required this.title,
      required this.labels,
      required this.values,
      required this.colors,
      required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: PieChart(
              PieChartData(
                sections: List.generate(
                    values.length,
                    (i) => PieChartSectionData(
                          value: values[i],
                          color: colors[i],
                          radius: 18,
                          title: '',
                        )),
                sectionsSpace: 2,
                centerSpaceRadius: 16,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                labels.length,
                (i) => Row(
                      children: [
                        Container(width: 10, height: 10, color: colors[i]),
                        const SizedBox(width: 4),
                        Text(labels[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700])),
                      ],
                    )),
          ),
        ],
      ),
    );
  }
}

class _BarStatCard extends StatelessWidget {
  final String title;
  final List<double> values;
  final List<String> labels;
  final Color color;
  final bool isDarkMode;
  const _BarStatCard(
      {required this.title,
      required this.values,
      required this.labels,
      required this.color,
      required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 40,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(labels[value.toInt() % labels.length],
                            style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700]));
                      },
                      reservedSize: 20,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                    values.length,
                    (i) => BarChartGroupData(x: i, barRods: [
                          BarChartRodData(toY: values[i], color: color)
                        ])),
                backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDarkMode;
  const _InsightRow(
      {required this.icon,
      required this.color,
      required this.text,
      required this.isDarkMode});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : Colors.black))),
        ],
      ),
    );
  }
}
