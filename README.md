# 🏨 Stoxier - Otel Stok ve Envanter Takip Uygulaması

Stoxier, otel işletmelerinin malzeme, demirbaş ve genel envanter yönetim süreçlerini dijitalleştirmek, hızlandırmak ve optimize etmek amacıyla Flutter ile geliştirilmiş modern bir mobil uygulamadır. Karmaşık stok süreçlerini kullanıcı dostu bir arayüzle buluşturarak otel departmanları (Ana Depo, Bar, Cost Control vb.) arasındaki koordinasyonu artırır.

---

## 🚀 Öne Çıkan Özellikler

* **Anlık Stok Takibi:** Depodaki ürünlerin miktarını, durumunu ve konumunu gerçek zamanlı olarak izleme.
* **Kategori Yönetimi:** Mutfak, tekstil, temizlik, teknik servis gibi otel departmanlarına özel kategorizasyon.
* **Hızlı Giriş/Çıkış İşlemleri:** Ürün ekleme, eksiltme ve güncelleme süreçlerinin pratik bir şekilde yönetilmesi.
* **Depolar Arası Transfer:** Bar ve yan depoların ana depodan ürün talep edebilmesi ve onay süreçleri.
* **Sayım ve Fark Denetimi:** Dönemsel stok sayımları, teorik miktar ile eldeki miktarın karşılaştırılması ve fark maliyeti hesabı.
* **Rol Bazlı Yetkilendirme:** Kullanıcıların departmanlarına (COST_CONTROL, BAR_SORUMLUSU) ve sorumlu oldukları depolara göre dinamik ekranlar.

---

## 🛠️ Kullanılan Teknolojiler

* **Frontend Framework:** Flutter (Dart)
* **Backend & Database:** Supabase (PostgreSQL)
* **Tasarım Standartları:** Material Design 3

---

## 🗄️ Veritabanı Şeması (Supabase / PostgreSQL)

Projenin veri modeli, bir otelin gerçek envanter mantığına uygun olarak ilişkisel bir yapıda kurgulanmıştır:

* **`oteller`:** Uygulamayı kullanan otellerin benzersiz kimlik ve giriş bilgileri.
* **`depolar`:** Otel bünyesindeki depolar (Örn: Ana Depo, Pool Bar, Lobby Bar).
* **`urunler`:** Stokta tutulan tüm ürünlerin tanımları, kategorileri ve birim fiyatları.
* **`stoklar`:** Hangi depoda, hangi üründen ne kadar (adet) kaldığını tutan ilişki tablosu.
* **`transfer_talepleri`:** Depoların birbirinden ürün istemesini ve onay süreçlerini yöneten akış.
* **`sayim_kayitlari`:** Sayım tarihlerini, teorik-gerçek miktar farklarını ve maliyet açıklarını tutan denetim tablosu.
* **`kullanicilar`:** Personellerin rollerini ve sorumlu oldukları depoları belirleyen kullanıcı tablosu.

---

## 💻 Kurulum ve Çalıştırma

Bu projeyi yerel bilgisayarınızda çalıştırmak isterseniz aşağıdaki adımları takip edebilirsiniz:

1. Bu depoyu (repository) bilgisayarınıza indirin.
2. Proje klasörünü VS Code veya Android Studio ile açın.
3. Terminali açarak gerekli paketleri indirmek için şu komutu çalıştırın:
```bash
   flutter pub get
