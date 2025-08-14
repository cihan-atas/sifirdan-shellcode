# 💣 Sıfırdan İleri Seviyeye Shellcode Geliştirme Atölyesi

Bu repoya hoş geldiniz!

Shellcode, bir programdaki zafiyetin sömürülmesi sonucunda hedef sistemde çalıştırılan küçük, saf makine kodu parçasıdır. Siber güvenlik dünyasının en temel ve en zorlu konularından biridir.

Bu repository'nin amacı, shellcode geliştirme gibi karmaşık bir konuyu sıfırdan ele alarak, adım adım ve anlaşılır bir şekilde öğretmektir. Bu atölye, özellikle Türkçe kaynak eksikliğini gidermeyi ve bu alana ilgi duyan herkese bir yol haritası sunmayı hedeflemektedir. Burada sadece teori değil, aynı zamanda pratik örnekler ve çalıştırılabilir kodlar bulacaksınız.

---

## 🎯 Hedef Kitle

Bu kaynak, aşağıdaki profillere sahip kişiler için tasarlanmıştır:

*   Siber güvenlik alanına yeni başlayanlar ve öğrenciler
*   Exploit geliştirme (Exploit Development) ve zafiyet analizi konularına merak duyanlar
*   Düşük seviyeli programlama (Assembly, C) yeteneklerini geliştirmek isteyen yazılımcılar
*   CTF (Capture The Flag) yarışmalarına katılanlar

---

## 🛠️ Gerekli Ön Bilgiler

Bu yolculuğa başlamadan önce aşağıdaki konulara temel düzeyde hakim olmanız, öğrenme sürecinizi kolaylaştıracaktır:

*   **Temel Linux Kullanımı:** Terminalde gezinme, dosya oluşturma, program derleme (`gcc`) gibi temel komutlara aşinalık.
*   **Temel C Programlama Bilgisi:** Değişkenler, pointer'lar, bellek yönetimi ve fonksiyonlar hakkında genel bir anlayış.

**Not:** Derinlemesine Assembly veya bilgisayar mimarisi bilgisine sahip olmanız **gerekmiyor**. Bu konular, repo içinde sıfırdan ele alınacaktır. En önemli gereksinim, öğrenme isteği ve sabırdır!

---

## 🗺️ Yol Haritası: Repo Nasıl Kullanılır?

Bu repo, bir öğrenme patikası şeklinde düzenlenmiştir. En iyi öğrenme deneyimi için klasörleri **sırayla** takip etmenizi şiddetle tavsiye ederiz.

*   **➡️ 00 - Giriş ve Temel Kavramlar**
    *   **Başlangıç Noktası:** Shellcode dünyasına giriş yapın. Ne olduğunu, neden önemli olduğunu ve çalışması için gerekli olan temel bellek ve mimari kavramlarını öğrenin.

*   **➡️ 01 - Assembly ve Mimariler**
    *   **Temelleri Sağlamlaştırın:** Modern sistemlerde en yaygın kullanılan x86-64 Assembly dilinin temellerini, yazmaçları ve temel komutları öğrenin.

*   **➡️ 02 - Sistem Çağrıları (Syscalls)**
    *   **İşletim Sistemiyle Konuşun:** Shellcode'un "iş yapmasını" sağlayan sistem çağrılarının (syscall) ne olduğunu ve Linux'ta nasıl kullanıldığını keşfedin.

*   **➡️ 03 - İlk Shellcode Örnekleri (Linux)**
    *   **Ellerinizi Kirletin:** Teoriyi pratiğe dökme zamanı! Programı sonlandırmak (`exit`) ve yeni bir komut satırı başlatmak (`/bin/sh`) gibi ilk çalışan shellcode'larınızı yazın, derleyin ve test edin.

*   **➡️ 04 - İleri Seviye Teknikler**
    *   **Ustalığınızı Geliştirin:** Shellcode'u daha kullanışlı ve tespit edilemez hale getiren teknikleri öğrenin. Null-byte'sız kod yazma, konumdan bağımsız kod (PIC) ve Windows için shellcode geliştirme gibi konulara dalın.

*   **➡️ 05 - Araçlar ve Kaynaklar**
    *   **Cephaneliğinizi Genişletin:** Bu yolda size yardımcı olacak temel araçları (NASM, GDB, objdump) ve daha fazla bilgi edinebileceğiniz kitap, makale ve web sitelerini keşfedin.

---

## 🤝 Katkıda Bulunma (Contributing)

Bu proje topluluk destekli bir projedir. Hataları düzeltmek, yeni örnekler eklemek veya açıklamaları iyileştirmek isterseniz, katkılarınızdan mutluluk duyarız. Lütfen katkıda bulunmadan önce `CONTRIBUTING.md` dosyasını okuyun.

---

## 📜 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
