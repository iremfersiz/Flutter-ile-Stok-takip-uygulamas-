import 'package:flutter/material.dart';
import '../../main.dart'; // supabase nesnesi burada tanımlı olmalı

class SayimDuzenleScreen extends StatefulWidget {
  final int sayimKayitId;
  final String urunAdi;
  final String depoAdi;
  final double mevcutSayim;
  final String birim;

  const SayimDuzenleScreen({
    super.key,
    required this.sayimKayitId,
    required this.urunAdi,
    required this.depoAdi,
    required this.mevcutSayim,
    required this.birim,
  });

  @override
  State<SayimDuzenleScreen> createState() => _SayimDuzenleScreenState();
}

class _SayimDuzenleScreenState extends State<SayimDuzenleScreen> {
  // Orijinal Aydınlık Tema Renkleri
  static const Color primaryColor = Colors.blue;
  static const Color screenBackground = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color darkTextColor = Colors.black; // Yazılar artık net siyah
  static const Color dangerColor = Colors.red;

  final TextEditingController _sayimController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sayimController.text = widget.mevcutSayim.toString();
  }

  @override
  void dispose() {
    _sayimController.dispose();
    super.dispose();
  }

  // --- CL TOPLAMA DİALOĞU (SİYAH YAZI GARANTİLİ) ---
  void _showQuickCalculateDialog() {
    List<double> entries = [];
    TextEditingController subController = TextEditingController();
    const double varsayilanHacim = 70.0; // Genelde 70cl

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalCl = entries.fold(0, (sum, item) => sum + item);
          double totalUnit = totalCl / varsayilanHacim;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hızlı cl Toplama', 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entries.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: entries.map((e) => Chip(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      label: Text('$e cl', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      onDeleted: () => setDialogState(() => entries.remove(e)),
                    )).toList(),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: subController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Yazı Siyah
                  decoration: InputDecoration(
                    labelText: 'cl Miktarı Gir ve Enter',
                    labelStyle: const TextStyle(color: Colors.grey),
                    suffixText: 'cl',
                    filled: true,
                    fillColor: screenBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) {
                    if (double.tryParse(val) != null) {
                      setDialogState(() {
                        entries.add(double.parse(val));
                        subController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sonuç:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      Text('${totalUnit.toStringAsFixed(2)} ${widget.birim}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  _sayimController.text = totalUnit.toStringAsFixed(2);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Aktar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guncelle() async {
    final double? yeniMiktar = double.tryParse(_sayimController.text);
    if (yeniMiktar == null) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('sayim_kayitlari').update({
        'sayilan_miktar': yeniMiktar,
      }).eq('id', widget.sayimKayitId);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: dangerColor));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('SAYIM DÜZENLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: cardColor,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: cardColor,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: primaryColor.withOpacity(0.1), width: 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _bilgiSatiri(Icons.inventory_2_outlined, 'Ürün:', widget.urunAdi),
                          const SizedBox(height: 12),
                          _bilgiSatiri(Icons.storefront_outlined, 'Depo:', widget.depoAdi),
                          const Divider(height: 40),
                          const Text('GÜNCEL SAYIM MİKTARI',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.1)),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _sayimController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                                  decoration: InputDecoration(
                                    suffixText: widget.birim,
                                    suffixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    filled: true,
                                    fillColor: screenBackground,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filled(
                                onPressed: _showQuickCalculateDialog,
                                icon: const Icon(Icons.calculate_outlined),
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  foregroundColor: primaryColor,
                                  padding: const EdgeInsets.all(12)
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _guncelle,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('GÜNCELLEMEYİ KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _bilgiSatiri(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black))),
      ],
    );
  }
}