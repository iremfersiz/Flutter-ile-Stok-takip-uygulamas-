// lib/screens/cost_control/kisi_basi_maliyet_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 

class KisiBasiMaliyetScreen extends StatefulWidget {
  const KisiBasiMaliyetScreen({super.key});

  @override
  State<KisiBasiMaliyetScreen> createState() => _KisiBasiMaliyetScreenState();
}

class _KisiBasiMaliyetScreenState extends State<KisiBasiMaliyetScreen> {
  // Hesaplama için değişkenler
  double _lastTotalCost = 0.0;
  double _costPerPerson = 0.0;
  final TextEditingController _personCountController = TextEditingController();
  
  // Rapor verisini çeken Future
  Future<void>? _dataFuture;
  
  // Tarih Filtresi (Varsayılan olarak son 30 gün)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Renk Paleti (Mavi Tema)
  static const Color _primaryColor = Colors.indigo; // Koyu Mavi (Yazılar için de kullanılacak)
  static const Color _accentColor = Colors.lightBlue; // Açık Mavi Vurgu
  static const Color _backgroundColor = Colors.white; // Genel Arka Plan ve AppBar Rengi
  static const Color _cardColor = Color(0xFFF3F4F6); // Hafif gri kart
  static const Color _resultColor = Colors.red; // Gider Sonucu
  static const Color _costPerPersonColor = Colors.indigo; // Kişi Başı Maliyet Sonucu Rengi

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchAndCalculateCost();
  }

  // Sayım kayıtlarını çeker ve toplam maliyeti hesaplar
  Future<void> _fetchAndCalculateCost() async {
    final String startDateStr = _startDate.toIso8601String();
    final String endDateStr = _endDate.add(const Duration(days: 1)).toIso8601String();
    
    var query = supabase
        .from('sayim_kayitlari')
        .select('fark_maliyeti')
        .gte('sayim_tarihi', startDateStr)
        .lt('sayim_tarihi', endDateStr);

    try {
        final List<Map<String, dynamic>> records = await query;
        double newTotalCost = 0.0;
        
        for (var record in records) {
            newTotalCost += (record['fark_maliyeti'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
            _lastTotalCost = newTotalCost;
            _calculateCostPerPerson(_personCountController.text); 
        });

    } catch (e) {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Veri çekilirken hata: $e'))
            );
        }
    }
  }
  
  // Kişi başı maliyeti hesaplar
  void _calculateCostPerPerson(String personCountText) {
    final int personCount = int.tryParse(personCountText) ?? 0;
    
    if (personCount > 0 && _lastTotalCost >= 0) {
      setState(() {
        _costPerPerson = _lastTotalCost / personCount;
      });
    } else {
      setState(() {
        _costPerPerson = 0.0;
      });
    }
  }

  // Tarih Seçici
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Tema: DatePicker'ın rengini ayarla (Mavi)
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _primaryColor,
            colorScheme: const ColorScheme.light(primary: _primaryColor),
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
      });
      _dataFuture = _fetchAndCalculateCost(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, 
      appBar: AppBar(
        // İsteğiniz üzerine AppBar Beyaz, Yazı Siyah/Koyu Mavi yapıldı
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('KİŞİ BAŞI MALİYET', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)),
        backgroundColor: _backgroundColor, 
        elevation: 0, // Hafif gölge ekleyelim
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryColor));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tarih Filtreleri
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: _cardColor, 
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 Gider Aralığını Seçin', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor)
                        ),
                        const Divider(color: _primaryColor, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDateFilterButton('Başlangıç', _startDate, true),
                            _buildDateFilterButton('Bitiş', _endDate, false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Hesaplama ve Sonuç Alanı
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: _cardColor, 
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💰 MALİYET BİLGİLERİ', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor)
                        ),
                        const Divider(color: _accentColor, height: 20),

                        // Toplam Gider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1. Toplam Kayıp Gideri (TL):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color:Colors.black)),
                            Text(
                              _lastTotalCost.toStringAsFixed(2), 
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _resultColor)
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Kişi Sayısı Girişi
                        const Text(
                          // Yazı rengi siyah
                          '2. Kişi Sayısı Girin (Örn: Toplam Misafir)', 
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _personCountController,
                          keyboardType: TextInputType.number,
                          autofocus: true, 
                          style: const TextStyle(color: Colors.black), // Giriş metnini siyah yaptık
                          decoration: InputDecoration(
                            labelText: 'Kişi Sayısı',
                            hintText: 'Misafir sayısını buraya girin',
                            labelStyle: const TextStyle(color: Colors.black54),
                            hintStyle: const TextStyle(color: Colors.black38),
                            prefixIcon: const Icon(Icons.people_alt, color: _primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          onChanged: _calculateCostPerPerson, 
                        ),
                        const SizedBox(height: 30),

                        // SONUÇ: Kişi Başı Maliyet
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _accentColor.withOpacity(0.3)),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('KİŞİ BAŞI MALİYET:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _costPerPersonColor)),
                                Text(
                                  '${_costPerPerson.toStringAsFixed(2)} TL',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _costPerPersonColor),
                                ),
                              ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tarih Filtre Butonu Widget'ı
  Widget _buildDateFilterButton(String label, DateTime date, bool isStartDate) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _selectDate(context, isStartDate),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor, 
            side: const BorderSide(color: _primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.date_range, size: 20),
          label: Text(
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}