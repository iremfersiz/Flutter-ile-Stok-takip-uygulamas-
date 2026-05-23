import 'package:flutter/material.dart';
import '../../main.dart'; // supabase nesnesi burada tanımlı olmalı

class FiyatlandirmaScreen extends StatefulWidget {
  const FiyatlandirmaScreen({super.key});

  @override
  State<FiyatlandirmaScreen> createState() => _FiyatlandirmaScreenState();
}

class _FiyatlandirmaScreenState extends State<FiyatlandirmaScreen> {
  // Aydınlık Tema Renkleri
  static const Color primaryColor = Colors.blue;
  static const Color screenBackground = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color textBlack = Colors.black;

  // Kontrolörler
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();

  final List<double> _bottleVolumes = [10.0, 20.0, 35.0, 50.0, 70.0, 75.0, 100.0, 150.0, 200.0];
  double? _selectedVolume;
  int? _selectedProductId;
  List<Map<String, dynamic>> _productList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('urunler').select('id, urun_adi, birim, birim_fiyati, birim_hacim, kritik_limit');
      setState(() => _productList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showSnackbar('Liste çekilemedi: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProductTransaction() async {
    final String name = _nameController.text.trim();
    final double quantity = double.tryParse(_quantityController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double volume = _selectedVolume ?? 70.0;
    final double? kritikLimit = double.tryParse(_limitController.text);

    if (name.isEmpty || price <= 0) {
      _showSnackbar('Lütfen en azından Ürün Adı ve Fiyat girin.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      double clFiyati = price / volume;
      int productId;

      if (_selectedProductId == null) {
        final res = await supabase.from('urunler').insert({
          'urun_adi': name,
          'birim': 'Şişe',
          'birim_fiyati': price,
          'birim_hacim': volume,
          'cl_fiyati': clFiyati,
          'kritik_limit': kritikLimit,
        }).select('id').single();
        productId = res['id'];
      } else {
        productId = _selectedProductId!;
        await supabase.from('urunler').update({
          'birim_fiyati': price,
          'birim_hacim': volume,
          'cl_fiyati': clFiyati,
          'kritik_limit': kritikLimit,
        }).eq('id', productId);
      }

      if (quantity > 0) {
        await _updateMainStock(productId, quantity);
        
        await supabase.from('alislar').insert({
          'urun_id': productId,
          'miktar': quantity,
          'birim_fiyat': price,
          'toplam_tutar': quantity * price,
          'birim_hacim': volume,
          'tarih': DateTime.now().toIso8601String(),
        });

        _showSnackbar('Stok ve Alım Kaydı Tamam!', Colors.green);
      } else {
        _showSnackbar('Ürün Bilgileri Güncellendi.', Colors.green);
      }

      _clearForm();
      await _fetchProducts();
    } catch (e) {
      _showSnackbar('Hata: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMainStock(int productId, double quantity) async {
    final mainDepo = await supabase.from('depolar').select('id').eq('tur', 'ANA').maybeSingle();
    if (mainDepo == null) return;
    final int depoId = mainDepo['id'];

    final res = await supabase.from('stoklar').select('adet').eq('depo_id', depoId).eq('urun_id', productId).maybeSingle();
    double currentAdet = (res?['adet'] as num?)?.toDouble() ?? 0.0;

    if (res != null) {
      await supabase.from('stoklar').update({'adet': currentAdet + quantity}).eq('depo_id', depoId).eq('urun_id', productId);
    } else {
      await supabase.from('stoklar').insert({'depo_id': depoId, 'urun_id': productId, 'adet': quantity});
    }
  }

  void _onProductSelected(int? id) {
    if (id == null) { _clearForm(); return; }
    final p = _productList.firstWhere((e) => e['id'] == id);
    setState(() {
      _selectedProductId = id;
      _nameController.text = p['urun_adi'] ?? '';
      _priceController.text = (p['birim_fiyati'] ?? 0).toString();
      _selectedVolume = (p['birim_hacim'] as num?)?.toDouble();
      _limitController.text = p['kritik_limit']?.toString() ?? '';
    });
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _limitController.clear();
    setState(() { _selectedProductId = null; _selectedVolume = null; });
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('FİYATLANDIRMA & ALIM', 
          style: TextStyle(fontWeight: FontWeight.bold, color: textBlack)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- GERİ OKU VE İKONLAR SİYAH OLDU ---
        foregroundColor: Colors.black, 
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              child: DropdownButtonFormField<int?>(
                value: _selectedProductId,
                dropdownColor: Colors.white,
                style: const TextStyle(color: textBlack, fontWeight: FontWeight.bold, fontSize: 16),
                items: [
                  const DropdownMenuItem(value: null, child: Text("➕ Yeni Ürün Tanımla")),
                  ..._productList.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['urun_adi']))),
                ],
                onChanged: _onProductSelected,
                decoration: _inputDeco('Mevcut Ürünlerden Seçin', Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    readOnly: _selectedProductId != null,
                    style: const TextStyle(color: textBlack, fontWeight: FontWeight.bold),
                    decoration: _inputDeco('Ürün Adı', Icons.edit),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<double>(
                    value: _selectedVolume,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: textBlack, fontWeight: FontWeight.bold),
                    items: _bottleVolumes.map((v) => DropdownMenuItem(value: v, child: Text('$v cl'))).toList(),
                    onChanged: (val) => setState(() => _selectedVolume = val),
                    decoration: _inputDeco('Şişe Hacmi (cl)', Icons.liquor),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: textBlack, fontWeight: FontWeight.bold),
                          decoration: _inputDeco('Alım Adedi', Icons.add_shopping_cart),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: textBlack, fontWeight: FontWeight.bold),
                          decoration: _inputDeco('Şişe Fiyatı (TL)', Icons.payments),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    decoration: _inputDeco('Kritik Stok Limiti (Opsiyonel)', Icons.notifications_active_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProductTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('KAYDET VE STOK GÜNCELLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}