// lib/screens/bar_sorumlusu/bar_talep_olustur_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; 

class BarTalepOlusturTab extends StatefulWidget {
  const BarTalepOlusturTab({super.key});

  @override
  State<BarTalepOlusturTab> createState() => _BarTalepOlusturTabState();
}

class _BarTalepOlusturTabState extends State<BarTalepOlusturTab> {
  // Form Controller'ları ve Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  // Supabase'den çekilen veriler
  List<Map<String, dynamic>> _barDepolari = [];
  List<Map<String, dynamic>> _urunler = [];

  // Seçilen değerler
  int? _selectedBarId;
  int? _selectedProductId;
  String? _selectedProductBirim;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Veri çekme mantığı (Değişmedi)
  Future<void> _fetchInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userDepotId = prefs.getInt('user_depot_id');

    try {
      var query = supabase
          .from('depolar')
          .select('id, depo_adi')
          .eq('tur', 'BAR');

      if (userDepotId != null) {
        query = query.eq('id', userDepotId);
      }

      final barResponse = await query;

      final productResponse = await supabase
          .from('urunler')
          .select('id, urun_adi, birim')
          .order('urun_adi', ascending: true);

      setState(() {
        _barDepolari = barResponse;
        _urunler = productResponse;
        _isLoading = false;

        if (_barDepolari.length == 1 && _selectedBarId == null) {
          _selectedBarId = _barDepolari.first['id'] as int;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri çekme hatası: ${e.toString()}')),
        );
      }
    }
  }

  bool get _isFormValid {
    return _selectedBarId != null &&
        _selectedProductId != null &&
        _quantityController.text.isNotEmpty &&
        (double.tryParse(_quantityController.text) ?? 0) > 0;
  }

  // Talep gönderme mantığı (Değişmedi)
  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final BuildContext currentContext = context;
    final double quantity = double.tryParse(_quantityController.text) ?? 0;

    setState(() => _isLoading = true);

    try {
      final mainDepo = await supabase.from('depolar').select('id').eq('tur', 'ANA').maybeSingle();
      final mainDepoId = mainDepo?['id'] as int?;

      if (mainDepoId == null) {
        throw Exception("Ana Depo Tanımlı Değil.");
      }

      final stockRecord = await supabase.from('stoklar')
          .select('adet')
          .eq('depo_id', mainDepoId)
          .eq('urun_id', _selectedProductId!)
          .maybeSingle();

      final double availableStock = (stockRecord?['adet'] as num?)?.toDouble() ?? 0.0;

      if (quantity > availableStock) {
        if (mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text(
                  'HATA: İstenen miktar (${quantity.toStringAsFixed(2)}) Ana Depo stoğunda (${availableStock.toStringAsFixed(2)}) mevcut değil. Mevcut stok: ${availableStock.toStringAsFixed(2)}.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
              ),
            );
        }
        return;
      }

      await supabase.from('transfer_talepleri').insert({
        'talep_eden_depo_id': _selectedBarId,
        'urun_id': _selectedProductId,
        'talep_edilen_miktar': quantity,
        'durum': 'BEKLEMEDE',
      });

      if (mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
                content: Text('✅ ${quantity.toString()} ${_selectedProductBirim ?? "Adet"} için talep başarıyla gönderildi.'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 3)),
          );

          setState(() {
            _selectedProductId = null;
            _quantityController.clear();
            _selectedProductBirim = null;
            if (_barDepolari.length > 1) {
              _selectedBarId = null;
            }
          });

          Future.microtask(() {
            try {
              final tabController = DefaultTabController.of(currentContext);
              // ignore: unnecessary_null_comparison
              if (tabController != null && tabController.length > 1) {
                tabController.animateTo(1);
              }
            } catch (e) {
              // Hata durumunda uygulama çökmez.
            }
          });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('❌ Talep gönderme hatası: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF9800);
    const Color textColor = Color(0xFF333333); // Koyu gri metin rengi

    const OutlineInputBorder focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: primaryColor, width: 2.0),
    );

    const OutlineInputBorder defaultBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    );


    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : Theme(
          // Dropdown menüsünün arka plan rengini düzeltmek için canvasColor'ı ayarla
          data: Theme.of(context).copyWith(
            primaryColor: primaryColor,
            canvasColor: Colors.white, // BURASI DROPDOWN MENÜSÜNÜN ARKA PLANINI BEYAZ YAPAR
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.orange
            ).copyWith(secondary: primaryColor),
            inputDecorationTheme: InputDecorationTheme(
              border: defaultBorderStyle,
              enabledBorder: defaultBorderStyle,
              focusedBorder: focusedBorderStyle,
              labelStyle: const TextStyle(color: textColor),
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
              errorStyle: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              titleMedium: TextStyle(color: textColor),
              bodyLarge: TextStyle(color: textColor),
              bodyMedium: TextStyle(color: textColor),
            ),
          ),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                onChanged: () {
                  setState(() {});
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text('Depodan Ürün Transferi Talebi',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 20.0),
                      child: Divider(height: 1, thickness: 2, color: primaryColor),
                    ),

                    // Bar Seçimi
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                          labelText: 'Talep Eden Bar',
                          prefixIcon: Icon(Icons.store, color: primaryColor)),
                      value: _selectedBarId,
                      hint: const Text('Hangi Bar için istiyorsunuz?'),
                      onChanged: (_barDepolari.length > 1)
                          ? (int? newValue) {
                              setState(() {
                                _selectedBarId = newValue;
                              });
                            }
                          : null,
                      items: _barDepolari
                          .map<DropdownMenuItem<int>>((Map<String, dynamic> bar) {
                        return DropdownMenuItem<int>(
                          value: bar['id'] as int,
                          child: Text(bar['depo_adi'] as String, style: const TextStyle(color: textColor)),
                        );
                      }).toList(),
                      validator: (value) => value == null ? 'Lütfen bir bar seçin.' : null,
                      iconDisabledColor: Colors.grey,
                    ),
                    const SizedBox(height: 20),

                    // Ürün Seçimi
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                          labelText: 'Ürün Seçimi',
                          prefixIcon: Icon(Icons.liquor, color: primaryColor)),
                      value: _selectedProductId,
                      hint: const Text('İstediğiniz ürünü seçin'),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedProductId = newValue;
                          final selectedProduct = _urunler.firstWhere(
                              (element) => element['id'] == newValue,
                              orElse: () => {'birim': ''});
                          _selectedProductBirim = selectedProduct['birim'] as String?;
                        });
                      },
                      items: _urunler
                          .map<DropdownMenuItem<int>>((Map<String, dynamic> product) {
                        return DropdownMenuItem<int>(
                            value: product['id'] as int,
                            // Açılan menü içindeki metinler
                            child: Text('${product['urun_adi']} (${product['birim']})', style: const TextStyle(color: textColor)));
                      }).toList(),
                      validator: (value) => value == null ? 'Lütfen bir ürün seçin.' : null,
                    ),
                    const SizedBox(height: 20),

                    // Miktar Girişi
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: const TextStyle(color: textColor),
                      decoration: InputDecoration(
                          labelText: 'İstenen Miktar',
                          suffixText: _selectedProductBirim ?? 'Adet',
                          suffixStyle: const TextStyle(color: textColor),
                          prefixIcon: const Icon(Icons.numbers, color: primaryColor)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Miktar girmek zorunludur.';
                        }
                        final double? quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Miktar pozitif bir sayı olmalıdır.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // Talep Gönder Butonu
                    ElevatedButton(
                      onPressed: (_isLoading || !_isFormValid) ? null : _sendRequest,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : const Text('Talebi Gönder',
                              style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        );
  }
}