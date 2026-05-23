import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bar_sorumlusu_transfer_screen.dart';
import 'bar_stok_durumu_screen.dart';

class BarSorumlusuAnaMenu extends StatefulWidget {
  const BarSorumlusuAnaMenu({super.key});

  @override
  State<BarSorumlusuAnaMenu> createState() => _BarSorumlusuAnaMenuState();
}

class _BarSorumlusuAnaMenuState extends State<BarSorumlusuAnaMenu> {
  String _barAdi = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    _loadBarInfo();
  }

  Future<void> _loadBarInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _barAdi = prefs.getString('user_depot_name') ?? "Bar Sorumlusu";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(_barAdi.toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("BAR OPERASYONU", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 20),
            
            // 1. MEVCUT STOK KARTI (Büyük ve Geniş)
            _buildMenuCard(
              context,
              title: "MEVCUT STOK DURUMUM",
              subtitle: "Elinizdeki şişe ve ürün miktarları",
              icon: Icons.inventory_2,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BarStokDurumuScreen())),
            ),
            
            const SizedBox(height: 20),
            
            // 2. TRANSFER İŞLEMLERİ KARTI (Büyük ve Geniş)
            _buildMenuCard(
              context,
              title: "TRANSFER TALEPLERİ",
              subtitle: "Ana depodan mal isteyin veya takip edin",
              icon: Icons.transfer_within_a_station,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BarSorumlusuTransferScreen())),
            ),

            const Spacer(),
            
            // Bilgilendirme Kutusu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Eksik ürünlerinizi 'Transfer' bölümünden isteyebilirsiniz.",
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}