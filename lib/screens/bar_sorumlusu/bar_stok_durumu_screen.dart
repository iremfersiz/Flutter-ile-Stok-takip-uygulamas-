import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; 

class BarStokDurumuScreen extends StatefulWidget {
  const BarStokDurumuScreen({super.key});

  @override
  State<BarStokDurumuScreen> createState() => _BarStokDurumuScreenState();
}

class _BarStokDurumuScreenState extends State<BarStokDurumuScreen> {
  // Tema Sabitleri (Transfer ekranlarıyla uyumlu)
  static const Color primaryBlue = Colors.blue;
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color textDark = Colors.black87;
  static const Color textGrey = Colors.black54;

  List<Map<String, dynamic>> _stokListesi = [];
  bool _isLoading = true;
  String _depoAdi = "Bar";

  @override
  void initState() {
    super.initState();
    _fetchBarStocks();
  }

  Future<void> _fetchBarStocks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userDepotId = prefs.getInt('user_depot_id');
      final String? userDepotName = prefs.getString('user_depot_name');

      if (userDepotId == null) {
        throw Exception("Kullanıcıya atanmış depo bulunamadı.");
      }

      setState(() {
        _depoAdi = userDepotName ?? "Bar";
      });

      // Sadece barmene ait deponun stoklarını çek
      final response = await supabase
          .from('stoklar')
          .select('adet, urun_id:urunler!inner(id, urun_adi, birim, kategori, kritik_limit)')
          .eq('depo_id', userDepotId)
          .order('adet', ascending: false);

      setState(() {
        _stokListesi = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Stok çekme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('$_depoAdi STOK DURUMU', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: textDark, // Geri oku siyah
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _stokListesi.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchBarStocks,
                  color: primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stokListesi.length,
                    itemBuilder: (context, index) {
                      final item = _stokListesi[index];
                      final urun = item['urun_id'];
                      final double miktar = (item['adet'] as num).toDouble();
                      final double? limit = (urun['kritik_limit'] as num?)?.toDouble();
                      
                      // Stok kritik limitin altındaysa kırmızı vurgu yapalım
                      bool isCritical = limit != null && miktar <= limit;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: isCritical 
                            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)
                            : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCritical ? Colors.red.shade50 : primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCritical ? Icons.warning_amber_rounded : Icons.liquor, 
                              color: isCritical ? Colors.red : primaryBlue,
                            ),
                          ),
                          title: Text(urun['urun_adi'], 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16)),
                          subtitle: Text(urun['kategori'] ?? 'Genel', 
                            style: const TextStyle(color: textGrey, fontSize: 13)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(miktar.toStringAsFixed(2), 
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w900, 
                                  color: isCritical ? Colors.red : textDark
                                )),
                              Text(urun['birim'] ?? 'Adet', 
                                style: const TextStyle(fontSize: 11, color: textGrey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Bu barda henüz tanımlı stok yok.", 
            style: TextStyle(fontWeight: FontWeight.bold, color: textGrey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchBarStocks,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Listeyi Yenile", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
          ),
        ],
      ),
    );
  }
}