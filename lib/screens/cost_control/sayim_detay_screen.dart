import 'package:flutter/material.dart';
import '../../main.dart'; // supabase nesnesi burada tanımlı olmalı

class SayimDetayScreen extends StatefulWidget {
  final int depoId;
  final String depoAdi;

  const SayimDetayScreen({super.key, required this.depoId, required this.depoAdi});

  @override
  State<SayimDetayScreen> createState() => _SayimDetayScreenState();
}

class _SayimDetayScreenState extends State<SayimDetayScreen> {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color backgroundGrey = Color(0xFFF2F2F7);
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textLight = Color(0xFF8E8E93);

  Map<String, List<Map<String, dynamic>>> _groupedProducts = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCountingData();
  }

  Future<void> _fetchCountingData() async {
    try {
      final prods = await supabase.from('urunler').select('id, urun_adi, kategori, birim, birim_fiyati, birim_hacim');
      final stocks = await supabase.from('stoklar').select('urun_id, adet').eq('depo_id', widget.depoId);

      final Map<int, double> stockMap = {for (var s in stocks) s['urun_id']: (s['adet'] as num).toDouble()};
      final Map<String, List<Map<String, dynamic>>> tempGroup = {};

      for (var p in prods) {
        final cat = p['kategori'] ?? 'Diğer';
        p['teorik_adet'] = stockMap[p['id']] ?? 0.0;
        if (!tempGroup.containsKey(cat)) tempGroup[cat] = [];
        tempGroup[cat]!.add(p);
        _controllers[p['id']] = TextEditingController();
      }

      setState(() {
        _groupedProducts = tempGroup;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar("Veri çekme hatası: $e", Colors.red);
    }
  }

  Future<void> _saveCount() async {
    final List<Map<String, dynamic>> recordsToInsert = [];
    final now = DateTime.now().toIso8601String();

    _groupedProducts.forEach((category, products) {
      for (var product in products) {
        final productId = product['id'] as int;
        final theoretical = product['teorik_adet'] as double;
        final price = (product['birim_fiyati'] as num?)?.toDouble() ?? 0.0;
        final controller = _controllers[productId];

        if (controller == null || controller.text.isEmpty) continue;

        final countedValue = double.tryParse(controller.text) ?? theoretical;
        final difference = countedValue - theoretical;
        final cost = difference.abs() * price;

        recordsToInsert.add({
          'depo_id': widget.depoId,
          'urun_id': productId,
          'sayim_tarihi': now,
          'sayilan_miktar': countedValue,
          'teorik_miktar': theoretical,
          'fark_maliyeti': cost,
          'fark_miktar': difference,
        });
      }
    });

    if (recordsToInsert.isEmpty) {
      _showSnackbar('Henüz hiçbir sayım miktarı girmediniz.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('sayim_kayitlari').insert(recordsToInsert);

      for (var record in recordsToInsert) {
        await supabase.from('stoklar').upsert({
          'depo_id': record['depo_id'],
          'urun_id': record['urun_id'],
          'adet': record['sayilan_miktar'],
        }, onConflict: 'depo_id,urun_id');
      }

      _showSnackbar('Sayım başarıyla kaydedildi!', Colors.green);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Kaydetme hatası: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCalculator(Map<String, dynamic> p, TextEditingController ctrl) {
    List<double> clList = [];
    TextEditingController subCtrl = TextEditingController();
    double hacim = (p['birim_hacim'] as num?)?.toDouble() ?? 70.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          double totalCl = clList.fold(0, (a, b) => a + b);
          double result = totalCl / hacim;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(p['urun_adi'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Birim: ${hacim.toInt()}cl', style: const TextStyle(color: textLight)),
                const SizedBox(height: 10),
                if (clList.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: clList.map((e) => Chip(
                      label: Text('$e cl', style: const TextStyle(color: Colors.black)),
                      onDeleted: () => setS(() => clList.remove(e)),
                      backgroundColor: backgroundGrey,
                    )).toList(),
                  ),
                const SizedBox(height: 15),
                TextField(
                  controller: subCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'cl Gir ve Ekle',
                    labelStyle: const TextStyle(color: textLight),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(icon: const Icon(Icons.add_circle, color: primaryBlue), onPressed: () {
                      if (double.tryParse(subCtrl.text) != null) {
                        setS(() { clList.add(double.parse(subCtrl.text)); subCtrl.clear(); });
                      }
                    }),
                  ),
                ),
                const Divider(height: 30),
                Text('${result.toStringAsFixed(2)} Şişe', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryBlue)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: textLight))),
              ElevatedButton(
                onPressed: () { ctrl.text = result.toStringAsFixed(2); Navigator.pop(ctx); setState(() {}); },
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                child: const Text('Aktar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.depoAdi} Sayımı', 
          style: const TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- GERİ OKUNU SİYAH YAPAR ---
        foregroundColor: Colors.black, 
        // ------------------------------
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _groupedProducts.keys.length,
              itemBuilder: (context, index) {
                String cat = _groupedProducts.keys.elementAt(index);
                return _buildCategorySection(cat, _groupedProducts[cat]!);
              },
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
          child: Text(title.toUpperCase(), 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
        ),
        ...products.map((p) => _buildProductRow(p)).toList(),
      ],
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final ctrl = _controllers[p['id']]!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: backgroundGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['urun_adi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                Text('Teorik: ${p['teorik_adet']} ${p['birim']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: primaryBlue, size: 26), 
            onPressed: () => _showCalculator(p, ctrl)
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: backgroundGrey,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                hintText: '0.0',
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCount,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('SAYIMI KAYDET VE STOKLARI GÜNCELLE', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}