// lib/screens/cost_control/bar_olustur_dialog.dart

import 'package:flutter/material.dart';
import '../../main.dart'; // Göreceli yol düzeltildi

class BarOlusturDialog extends StatefulWidget {
  final VoidCallback onBarCreated;
  const BarOlusturDialog({super.key, required this.onBarCreated});

  @override
  State<BarOlusturDialog> createState() => _BarOlusturDialogState();
}

class _BarOlusturDialogState extends State<BarOlusturDialog> {
  // Tema sabitleri
  static const Color primaryColor = Colors.blue;
  static const Color darkTextColor = Colors.black87;
  static const Color cardColor = Colors.white; // Diyalog arka planı

  final TextEditingController _barNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createBar() async {
    final barName = _barNameController.text.trim();
    if (barName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bar adı boş olamaz.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('depolar').insert({
        'depo_adi': barName,
        'tur': 'BAR',
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$barName başarıyla oluşturuldu.'),
        backgroundColor: Colors.green,
      ));
      widget.onBarCreated();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hata: Bar oluşturulamadı (Adı zaten var olabilir).'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardColor, // Beyaz arka plan
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      
      title: const Text('Yeni Bar / Depo Oluştur', 
          style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
      
      content: TextField(
        controller: _barNameController,
        style: const TextStyle(color: darkTextColor),
        decoration: InputDecoration(
          labelText: 'Bar Adı (Örn: Pool Bar, Lobby Bar)',
          labelStyle: TextStyle(color: darkTextColor.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.local_bar, color: primaryColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createBar,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Ana Mavi renk kullanıldı
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 15),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: cardColor, strokeWidth: 2))
              : const Text('Oluştur', style: TextStyle(color: cardColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}