// lib/screens/cost_control/transfer_onay_screen.dart (AÇIK RENK TEMA İLE UYUMLU)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../main.dart'; 

class TransferOnayScreen extends StatefulWidget {
  const TransferOnayScreen({super.key});

  @override
  State<TransferOnayScreen> createState() => _TransferOnayScreenState();
}

class _TransferOnayScreenState extends State<TransferOnayScreen> {
  // Renk ve Stil Sabitleri (Depolar Ekranı ile aynı)
  static const Color primaryColor = Colors.blue; // Ana vurgu rengi
  static const Color accentColor = Colors.lightBlue; // İkincil vurgu rengi
  static const Color cardColor = Colors.white; // Kart arka plan rengi
  static const Color screenBackground = Color(0xFFF5F5F5); // Ekran arka planı (Çok açık gri)
  static const Color darkTextColor = Colors.black87; // Genel koyu metin rengi
  
  static const Color successColor = Colors.green; // Onay
  static const Color dangerColor = Colors.redAccent; // Red
  static const Color warningColor = Colors.orange; // Kısmi Onay

  Future<List<Map<String, dynamic>>>? _pendingRequests;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  // Bekleyen transfer taleplerini çekme fonksiyonu (Değiştirilmedi)
  Future<void> _fetchPendingRequests() async {
    setState(() {
      _pendingRequests = supabase
          .from('transfer_talepleri')
          .select('id, talep_edilen_miktar, talep_eden_depo_id, urun_id, talep_tarihi, talep_eden_depo_id:depolar!inner(depo_adi, id), urun_id:urunler!inner(urun_adi, birim, id)') 
          .eq('durum', 'BEKLEMEDE')
          .order('talep_tarihi', ascending: true);
    });
  }

  // YARDIMCI FONKSİYON: Stok Güncelleme İşlemi (Değiştirilmedi)
  Future<void> _updateStock(int depoId, int urunId, double delta) async {
      final existingStock = await supabase.from('stoklar')
          .select('adet') 
          .eq('depo_id', depoId)
          .eq('urun_id', urunId)
          .maybeSingle();

      final double currentStock = (existingStock?['adet'] as num?)?.toDouble() ?? 0.0;
      final double newStock = currentStock + delta;

      if (existingStock != null) {
          await supabase.from('stoklar')
              .update({'adet': newStock})
              .eq('depo_id', depoId)
              .eq('urun_id', urunId);
      } else if (newStock > 0) {
          await supabase.from('stoklar').insert({
              'depo_id': depoId,
              'urun_id': urunId,
              'adet': newStock,
          });
      }
  }


