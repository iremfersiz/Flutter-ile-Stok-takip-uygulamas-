// lib/screens/cost_control/rapor_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart'; 

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

// Rapor sonuçlarını tutacak ana yapı
class CostReport {
  double totalCost;
  Map<String, double> barCosts; // Bar Adı -> Maliyet
  Map<String, double> productCosts; // Ürün Adı -> Maliyet

  CostReport({
    required this.totalCost, 
    required this.barCosts, 
    required this.productCosts
  });
}

class _RaporScreenState extends State<RaporScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Future<CostReport>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchCostReport(_startDate, _endDate);
  }

  // Cost Sayım Kayıtlarını Çekme ve Raporlama
  Future<CostReport> _fetchCostReport(DateTime start, DateTime end) async {
    // Supabase'de tarih aralığı filtresi için UTC ISO formatına çevrilir
    final String startDateStr = start.toIso8601String();
    // Bitiş gününün tamamını dahil etmek için 1 gün ekliyoruz
    final String endDateStr = end.add(const Duration(days: 1)).toIso8601String(); 

    try {
      // Sayım kayıtlarını, depo ve ürün bilgileriyle birlikte çek
      final List<Map<String, dynamic>> records = await supabase
          .from('sayim_kayitlari')
          .select('''
            fark_maliyeti,
            depo_id:depolar!inner(depo_adi),
            urun_id:urunler!inner(urun_adi)
          ''')
          .gte('sayim_tarihi', startDateStr) // Başlangıç tarihinden büyük veya eşit
          .lt('sayim_tarihi', endDateStr);  // Bitiş tarihinden küçük

      double totalCost = 0.0;
      Map<String, double> barCosts = {};
      Map<String, double> productCosts = {};

      for (var record in records) {
        final cost = (record['fark_maliyeti'] as num?)?.toDouble() ?? 0.0;
        final barName = (record['depo_id'] as Map)['depo_adi'] as String;
        final productName = (record['urun_id'] as Map)['urun_adi'] as String;

        // Toplam Gider
        totalCost += cost;

        // Bar Bazında Gider
        barCosts[barName] = (barCosts[barName] ?? 0) + cost;

        // Ürün Bazında Gider
        productCosts[productName] = (productCosts[productName] ?? 0) + cost;
      }

      return CostReport(
        totalCost: totalCost,
        barCosts: barCosts,
        productCosts: productCosts,
      );

    } catch (e) {
      // Hata oluşursa, hata mesajını gösteririz
      throw Exception('Rapor verisi çekilirken hata: ${e.toString()}');
    }
  }

  // Tarih Seçici
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Tarih seçici temasını açık moda uygun ayarla
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue, // Başlık arka plan rengi
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        // Yeni tarih aralığı ile raporu yenile
        _reportFuture = _fetchCostReport(_startDate, _endDate);
      });
    }
  }
  
  // Rapor Detay Kartı oluşturma
  Widget _buildDetailCard(String title, Map<String, double> data) {
    // Maliyeti yüksekten düşüğe sıralar
    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return Card(
      // Beyaz arka plan
      color: const Color.fromARGB(255, 255, 255, 255), 
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            // Başlık rengi daha koyu bir renk
            color: Colors.blue.shade800
          )
        ),
        children: sortedData.map((entry) {
          // Maliyeti sıfır olanları gösterme
          if (entry.value <= 0) return const SizedBox.shrink();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(entry.key, style: const TextStyle(color: Colors.black87)),
            trailing: Text(
              '${entry.value.toStringAsFixed(2)} TL',
              style: const TextStyle(
                fontWeight: FontWeight.w600, 
                // Gider rengi
                color: Colors.redAccent
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold arka planını açık mod için beyaz yap
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'GİDER ANALİZ RAPORU', 
          // AppBar başlık rengini koyu yap
          style: TextStyle(color: Color.fromARGB(255, 8, 7, 7))
        ),
        centerTitle: true,
        // AppBar arka planını mavi yap
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), 
        // AppBar parlaklığını açık tema için ayarla (isteğe bağlı)
        elevation: 0,
        
        // Geri (Back) butonunun rengini siyah yapar
        foregroundColor: Colors.black, // <--- BURASI DEĞİŞTİRİLDİ
        
      ),

      body: Column(
        children: [
          // --- Tarih Filtreleri ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDateFilterButton('Başlangıç', _startDate, true),
                _buildDateFilterButton('Bitiş', _endDate, false),
              ],
            ),
          ),
          
          // --- Rapor Sonuçları ---
          Expanded(
            child: FutureBuilder<CostReport>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    // Hata metin rengini siyah yap
                    child: Text(
                      'Hata: ${snapshot.error}', 
                      style: const TextStyle(color: Colors.red)
                    )
                  );
                }
                final report = snapshot.data!;
                
                return RefreshIndicator(
                  onRefresh: () async {
                    // RefreshIndicator'da Future'ı setstate içinde güncellemeliyiz.
                    setState(() {
                      _reportFuture = _fetchCostReport(_startDate, _endDate);
                    });
                    // Future'ın tamamlanmasını bekle
                    await _reportFuture;
                  },
                  color: Colors.blue, // RefreshIndicator rengi
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 1. Otelin Toplam Gideri
                      Card(
                        // Açık mavi arka plan
                        color: Colors.blue.shade100, 
                        elevation: 5,
                        child: ListTile(
                          title: const Text(
                            'OTEL TOPLAM GİDERİ (SAYIM FARKI)', 
                            // Başlık metin rengi koyu
                            style: TextStyle(color: Colors.black87)
                          ),
                          trailing: Text(
                            '${report.totalCost.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              // Gider rengi
                              color: Colors.red
                            ),
                          ),
                        ),
                      ),
                      
                      // 2. Bar Bazında Giderler
                      _buildDetailCard('Bar Bazında Toplam Giderler', report.barCosts),
                      
                      // 3. Ürünlerin Ayrı Ayrı Giderleri
                      _buildDetailCard('Ürün Bazında En Yüksek Maliyet', report.productCosts),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateFilterButton(String label, DateTime date, bool isStartDate) {
    return Column(
      children: [
        Text(
          label, 
          // Metin rengini siyah yap
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)
        ),
        const SizedBox(height: 5),
        OutlinedButton.icon(
          onPressed: () => _selectDate(context, isStartDate),
          style: OutlinedButton.styleFrom(
            // Buton kenar ve metin rengini mavi yap
            foregroundColor: Colors.blue, 
            side: const BorderSide(color: Colors.blue),
          ),
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text('${date.day}/${date.month}/${date.year}'),
        ),
      ],
    );
  }
}