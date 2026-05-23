import 'package:flutter/material.dart';
import '../../main.dart'; 

class AlimGecmisiScreen extends StatefulWidget {
  const AlimGecmisiScreen({super.key});

  @override
  State<AlimGecmisiScreen> createState() => _AlimGecmisiScreenState();
}

class _AlimGecmisiScreenState extends State<AlimGecmisiScreen> {
  static const Color primaryColor = Colors.blue;
  static const Color screenBackground = Color(0xFFF2F2F7);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<Map<String, dynamic>> _alimlar = [];
  double _totalSpending = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlimlar();
  }

  Future<void> _fetchAlimlar() async {
    setState(() => _isLoading = true);
    
    final String startDateStr = _startDate.toIso8601String();
    final String endDateStr = _endDate.add(const Duration(days: 1)).toIso8601String();

    try {
      // 1. Önce alımları çekiyoruz
      final alimlarRes = await supabase
          .from('alislar')
          .select()
          .gte('tarih', startDateStr)
          .lt('tarih', endDateStr)
          .order('tarih', ascending: false);

      final List<Map<String, dynamic>> rawAlimlar = List<Map<String, dynamic>>.from(alimlarRes);

      // 2. Tüm ürünleri çekip bir haritaya (Map) alıyoruz (Hızlı eşleşme için)
      final urunlerRes = await supabase.from('urunler').select('id, urun_adi');
      final Map<int, String> urunMap = {
        for (var u in urunlerRes) (u['id'] as int): (u['urun_adi'] as String)
      };

      double total = 0;
      for (var alim in rawAlimlar) {
        // Ürün adını Map üzerinden ID ile bulup ekliyoruz
        int uId = alim['urun_id'];
        alim['display_name'] = urunMap[uId] ?? 'Silinmiş Ürün (ID: $uId)';
        total += (alim['toplam_tutar'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        _alimlar = rawAlimlar;
        _totalSpending = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) _startDate = picked; else _endDate = picked;
      });
      _fetchAlimlar();
    }
  }

  String _formatDate(String isoString) {
    DateTime dt = DateTime.parse(isoString).toLocal();
    return "${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('SATIN ALMA GEÇMİŞİ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildDateFilters(),
          _buildTotalCard(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchAlimlar,
                  child: _alimlar.isEmpty
                      ? const Center(child: Text('Bu tarihlerde alım bulunamadı.', style: TextStyle(color: Colors.black)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _alimlar.length,
                          itemBuilder: (context, index) => _buildAlimCard(_alimlar[index]),
                        ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dateBtn('Başlangıç', _startDate, true),
          _dateBtn('Bitiş', _endDate, false),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, DateTime date, bool isStart) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      OutlinedButton(
        onPressed: () => _selectDate(context, isStart),
        child: Text("${date.day}.${date.month}.${date.year}", style: const TextStyle(color: primaryColor)),
      ),
    ],
  );

  Widget _buildTotalCard() => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dönem Toplam Harcama', style: TextStyle(color: Colors.white70)),
          Text('${_totalSpending.toStringAsFixed(2)} TL', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _buildAlimCard(Map<String, dynamic> alim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alim['display_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text(_formatDate(alim['tarih']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${alim['miktar']} Adet / ${alim['birim_hacim']} cl', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${alim['birim_fiyat']} TL', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              Text('${alim['toplam_tutar']} TL', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}