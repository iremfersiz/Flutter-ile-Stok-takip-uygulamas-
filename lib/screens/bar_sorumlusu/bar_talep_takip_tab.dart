// lib/screens/bar_sorumlusu/bar_talep_takip_tab.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; 

class BarTalepTakipTab extends StatefulWidget {
  const BarTalepTakipTab({super.key});

  @override
  State<BarTalepTakipTab> createState() => _BarTalepTakipTabState();
}

class _BarTalepTakipTabState extends State<BarTalepTakipTab> {
  // ☀️ NORMAL TEMA (Light Mode) Sabitleri
  static const Color primaryColor = Colors.blue; // Temel mavi vurgu
  static const Color backgroundColor = Colors.white; // Açık arka plan
  static const Color cardColor = Colors.white; // Kart arka planı (Beyaz)
  static const Color lightTextColor = Colors.black87; // Metin rengi (Koyu)
  static const Color secondaryTextColor = Colors.black54; // İkincil metin (Daha açık koyu)
  static const Color pendingColor = Colors.orange; // Beklemede (Turuncu)
  static const Color successColor = Colors.green; // Başarılı (Yeşil)
  static const Color dangerColor = Colors.red; // Tehlike (Kırmızı)

  Future<List<Map<String, dynamic>>>? _myRequests;

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  // Duruma göre renk döndürür
  Color _getStatusColor(String durum) {
    switch (durum) {
      case 'ONAYLANDI':
        return successColor;
      case 'REDDEDİLDİ':
        return dangerColor;
      case 'BEKLEMEDE':
      default:
        return pendingColor;
    }
  }
  
  // SADECE kullanıcının kendi deposundan gelen talepleri çeker
  Future<void> _fetchMyRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userDepotId = prefs.getInt('user_depot_id'); 

    if (userDepotId == null) {
      setState(() {
        _myRequests = Future.error('Kullanıcıya atanmış depo bulunamadı.');
      });
      return;
    }

    var query = supabase
        .from('transfer_talepleri')
        .select('*, talep_eden_depo_id:depolar!inner(depo_adi), urun_id:urunler!inner(urun_adi, birim)')
        .eq('talep_eden_depo_id', userDepotId) // Filtre uygulandı
        .order('talep_tarihi', ascending: false);

    setState(() {
      _myRequests = query;
    });
  }

  // YARDIMCI WIDGET: Talep Kartını oluşturur
  Widget _buildRequestCard(Map<String, dynamic> request) {
    // final barName = (request['talep_eden_depo_id'] as Map?)?['depo_adi'] ?? '---'; 
    final productName = (request['urun_id'] as Map?)?['urun_adi'] ?? 'Bilinmeyen Ürün';
    final productBirim = (request['urun_id'] as Map?)?['birim'] ?? 'Adet';
    final requestedAmount = (request['talep_edilen_miktar'] as num).toDouble();
    final status = request['durum'] as String;
    final approvedAmount = (request['cevap_miktar'] as num?)?.toDouble();
    final statusColor = _getStatusColor(status);

    String responseText = 'Cevap bekleniyor...';
    if (status == 'ONAYLANDI') {
      final finalAmount = approvedAmount ?? requestedAmount;
      responseText = '✅ Onaylanan Miktar: ${finalAmount.toStringAsFixed(2)} $productBirim';
    } else if (status == 'REDDEDİLDİ') {
      responseText = '❌ Talep REDDEDİLDİ.';
    }

    final date = request['talep_tarihi'] != null
        ? DateTime.parse(request['talep_tarihi']).toLocal()
        : DateTime.now().toLocal();
    
    // Tarih formatı: GG.AA.YYYY SS:DD
    final dateString = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';


    return Card(
      color: cardColor, // Normal modda beyaz/açık gri kart
      elevation: 3, // Biraz daha az gölge
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Duruma göre çerçeve rengi
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Icon(
          status == 'ONAYLANDI'
              ? Icons.check_circle_outline
              : status == 'REDDEDİLDİ'
                  ? Icons.cancel_outlined
                  : Icons.schedule,
          color: statusColor,
          size: 32,
        ),
        title: Text(
          '$productName',
          style: const TextStyle(fontWeight: FontWeight.bold, color: lightTextColor, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
                'İstenen Miktar: ${requestedAmount.toStringAsFixed(2)} $productBirim',
                style: const TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 2),
            Text(
              responseText,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Talep Tarihi: $dateString',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2), // Hafif arka plan
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 1), // Renkli çerçeve
          ),
          child: Text(
            status,
            style: TextStyle(
                color: statusColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, // Normal modda renkli etiket için metin rengini ayarla
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container( // Arka plan rengini normal tema yap
      color: backgroundColor,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _myRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Veri çekilirken hata oluştu: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: dangerColor, fontSize: 16)),
            ));
          }
          final requests = snapshot.data;
          if (requests == null || requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('Henüz gönderilmiş transfer talebi yok.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _fetchMyRequests,
                    icon: const Icon(Icons.refresh, color: primaryColor),
                    label: const Text('Listeyi Yenile',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchMyRequests,
            color: primaryColor,
            backgroundColor: Colors.white, // Yenileme göstergesinin arka planı
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(requests[index]);
              },
            ),
          );
        },
      ),
    );
  }
}