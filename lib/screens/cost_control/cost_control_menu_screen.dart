// lib/screens/cost_control/cost_control_menu_screen.dart

import 'package:flutter/material.dart';
import 'sayim_screen.dart';
import 'fiyatlandirma_screen.dart';
import 'transfer_onay_screen.dart';
import 'depolar_screen.dart';
import 'rapor_screen.dart';
import 'grafik_screen.dart';
import 'kisi_basi_maliyet_screen.dart'; // <<< YENİ IMPORT
import 'alim_gecmisi_screen.dart';
import 'eksik_listesi_screen.dart';

// --- Yardımcı Metotlar ---

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

// Menü Veri Yapısı (Değişmedi)
class MenuItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget screen;
  final bool isSpecial;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.screen,
    this.isSpecial = false,
  });
}

// --- ANA WIDGET ---

class CostControlMenuScreen extends StatelessWidget {
  const CostControlMenuScreen({super.key});

  final List<MenuItem> _menuItems = const [
    MenuItem(
      title: 'STOK SAYIM',
      icon: Icons.qr_code_scanner,
      iconColor: Color(0xFFE53935), // Kırmızı
      screen: SayimScreen(),
    ),
    MenuItem(
      title: 'FİYAT GÜNCELLEME',
      icon: Icons.price_change_outlined,
      iconColor: Color(0xFFFB8C00), // Koyu Turuncu
      screen: FiyatlandirmaScreen(),
    ),
    MenuItem(
      title: 'KİŞİ BAŞI MALİYET', // <<< YENİ MENÜ ÖĞESİ
      icon: Icons.group_outlined,
      iconColor: Color(0xFF00ACC1), // Çiçek Mavisi
      screen: KisiBasiMaliyetScreen(),
    ),
    MenuItem(
      title: 'RAPOR ANALİZ',
      icon: Icons.analytics_outlined,
      iconColor: Color(0xFF1E88E5), // Mavi
      screen: RaporScreen(),
    ),
    MenuItem(
      title: 'PERFORMANS GRAFİK',
      icon: Icons.show_chart,
      iconColor: Color(0xFF43A047), // Yeşil
      screen: GrafikScreen(),
    ),
    MenuItem(
      title: 'TRANSFER YÖNETİMİ',
      icon: Icons.swap_horiz,
      iconColor: Color(0xFF8E24AA), // Mor
      screen: TransferOnayScreen(),
    ),
    MenuItem(
      title: 'DEPO ENVANTER',
      icon: Icons.location_city_outlined,
      iconColor: Color(0xFF6D4C41), // Kahverengi
      screen: DepolarScreen(),
    ),
    MenuItem(
      title: 'ALIM GEÇMİŞİ',
      icon: Icons.shop,
      iconColor: Color.fromARGB(255, 255, 63, 207), // Kahverengi
      screen: AlimGecmisiScreen(),
    ),
    MenuItem(
      title: 'EKSİK LİSTESİ',
      icon: Icons.analytics_outlined,
      iconColor: Color.fromARGB(255, 238, 222, 0), // Mavi
      screen: EksikListesiScreen(),
    ),
  ];

  // ULTRA MODERN MENÜ BUTONU (Minimalist, Derinlikli) - Değişmedi
  Widget _buildUltraModernMenuButton(
    BuildContext context,
    MenuItem item,
  ) {
    if (item.isSpecial) {
      return InkWell(
        onTap: () => _showSnackbar(context, 'Çıkış işlemi başlatıldı...'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(item.icon, size: 36, color: Colors.black54),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Modern Tasarım: Temiz Card yapısı
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => item.screen));
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Beyaz arka plan
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            // Hafif bir üst gölge (light source simulation)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
            // Belirgin bir alt gölge (derinlik)
            BoxShadow(
              color: item.iconColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                item.icon,
                size: 44, // İkon daha da büyütüldü
                color: item.iconColor,
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: item.iconColor.withOpacity(0.9), // İkon rengiyle uyumlu yazı rengi
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BUILD METODU GÜNCELLENDİ (RESPONSIVE İÇİN) ---
  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini alıyoruz
    final double screenWidth = MediaQuery.of(context).size.width;

    // Minimum bir buton genişliği belirliyoruz (örneğin 120.0)
    const double minItemWidth = 120.0;
    
    // Grid aralığı (spacing)
    const double spacing = 10.0;
    
    // Toplam Padding (16 sağ + 16 sol = 32)
    const double totalPadding = 32.0;

    // Kullanılabilir genişlik: Ekran Genişliği - Toplam Padding
    final double availableWidth = screenWidth - totalPadding;

    // Sütun sayısını hesapla: (Kullanılabilir Genişlik + Aralanma) / (Minimum Öğe Genişliği + Aralanma)
    // Bu, aralanmayı da hesaba katarak kaç tane minimum genişlikte öğenin sığabileceğini bulur.
    int crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor();
    
    // Sütun sayısını en az 2 ve en fazla 6 ile sınırla (Mobil'de 2, Büyük Ekranlarda Max 6)
    if (crossAxisCount < 2) {
      crossAxisCount = 2;
    } else if (crossAxisCount > 6) {
      crossAxisCount = 6;
    }

    // Menü öğelerine ÇIKIŞ öğesini ekle
    List<MenuItem> allItems = [
      ..._menuItems,
      const MenuItem(
        title: 'ÇIKIŞ',
        icon: Icons.power_settings_new_outlined,
        iconColor: Colors.black54,
        screen: Placeholder(),
        isSpecial: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MALİYET KONTROL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4511E), // Koyu, Kurumsal Turuncu
        elevation: 0,
        centerTitle: true,
      ),
      // Arka plan rengi, Neumorphism hissiyatını desteklemek için hafif bir ton
      backgroundColor: const Color(0xFFF5F5F5), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // DİNAMİK OLARAK HESAPLANAN SÜTUN SAYISI KULLANILDI
            crossAxisCount: crossAxisCount, 
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.1, // Kareye yakın
          ),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            return _buildUltraModernMenuButton(context, allItems[index]);
          },
        ),
      ),
    );
  }
}