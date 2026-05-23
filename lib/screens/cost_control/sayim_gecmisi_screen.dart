// lib/screens/cost_control/sayim_gecmisi_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart';
// Sayım Düzenle ekranını import ediyoruz
import 'sayim_duzenle_screen.dart';

class SayimGecmisiScreen extends StatefulWidget {
  const SayimGecmisiScreen({super.key});

  @override
  State<SayimGecmisiScreen> createState() => _SayimGecmisiScreenState();
}

class _SayimGecmisiScreenState extends State<SayimGecmisiScreen> {
  // TransferOnayScreen, RaporScreen, FiyatlandirmaScreen ile uyumlu renk sabitleri
  static const Color primaryColor = Colors.blue; // Ana vurgu rengi
  static const Color screenBackground =
      Color(0xFFF5F5F5); // Ekran arka planı (Çok açık gri)
  static const Color cardColor = Colors.white; // Kart/AppBar arka plan rengi
  static const Color darkTextColor = Colors.black87; // Genel koyu metin rengi
  static const Color lostColor = Colors.red; // Kayıp/Gider rengi
  static const Color surplusColor = Colors.green; // Fazla/Karşılama rengi

  Future<Map<String, List<Map<String, dynamic>>>>? _pastCountsFuture;

  @override
  void initState() {
    super.initState();
    _pastCountsFuture = _fetchPastCounts();
  }

  // Geçmiş sayım kayıtlarını çeker ve tarih bazında gruplar
  Future<Map<String, List<Map<String, dynamic>>>> _fetchPastCounts() async {
    try {
      // Sayım kayıtlarını, depo ve ürün bilgileriyle birlikte çek
      final List<Map<String, dynamic>> records = await supabase
          .from('sayim_kayitlari')
          .select('''
            id, sayim_tarihi, sayilan_miktar, teorik_miktar, fark_miktar, fark_maliyeti,
            depo_id:depolar!inner(depo_adi),
            urun_id:urunler!inner(urun_adi, birim, birim_fiyati)
          ''')
          .order('sayim_tarihi', ascending: false);

      // Anahtar: Sayım Tarihi (GG/AA/YYYY)
      Map<String, List<Map<String, dynamic>>> groupedCounts = {};

      for (var record in records) {
        final dateTime =
            DateTime.parse(record['sayim_tarihi'] as String).toLocal();
        // Tarih formatlama
        final dateKey =
            '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';

        if (!groupedCounts.containsKey(dateKey)) {
          groupedCounts[dateKey] = [];
        }
        groupedCounts[dateKey]!.add(record);
      }
      return groupedCounts;
    } catch (e) {
      throw Exception('Geçmiş sayım verileri çekilemedi: ${e.toString()}');
    }
  }

  // Sayım Düzenleme Ekranını Açar
  void _openEditScreen(Map<String, dynamic> record) async {
    final int recordId = record['id'] as int;
    final barName = (record['depo_id'] as Map)['depo_adi'] as String;
    final productMap = (record['urun_id'] as Map);
    final productName = productMap['urun_adi'] as String;
    final productUnit = productMap['birim'] as String;
    final counted = (record['sayilan_miktar'] as num).toDouble();

    // Düzenleme ekranını aç ve sonucu bekle
    final bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SayimDuzenleScreen(
          sayimKayitId: recordId,
          urunAdi: productName,
          depoAdi: barName,
          mevcutSayim: counted,
          birim: productUnit,
        ),
      ),
    );

    // Eğer başarılı bir güncelleme sinyali gelirse listeyi yenile
    if (isUpdated == true) {
      setState(() {
        _pastCountsFuture = _fetchPastCounts();
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text('Liste yenileniyor...'),
           backgroundColor: primaryColor,
        ));
      }
    }
  }

  // Geçmiş Sayım Detay Kartı
  Widget _buildCountDetailCard(Map<String, dynamic> record) {
    final barName = (record['depo_id'] as Map)['depo_adi'] as String;
    final productMap = (record['urun_id'] as Map);
    final productName = productMap['urun_adi'] as String;
    final productUnit = productMap['birim'] as String;
    final theoretical = (record['teorik_miktar'] as num).toDouble();
    final counted = (record['sayilan_miktar'] as num).toDouble();
    final difference = (record['fark_miktar'] as num).toDouble();
    final cost = (record['fark_maliyeti'] as num).toDouble();

    // Fark durumuna göre renk ve ikon
    Color diffColor = darkTextColor.withOpacity(0.6); // Sıfır fark
    IconData diffIcon = Icons.remove_circle_outline;
    String diffText = 'Fark: ${difference.abs().toStringAsFixed(2)}';
    
    if (difference < 0) {
      diffColor = lostColor; // Kayıp/Gider (Kırmızı)
      diffIcon = Icons.arrow_downward;
      diffText = 'Açık: ${difference.abs().toStringAsFixed(2)}'; // Farkın negatif olması açık anlamına gelir
    } else if (difference > 0) {
      diffColor = surplusColor; // Fazla/Karşılama (Yeşil)
      diffIcon = Icons.arrow_upward;
      diffText = 'Fazla: ${difference.abs().toStringAsFixed(2)}';
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(diffIcon, color: diffColor, size: 20),
      title: Text(
        '$productName (${barName})',
        style: const TextStyle(fontWeight: FontWeight.w600, color: darkTextColor),
      ),
      subtitle: Text(
        'Sayım: ${counted.toStringAsFixed(2)} $productUnit | Teorik: ${theoretical.toStringAsFixed(2)} $productUnit',
        style: TextStyle(color: darkTextColor.withOpacity(0.7), fontSize: 13),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(diffText,
              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold)),
          Text(
            '${cost.toStringAsFixed(2)} TL',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      // Tıklanma işlevi eklendi
      onTap: () => _openEditScreen(record),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground, // Açık gri arka plan
      appBar: AppBar(
        title: const Text('GEÇMİŞ SAYIM KAYITLARI',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        backgroundColor: cardColor, // AppBar'ı beyaz yaptık
        foregroundColor: darkTextColor, // İkon ve metin rengi
        elevation: 0.5, // Hafif gölge
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _pastCountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: lostColor, fontWeight: FontWeight.bold)),
                ));
          }
          final groupedCounts = snapshot.data;
          if (groupedCounts == null || groupedCounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('Henüz kaydedilmiş sayım kaydı bulunmamaktadır.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _pastCountsFuture = _fetchPastCounts();
                      });
                    },
                    icon: const Icon(Icons.refresh, color: primaryColor),
                    label: const Text('Listeyi Yenile',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          // Tarih anahtarlarını büyükten küçüğe sırala (Zaten çekilirken sıralanıyor, sadece key listesi lazım)
          final sortedDates = groupedCounts.keys.toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _pastCountsFuture = _fetchPastCounts();
              });
              await _pastCountsFuture;
            },
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: sortedDates.length,
              itemBuilder: (context, dateIndex) {
                final dateKey = sortedDates[dateIndex];
                final recordsOnDate = groupedCounts[dateKey]!;

                // Tarih bazında Expandable Kart
                return Card(
                  color: cardColor,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: primaryColor.withOpacity(0.3), width: 1.0),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                    title: Text('Sayım Tarihi: $dateKey',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: darkTextColor)),
                    subtitle: Text('${recordsOnDate.length} adet kayıt', style: TextStyle(color: darkTextColor.withOpacity(0.7))),
                    iconColor: primaryColor,
                    collapsedIconColor: darkTextColor.withOpacity(0.7),
                    children: recordsOnDate.map((record) {
                      return _buildCountDetailCard(record);
                    }).toList(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}