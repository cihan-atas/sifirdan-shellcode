# Bölüm 7: Windows API ve Shellcode - Farklı Kurallar, Farklı Stratejiler

Şimdiye kadar Linux'un doğrudan ve iyi belgelenmiş syscall mekanizmasına odaklandık. Ancak Windows işletim sisteminde shellcode geliştirmek, tamamen farklı bir yaklaşım ve strateji gerektirir. Linux'taki gibi sabit syscall numaralarını kullanarak çekirdekle doğrudan konuşmak, Windows'ta pratik ve güvenilir bir yöntem değildir.

## Neden Doğrudan Syscall Kullanmıyoruz?

1.  **Syscall Numaraları Stabil Değil:** Microsoft, syscall numaralarının Windows sürümleri ve hatta servis paketleri arasında değişebileceğini garanti etmez. Bu da, bir Windows sürümü için yazdığınız syscall tabanlı bir shellcode'un, bir sonraki güncellemede çalışmamasına neden olabilir.
2.  **Belgelenmemiş ve Karmaşık:** Çekirdek seviyesindeki bu arayüz (NTAPI), son kullanıcı geliştiriciler için resmi olarak belgelenmemiştir ve kullanımı daha karmaşıktır.
3.  **PatchGuard:** Modern 64-bit Windows sistemlerinde, çekirdeği ve kritik sistem yapılarını modifiye etmeye karşı koruyan "PatchGuard" adlı bir mekanizma bulunur. Doğrudan syscall yapmaya çalışmak, bu tür koruma mekanizmalarını tetikleyebilir.

## Çözüm: WinAPI ve Dinamik Adres Çözümlemesi

Windows'ta güvenilir ve sürdürülebilir bir yol, işletim sisteminin kendisinin programlara sunduğu yüksek seviyeli API'ları (Application Programming Interface) kullanmaktır. Bu fonksiyonlar, `kernel32.dll`, `user32.dll`, `ws2_32.dll` gibi Dinamik Bağlantı Kütüphaneleri (DLL'ler) içinde bulunur.

Ancak burada bir sorun var: Shellcode'umuz, bu DLL'lerin bellekte nereye yüklendiğini veya `CreateProcessA` (program çalıştırmak için) ya da `LoadLibraryA` (DLL yüklemek için) gibi fonksiyonların tam bellek adreslerini önceden bilemez.

Bu yüzden Windows shellcode'unun en temel görevi, ihtiyaç duyduğu fonksiyonların adreslerini **dinamik olarak çalışma zamanında bulmaktır.**

### Fonksiyon Adreslerini Bulma Yöntemi

Windows shellcode'u genellikle şu adımları izleyen zekice bir teknik kullanır:

1.  **`kernel32.dll`'in Adresini Bul:** Bu DLL, hemen hemen her Windows programının bellek alanına yüklenir ve en temel fonksiyonları içerir. Shellcode, `PEB` (Process Environment Block) adı verilen ve çalışan süreç hakkındaki bilgileri tutan özel bir bellek yapısını tarayarak `kernel32.dll`'in başlangıç adresini (base address) bulur.

2.  **`kernel32.dll`'in Export Tablosunu (Dışarı Aktarma Tablosu) Tara:** Her DLL, dışarıya sunduğu fonksiyonların isimlerini ve adreslerini içeren bir "Export Address Table" (EAT) barındırır. Shellcode, bu tabloyu okuyarak ihtiyacı olan iki kritik fonksiyonun adresini bulur:
    *   **`LoadLibraryA`:** Diğer DLL'leri (örneğin ağ işlemleri için `ws2_32.dll`) belleğe yüklemek için kullanılır.
    *   **`GetProcAddress`:** Yüklenmiş bir DLL içindeki herhangi bir fonksiyonun adresini, ismini kullanarak bulmayı sağlar.

3.  **Gerekli Fonksiyonların Adreslerini Yükle:** `LoadLibraryA` ve `GetProcAddress`'in adresleri bulunduktan sonra, shellcode artık bir "yol haritasına" sahiptir. Bu iki fonksiyonu kullanarak, `CreateProcessA`, `WinExec`, `socket`, `connect` gibi ihtiyacı olan diğer tüm fonksiyonların adreslerini dinamik olarak bulabilir.

4.  **Asıl İşi Yap:** Gerekli tüm fonksiyonların adresleri elde edildikten sonra, shellcode artık bu fonksiyonları çağırarak asıl amacını (bir program çalıştırmak, ters bağlantı kurmak vb.) gerçekleştirebilir.

Bu süreç, bir `hash` fonksiyonu kullanarak fonksiyon isimlerini karşılaştırmak gibi daha karmaşık ve gizli yöntemlerle de yapılabilir. Bu, shellcode'un içinde "CreateProcessA" gibi bariz string'lerin bulunmasını engelleyerek tespit edilmesini zorlaştırır.



### Özet: Linux vs. Windows

| Özellik              | Linux Shellcode                               | Windows Shellcode                                                                |
| :------------------- | :-------------------------------------------- | :------------------------------------------------------------------------------- |
| **Temel Mekanizma**  | Doğrudan Sistem Çağrıları (Syscalls)          | WinAPI Fonksiyonları (DLL'ler aracılığıyla)                                      |
| **Adresleme**        | Sabit syscall numaraları kullanılır (`mov rax, 60`) | Fonksiyon adresleri çalışma zamanında dinamik olarak bulunur.                    |
| **İlk Görev**        | Doğru argümanları yazmaçlara koyup `syscall`'u çağırmak. | `kernel32.dll`'i bulup `LoadLibraryA` ve `GetProcAddress`'in adreslerini öğrenmek. |
| **Zorluk**           | Syscall kurallarını ve konumdan bağımsız kodu bilmek. | PEB/PE formatını anlamak, bellek yapılarını taramak ve dinamik adres çözmek. |

Windows shellcode geliştirme, Linux'a göre daha fazla ön hazırlık ve daha karmaşık bir mantık gerektirir, ancak temel felsefe (önceden bilinemeyen bir ortamda hayatta kalmak) aynıdır. Bu konunun detaylı pratik uygulamaları, **`04-Ileri-Seviye-Teknikler`** bölümünde ele alınacaktır.
