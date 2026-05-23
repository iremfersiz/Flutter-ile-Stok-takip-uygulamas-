// lib/screens/bar_sorumlusu/bar_sorumlusu_transfer_screen.dart

import 'package:flutter/material.dart';
// ignore: unused_import
import '../../main.dart';
import 'bar_talep_olustur_tab.dart';
import 'bar_talep_takip_tab.dart'; 

class BarSorumlusuTransferScreen extends StatelessWidget {
  const BarSorumlusuTransferScreen({super.key});

  // Tema sabitleri
  static const Color primaryColor = Colors.blue; // Ana vurgu rengi
  static const Color cardColor = Colors.white; // AppBar arka plan rengi
  static const Color darkTextColor = Colors.black87; // Genel koyu metin rengi

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: cardColor, // Arka planı beyaz yap
        appBar: AppBar(
          title: const Text('Transfer Yönetimi',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: darkTextColor)),
          backgroundColor: cardColor, // AppBar'ı beyaz yaptık
          foregroundColor: darkTextColor, // İkon ve metin rengi
          elevation: 0.5, // Hafif gölge
          centerTitle: true,
          bottom: const TabBar(
            // Vurgu rengini primaryColor (mavi) yap
            indicatorColor: primaryColor,
            labelColor: primaryColor, // Seçili sekme metni mavi
            unselectedLabelColor: Colors.black54, // Seçili olmayan metin koyu gri
            tabs: [
              Tab(icon: Icon(Icons.add_shopping_cart), text: 'Talep Oluştur'),
              Tab(icon: Icon(Icons.list_alt), text: 'Taleplerim'),
            ],
          ),
        ),
        // ÇÖZÜM: Builder ile context'i yeniliyoruz
        body: Builder(
          builder: (BuildContext innerContext) {
            return const TabBarView(
              children: [
                BarTalepOlusturTab(), 
                BarTalepTakipTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}