// lib/screens/cost_control/sayim_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart'; // main.dart'a erişim yolu
import 'bar_olustur_dialog.dart';
import 'sayim_detay_screen.dart';
import 'sayim_gecmisi_screen.dart'; // Yeni Geçmiş Sayımlar ekranı

class SayimScreen extends StatefulWidget {
  const SayimScreen({super.key});

  @override
  State<SayimScreen> createState() => _SayimScreenState();
}

class _SayimScreenState extends State<SayimScreen> {
  // TransferOnayScreen, RaporScreen, FiyatlandirmaScreen ile uyumlu renk sabitleri
  static const Color primaryColor = Colors.blue; // Ana vurgu rengi
  static const Color screenBackground =
      Color(0xFFF5F5F5); // Ekran arka planı (Çok açık gri)
  static const Color cardColor = Colors.white; // Kart/AppBar arka plan rengi
  static const Color darkTextColor = Colors.black87; // Genel koyu metin rengi
  static const Color accentColor = Colors.lightBlue; // Vurgu/İkon rengi

  Future<List<Map<String, dynamic>>>? _barList;

  @override
  void initState() {
    super.initState();
    _fetchBarList();
  }

  // Sadece BAR türündeki depoları çeker
  Future<void> _fetchBarList() async {
    setState(() {
      _barList = supabase
          .from('depolar')
          .select('id, depo_adi')
          .eq('tur', 'BAR')
          .order('depo_adi', ascending: true);
    });
  }

  // Yeni Bar Oluşturma Diyaloğunu açar
  void _showBarCreationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return BarOlusturDialog(
          // Not: BarOlusturDialog'un kendi içinde stili korunmalıdır.
          onBarCreated: () {
            _fetchBarList(); // Başarılı oluşturma sonrası listeyi yenile
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Sayım Detay Ekranına yönlendirir
  void _startCounting(int depoId, String depoAdi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SayimDetayScreen(depoId: depoId, depoAdi: depoAdi),
      ),
    ).then((_) {
      _fetchBarList(); // Sayım bitince listeyi yenile
    });
  }

  // Geçmiş Sayımlar Ekranına yönlendirir
  void _navigateToPastCounts() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SayimGecmisiScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground, // Açık gri arka plan
      appBar: AppBar(
        title: const Text('SAYIM & BAR YÖNETİMİ',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        backgroundColor: cardColor, // AppBar'ı beyaz yaptık
        foregroundColor: darkTextColor, // İkon ve metin rengi
        elevation: 0.5, // Hafif gölge
        centerTitle: true,
        // Geçmiş Sayımlar butonu
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: primaryColor),
            tooltip: 'Geçmiş Sayımlar',
            onPressed: _navigateToPastCounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Bar Oluşturma Butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showBarCreationDialog,
              icon: const Icon(Icons.add_business, color: cardColor),
              label: const Text('YENİ BAR / DEPO OLUŞTUR',
                  style: TextStyle(color: cardColor, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Ana Mavi renk kullanıldı
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // 2. Sayım Başlatma Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text('Sayım Yapılacak Barı Seçin:',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor)),
          ),

          // 3. Sayım Başlatma Listesi (Mevcut Barlar)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _barList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                final bars = snapshot.data;
                if (bars == null || bars.isEmpty) {
                  return Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('Henüz oluşturulmuş bir bar bulunmamaktadır.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ));
                }

                return RefreshIndicator(
                  onRefresh: _fetchBarList,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: bars.length,
                    itemBuilder: (context, index) {
                      final bar = bars[index];
                      return Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: primaryColor.withOpacity(0.2), width: 1.0),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.local_bar, color: accentColor),
                          title: Text(bar['depo_adi'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: darkTextColor)),
                          subtitle: const Text('Sayım başlatmak için dokunun.',
                              style: TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.navigate_next,
                              size: 24, color: primaryColor),
                          onTap: () => _startCounting(
                              bar['id'] as int, bar['depo_adi'] as String),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}