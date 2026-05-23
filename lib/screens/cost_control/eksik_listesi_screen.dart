import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Panoya kopyalama için eklendi
import '../../main.dart';

class EksikListesiScreen extends StatefulWidget {
  const EksikListesiScreen({super.key});

  @override
  State<EksikListesiScreen> createState() => _EksikListesiScreenState();
}

class _EksikListesiScreenState extends State<EksikListesiScreen> {
  static const Color primaryColor = Colors.blue;
  static const Color warningRed = Color(0xFFFF3B30);
  
  List<Map<String, dynamic>> _eksikler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEksikler();
  }

  Future<void> _fetchEksikler() async {
    setState(() => _isLoading = true);
    try {
      final depoRes = await supabase.from('depolar').select('id').eq('tur', 'ANA').maybeSingle();
      if (depoRes == null) {
        setState(() => _isLoading = false);
        return;
      }
      final int anaDepoId = depoRes['id'];

      final response = await supabase
          .from('stoklar')
          .select('adet, urun_id:urunler!inner(id, urun_adi, kritik_limit, birim)')
          .eq('depo_id', anaDepoId)
          .not('urunler.kritik_limit', 'is', null);

      final List<Map<String, dynamic>> allData = List<Map<String, dynamic>>.from(response);

      final List<Map<String, dynamic>> filteredList = allData.where((item) {
        final double mevcutAdet = (item['adet'] as num).toDouble();
        final double limit = (item['urun_id']['kritik_limit'] as num).toDouble();
        return mevcutAdet <= limit;
      }).toList();

      setState(() {
        _eksikler = filteredList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Eksik listesi hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  // Listeyi metin olarak kopyalama fonksiyonu
  void _copyOrderList() {
    if (_eksikler.isEmpty) return;

    String orderText = "*EKSİK SİPARİŞ LİSTESİ*\n";
    orderText += "Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}\n\n";

    for (var item in _eksikler) {
      final urun = item['urun_id'];
      orderText += "- ${urun['urun_adi']} (Mevcut: ${item['adet']} ${urun['birim']})\n";
    }

    Clipboard.setData(ClipboardData(text: orderText)).then((_) {
      _showSnackbar("Sipariş listesi panoya kopyalandı! WhatsApp'a yapıştırabilirsiniz.", Colors.green);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('KRİTİK EKSİK LİSTESİ', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- GERİ OKUNU VE İKONLARI SİYAH YAPAR ---
        foregroundColor: Colors.black, 
        // ------------------------------------------
        actions: [
          if (_eksikler.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined, color: primaryColor),
              onPressed: _copyOrderList,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEksikler,
              child: _eksikler.isEmpty ? _buildEmptyState() : _buildList(),
            ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eksikler.length,
      itemBuilder: (context, index) {
        final item = _eksikler[index];
        final urun = item['urun_id'];
        final double stok = (item['adet'] as num).toDouble();
        final double limit = (urun['kritik_limit'] as num).toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, color: warningRed.withOpacity(0.5), size: 35),
                const Icon(Icons.priority_high, color: warningRed, size: 18),
              ],
            ),
            title: Text(urun['urun_adi'], 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Mevcut Stok: $stok ${urun['birim']}", 
                  style: const TextStyle(color: warningRed, fontWeight: FontWeight.bold)),
                Text("Belirlenen Limit: $limit ${urun['birim']}", 
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            trailing: const Icon(Icons.add_shopping_cart, color: primaryColor),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text("HARİKA!", 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          const Text("Kritik seviyenin altında ürün bulunamadı.", 
            style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchEksikler, 
            child: const Text("Listeyi Yenile")
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2))
    );
  }
}