  // Talebi onaylama işlemi (Değiştirilmedi)
  Future<void> _processRequest(int requestId, int talepEdenDepoId, int urunId, double requestedAmount, [double? approvedAmount]) async {
    final double finalAmount = approvedAmount ?? requestedAmount;

    setState(() => _isLoading = true);

    try {
        if (talepEdenDepoId <= 0 || urunId <= 0) {
            throw Exception("Talep Eden Depo veya Ürün ID'si hatalı. İşlem İptal.");
        }
        
        final mainDepo = await supabase.from('depolar').select('id').eq('tur', 'ANA').maybeSingle();
        final mainDepoId = mainDepo?['id'] as int?;

        if (mainDepoId == null) throw Exception("Ana Depo ID'si veritabanında bulunamadı.");

        final mainStockRecord = await supabase.from('stoklar')
            .select('adet')
            .eq('depo_id', mainDepoId)
            .eq('urun_id', urunId)
            .maybeSingle();

        final double availableStock = (mainStockRecord?['adet'] as num?)?.toDouble() ?? 0.0;
        
        if (finalAmount > availableStock) {
              throw Exception("Ana Depo stoğu yetersiz! Mevcut: ${availableStock.toStringAsFixed(2)}");
        }
        
        // --- İŞLEM BAŞARILI: STOK VE TALEP GÜNCELLEMELERİ ---
        await _updateStock(mainDepoId, urunId, -finalAmount); 
        await _updateStock(talepEdenDepoId, urunId, finalAmount); 

        await supabase
            .from('transfer_talepleri')
            .update({'durum': 'ONAYLANDI', 'cevap_miktar': finalAmount})
            .eq('id', requestId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Talep başarıyla onaylandı (${finalAmount.toStringAsFixed(2)} adet).'), backgroundColor: successColor)
        );
        _fetchPendingRequests(); 

    } on PostgrestException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veritabanı Hatası: ${e.message}'), backgroundColor: dangerColor)
        );
    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İşlem Hatası: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: dangerColor)
        );
    } finally {
        if (mounted) {
            setState(() => _isLoading = false);
        }
    }
  }

  // Talebi Reddetme Fonksiyonu (Değiştirilmedi)
  Future<void> _rejectRequest(int requestId) async {
      setState(() => _isLoading = true);
      try {
          await supabase.from('transfer_talepleri').update({'durum': 'REDDEDİLDİ', 'cevap_miktar': 0}).eq('id', requestId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talep REDDEDİLDİ.'), backgroundColor: dangerColor));
          _fetchPendingRequests();
      } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reddetme Hatası: $e'), backgroundColor: dangerColor));
      } finally {
          if (mounted) {
              setState(() => _isLoading = false);
          }
      }
  }
  
  // Kısmen Onaylama Dialogu (Depolar ekranı stiline uyarlandı)
  void _showPartialApprovalDialog(int requestId, int talepEdenDepoId, int urunId, double requestedAmount, String birim) {
    final TextEditingController amountController = TextEditingController(text: requestedAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: warningColor),
              SizedBox(width: 10),
              Text('Kısmen Onayla', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
            ],
          ),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, color: darkTextColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Onaylanan Miktar',
              labelStyle: const TextStyle(color: darkTextColor),
              suffixText: birim,
              hintText: 'Maksimum ${requestedAmount.toStringAsFixed(2)}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: warningColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Onayı Gerçekleştir'),
              onPressed: () {
                final approvedAmount = double.tryParse(amountController.text);
                if (approvedAmount != null && approvedAmount <= requestedAmount && approvedAmount > 0) { 
                  Navigator.of(context).pop();
                  _processRequest(requestId, talepEdenDepoId, urunId, requestedAmount, approvedAmount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir miktar girin (0 ile talep edilen miktar arasında).')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  // Talebi gösteren Card Widget'ı (Depolar ekranı stiline uyarlandı)
  Widget _buildRequestCard(Map<String, dynamic> request) {
    // İlişkisel veriler
    final talepEdenDepoData = request['talep_eden_depo_id'] as Map?;
    final urunData = request['urun_id'] as Map?;

    final barName = talepEdenDepoData?['depo_adi'] ?? 'Bilinmeyen Bar';
    final productName = urunData?['urun_adi'] ?? 'Bilinmeyen Ürün';
    final productBirim = urunData?['birim'] ?? 'Adet';

    // ID'lerin güvenli çekilmesi
    final talepEdenDepoId = talepEdenDepoData?['id'] as int? ?? 0;
    final urunId = urunData?['id'] as int? ?? 0;
    
    final requestedAmount = (request['talep_edilen_miktar'] as num).toDouble();
    final requestId = request['id'] as int;

    // Eğer ID'ler hatalı çekildiyse kartı gizle/atla
    if (talepEdenDepoId == 0 || urunId == 0) return const SizedBox.shrink();

    return Card(
      elevation: 3, // Daha az belirgin gölge
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Depolar ekranı ile aynı köşe
        side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.0), // Daha hafif çerçeve
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Başlık Bölümü (Talep Eden ve Tarih)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      barName, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)
                    ),
                  ],
                ),
                Text(
                  request['talep_tarihi'] != null ? 
                  (request['talep_tarihi'] as String).substring(0, 10) : // Tarih formatlama
                  '', 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.grey), // Açık temaya uygun ayırıcı
            
            // 2. Ürün ve Miktar Detayları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: darkTextColor, size: 24),
                    const SizedBox(width: 10),
                    Text(productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextColor)),
                  ],
                ),
                Text(
                  '${requestedAmount.toStringAsFixed(2)} $productBirim', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor)
                ),
              ],
            ),

            const SizedBox(height: 15),
            
            // 3. Aksiyon Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // REDDET
                TextButton.icon(
                  onPressed: () => _rejectRequest(requestId),
                  icon: const Icon(Icons.close, color: dangerColor),
                  label: const Text('REDDET', style: TextStyle(color: dangerColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 5),
                // KISMİ ONAY
                TextButton.icon(
                  onPressed: () => _showPartialApprovalDialog(requestId, talepEdenDepoId, urunId, requestedAmount, productBirim),
                  icon: const Icon(Icons.edit_note, color: warningColor),
                  label: const Text('KISMİ', style: TextStyle(color: warningColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                // TAM ONAY
                ElevatedButton.icon(
                  onPressed: () => _processRequest(requestId, talepEdenDepoId, urunId, requestedAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('ONAYLA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground, // Depolar ekranı ile aynı arka plan
      appBar: AppBar(
        title: const Text('Transfer Talepleri Onayı', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        backgroundColor: cardColor, // AppBar'ı beyaz yaptık
        foregroundColor: darkTextColor, // İkon ve metin rengi
        elevation: 0.5, // Hafif gölge
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _pendingRequests,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Veri çekilirken hata oluştu: ${snapshot.error}', style: const TextStyle(color: dangerColor, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              final requests = snapshot.data;
              
              if (requests == null || requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('Bekleyen transfer talebi bulunmamaktadır.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _fetchPendingRequests, 
                        icon: const Icon(Icons.refresh, color: primaryColor), 
                        label: const Text('Listeyi Yenile', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600))
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: _fetchPendingRequests,
                color: primaryColor,
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
          // Yükleniyor durumu (Depolar ekranı ile aynı stile uyarlandı)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1), // Daha açık bir overlay
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}