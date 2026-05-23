// lib/screens/cost_control/depolar_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart'; // supabase'in burada tanımlı olduğunu varsayıyorum

class DepolarScreen extends StatefulWidget {
  const DepolarScreen({super.key});

  @override
  State<DepolarScreen> createState() => _DepolarScreenState();
}

// Ana veri yapısı: Depo Adı -> Ürün Adı -> Stok Adedi
typedef DepotStockData = Map<String, Map<String, double>>;

class _DepolarScreenState extends State<DepolarScreen> {
  Future<DepotStockData>? _depotStockFuture;
  
  Map<String, double> _totalStock = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Renk Paleti Tanımları
  static const Color primaryColor = Colors.blue; 
  static const Color cardColor = Colors.white; 
  static const Color screenBackground = Color(0xFFF5F5F5); 
  static const Color lowStockColor = Colors.redAccent;
  static const Color highStockColor = Colors.green;
  static const Color darkTextColor = Colors.black87; 
  static const Color lightBlueBackground = Color.fromARGB(255, 173, 180, 245); 

  @override
  void initState() {
    super.initState();
    _depotStockFuture = _fetchDepotStocks();
    _searchController.addListener(_updateSearchText);
  }

  void _updateSearchText() {
    final currentText = _searchController.text.toLowerCase();
    if (_searchText != currentText) {
      setState(() {
        _searchText = currentText;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchText);
    _searchController.dispose();
    super.dispose();
  }

  // Hata Yönetimi Geliştirilmiş Supabase Veri Çekme Mantığı
  Future<DepotStockData> _fetchDepotStocks() async {
    try {
      // 1. Depoları Çek
      final List<Map<String, dynamic>> depots = await supabase
          .from('depolar')
          .select('id, depo_adi, tur');
      
      // 2. Tüm Ürünleri Çek ve Map Oluştur
      final List<Map<String, dynamic>> allProducts = await supabase
          .from('urunler')
          .select('id, urun_adi, birim');
      
      final Map<int, String> productMap = {
        for (var p in allProducts) p['id'] as int: '${p['urun_adi']} (${p['birim']})'
      };

      // 3. Tüm Stok Kayıtlarını Çek
      // 💥 KRİTİK DÜZELTME: 'depo_stok' yerine 'stoklar' tablosu kullanıldı.
      final List<Map<String, dynamic>> allStocks = await supabase
          .from('stoklar') 
          .select('depo_id, urun_id, adet'); // Tablo adı 'stoklar' ve miktar sütunu 'adet' olmalı.

      DepotStockData depotData = {};
      Map<String, double> runningTotal = {};

      for (var depot in depots) {
        final depotId = depot['id'] as int;
        final depotName = depot['depo_adi'] as String;
        
        depotData[depotName] = {};

        final currentDepotStocks = allStocks.where((s) => s['depo_id'] == depotId);

        for (var stock in currentDepotStocks) {
          final productId = stock['urun_id'] as int;
          // Güvenli tip dönüştürme ve null kontrolü (Sütun adı 'miktar' yerine 'adet' olarak düzeltildi)
          final quantity = (stock['adet'] as num?)?.toDouble() ?? 0.0;
          
          if (quantity <= 0) continue; 

          final productName = productMap[productId] ?? 'Bilinmeyen Ürün (ID: $productId)';

          depotData[depotName]![productName] = quantity;
          runningTotal[productName] = (runningTotal[productName] ?? 0) + quantity;
        }
      }
      
      if (!mounted) return {};
      setState(() {
        _totalStock = runningTotal;
      });

      return depotData;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'KRİTİK HATA: Veri çekilemedi. Bağlantıyı, Tablo Adlarını ve RLS (izinleri) kontrol edin. Hata Detayı: ${e.toString()}',
              maxLines: 3,
            ), 
            backgroundColor: lowStockColor,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      rethrow; 
    }
  }
  
  // Toplam Stok Kartını oluşturur
  Widget _buildTotalStockCard(BuildContext context) {
    if (_totalStock.isEmpty) return const SizedBox.shrink();

    final sortedTotalStock = _totalStock.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); 
    
    final filteredStock = sortedTotalStock
        .where((entry) => entry.key.toLowerCase().contains(_searchText) && entry.value > 0)
        .toList();

    if (filteredStock.isEmpty) return const SizedBox.shrink(); 

    return Card(
      elevation: 4,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.analytics_outlined, color: primaryColor, size: 30),
        title: const Text(
          'GENEL TOPLAM STOK', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
        ),
        initiallyExpanded: _searchText.isNotEmpty,
        children: filteredStock.map((entry) {
          final isLow = entry.value < 5; 
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14, color: darkTextColor))), 
                Text(
                  entry.value.toStringAsFixed(2), 
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 15,
                    color: isLow ? lowStockColor : highStockColor,
                  )
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Depo bazında detaylı stok kartını oluşturur
  Widget _buildDepotDetail(String depotName, Map<String, double> stockDetails) {
    final sortedStockDetails = stockDetails.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    final filteredStockDetails = sortedStockDetails
        .where((entry) => entry.key.toLowerCase().contains(_searchText) && entry.value > 0)
        .toList();

    final isEmpty = stockDetails.isEmpty || filteredStockDetails.isEmpty;
    final totalDepotQuantity = stockDetails.values.fold(0.0, (sum, item) => sum + item);

    return Card(
      elevation: 1,
      color: cardColor, 
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: isEmpty && stockDetails.isEmpty 
          ? ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              title: Text(depotName, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)), 
              subtitle: const Text(
                'Depoda henüz kayıtlı stok yok.',
                style: TextStyle(color: Colors.grey), 
              ),
            )
          : ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.warehouse_outlined, color: primaryColor, size: 28),
              title: Text(
                depotName, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTextColor)
              ), 
              trailing: isEmpty ? 
                const Icon(Icons.search_off, color: Colors.grey) : 
                Text(
                  'Toplam: ${totalDepotQuantity.toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)
                ),
              initiallyExpanded: filteredStockDetails.isNotEmpty && _searchText.isNotEmpty,
              children: isEmpty ? [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text('Aradığınız ürün bu depoda bulunamadı.', style: TextStyle(color: Colors.grey)),
                )
              ] : filteredStockDetails.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14, color: darkTextColor))), 
                      Text(
                        entry.value.toStringAsFixed(2), 
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: darkTextColor) 
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // Arama Çubuğu
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: darkTextColor), 
        decoration: InputDecoration(
          hintText: 'Ürün veya birim ara...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchText.isNotEmpty ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
            },
          ) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: lightBlueBackground.withOpacity(0.1), 
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          enabledBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: primaryColor, width: 2.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground, 
      appBar: AppBar(
        title: const Text('DEPO STOK ENVANTERİ', style: TextStyle(fontWeight: FontWeight.w600, color: darkTextColor)),
        centerTitle: true,
        backgroundColor: cardColor, 
        elevation: 0.5, 
        foregroundColor: darkTextColor,
      ),
      body: FutureBuilder<DepotStockData>(
        future: _depotStockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off, color: lowStockColor, size: 40),
                    const SizedBox(height: 10),
                    // Hata ayıklama ipuçlarını içeren detaylı hata mesajı
                    const Text(
                      'Veri yüklenirken kritik bir hata oluştu. Lütfen şunları kontrol edin:', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)
                    ), 
                    const Text(
                      '1. Supabase bağlantı ayarlarınız (URL/Key)\n2. Veritabanındaki tablo adlarınızın (depolar, urunler, stoklar) doğru yazımı\n3. Supabase RLS (Satır Düzeyinde Güvenlik) izinleri.', 
                      textAlign: TextAlign.start, 
                      style: TextStyle(color: darkTextColor, fontSize: 13)
                    ), 
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          // Hata durumunda yeniden denemek için future'ı sıfırla
                          _depotStockFuture = _fetchDepotStocks();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yeniden Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, 
                        foregroundColor: Colors.white, 
                      ),
                    )
                  ],
                ),
              ),
            );
          }
          
          final depotData = snapshot.data ?? {};

          // Genel Boş Durum Kontrolü
          if (depotData.isEmpty && _totalStock.isEmpty) {
             return RefreshIndicator(
                onRefresh: () async { _depotStockFuture = _fetchDepotStocks(); await _depotStockFuture; },
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 50),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                          SizedBox(height: 10),
                          Text('Kayıtlı hiçbir depo veya stok bulunamadı.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
            );
          }


          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              _depotStockFuture = _fetchDepotStocks();
              await _depotStockFuture; 
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Arama Çubuğu
                _buildSearchBar(),

                // 1. Toplam Stok Kartı
                _buildTotalStockCard(context),
                
                const Divider(height: 30, thickness: 0.5, color: Colors.black12),
                
                // 2. Depo Bazında Detaylar Başlığı
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
                  child: Text(
                    'Depo Envanteri Detayları', 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: darkTextColor 
                    )
                  ),
                ),
                
                // Depoları, veritabanından geldikleri sıra ile göster (SIRALAMA İPTAL EDİLDİ)
                ...depotData.keys.toList()
                    .map((depotName) {
                      return _buildDepotDetail(depotName, depotData[depotName]!);
                    }).toList(),
                
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}