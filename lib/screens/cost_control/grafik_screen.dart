import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart'; 

class GrafikScreen extends StatefulWidget {
  const GrafikScreen({super.key});
  @override
  State<GrafikScreen> createState() => _GrafikScreenState();
}

class _GrafikScreenState extends State<GrafikScreen> {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color bgGrey = Color(0xFFF2F2F7);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 180));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'BAR'; 
  bool _isLoading = true;

  Map<String, List<FlSpot>> _chartData = {};
  List<Map<String, dynamic>> _topThree = [];
  double _periodTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    setState(() => _isLoading = true);
    try {
      final String startStr = _startDate.toIso8601String();
      final String endStr = _endDate.add(const Duration(days: 1)).toIso8601String();

      final response = await supabase
          .from('sayim_kayitlari')
          .select('''
            fark_maliyeti,
            sayim_tarihi,
            depo_id:depolar!inner(depo_adi),
            urun_id:urunler!inner(urun_adi)
          ''')
          .gte('sayim_tarihi', startStr)
          .lt('sayim_tarihi', endStr);

      final List<Map<String, dynamic>> records = List<Map<String, dynamic>>.from(response);

      Map<String, Map<int, double>> grouped = {};
      Map<String, double> totals = {};
      double grandTotal = 0;

      for (var r in records) {
        DateTime date = DateTime.parse(r['sayim_tarihi']);
        int month = date.month;
        double cost = (r['fark_maliyeti'] as num?)?.toDouble() ?? 0.0;
        String key = _selectedType == 'BAR' ? r['depo_id']['depo_adi'] : r['urun_id']['urun_adi'];

        grandTotal += cost;
        totals[key] = (totals[key] ?? 0) + cost;

        if (!grouped.containsKey(key)) grouped[key] = {};
        grouped[key]![month] = (grouped[key]![month] ?? 0) + cost;
      }

      var sortedEntries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _topThree = sortedEntries.take(3).map((e) => {'name': e.key, 'value': e.value}).toList();

      Map<String, List<FlSpot>> finalSpots = {};
      grouped.forEach((name, months) {
        List<FlSpot> spots = [];
        for (int m = 1; m <= 12; m++) {
          spots.add(FlSpot(m.toDouble(), months[m] ?? 0));
        }
        spots.sort((a, b) => a.x.compareTo(b.x));
        finalSpots[name] = spots;
      });

      setState(() {
        _chartData = finalSpots;
        _periodTotal = grandTotal;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text('MALİYET VE TREND ANALİZİ', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- GERİ OKU VE TÜM İKONLAR SİYAH YAPILDI ---
        foregroundColor: Colors.black, 
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildFilterSection(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildChartContainer(),
                    const SizedBox(height: 20),
                    _buildTopThreeSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dateBtn("BAŞLANGIÇ", _startDate, true),
              const Icon(Icons.swap_horiz, color: Colors.black),
              _dateBtn("BİTİŞ", _endDate, false),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'BAR', label: Text('Barlar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              ButtonSegment(value: 'ÜRÜN', label: Text('Ürünler', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
            ],
            selected: {_selectedType},
            onSelectionChanged: (val) {
              setState(() => _selectedType = val.first);
              _fetchRealData();
            },
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, DateTime dt, bool isStart) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(context: context, initialDate: dt, firstDate: DateTime(2023), lastDate: DateTime.now());
      if (picked != null) {
        setState(() { if (isStart) _startDate = picked; else _endDate = picked; });
        _fetchRealData();
      }
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
        Text("${dt.day}.${dt.month}.${dt.year}", style: const TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 16)),
      ],
    ),
  );

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DÖNEM TOPLAM GİDER", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("Sayım Farkları", style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          Text("${_periodTotal.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.black12, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: _leftTitles)),
          ),
          lineBarsData: _getLineData(),
        ),
      ),
    );
  }

  List<LineChartBarData> _getLineData() {
    return _chartData.entries.map((e) => LineChartBarData(
      spots: e.value,
      isCurved: true,
      color: primaryBlue,
      barWidth: 4,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: primaryBlue.withOpacity(0.1)),
    )).toList();
  }

  Widget _bottomTitles(double v, TitleMeta m) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    int idx = v.toInt() - 1;
    if (idx < 0 || idx >= 12) return const SizedBox();
    return SideTitleWidget(axisSide: m.axisSide, child: Text(months[idx], 
      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _leftTitles(double v, TitleMeta m) => Text(v.toInt().toString(), 
    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold));

  Widget _buildTopThreeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EN YÜKSEK 3 GİDER (TOP 3)", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14)),
        const SizedBox(height: 12),
        ..._topThree.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              Text("${item['value'].toStringAsFixed(2)} TL", 
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
            ],
          ),
        )),
      ],
    );
  }
}