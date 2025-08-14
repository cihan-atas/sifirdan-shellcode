# Bölüm 10: Polimorfik ve Metamorfik Kod - Bukalemun Gibi Olmak

Şimdiye kadar fonksiyonel, yani görevini yerine getiren shellcode'lar yazmaya odaklandık. Ancak gerçek bir sızma testi veya exploit senaryosunda, shellcode'umuzun bir engeli daha vardır: **tespit edilmek**.

Antivirüs (AV) programları ve Ağ Saldırı Tespit Sistemleri (NIDS/HIDS), bilinen zararlı yazılımları ve shellcode'ları tespit etmek için **imza tabanlı tarama** yaparlar. İmza, bir dosyanın veya ağ paketinin içindeki belirli, benzersiz bir byte dizisidir.

Eğer yazdığımız `execve("/bin/sh")` shellcode'u (`\xeb\x1f\x5f...`) daha önce bir saldırıda kullanıldıysa, güvenlik ürünleri bu byte dizisini "kötü" olarak işaretleyecektir. Kodumuz hedef sisteme ulaşmadan engellenir.

Bu sorunu aşmak için shellcode'umuzun "şekil değiştirmesi" gerekir. İşte burada polimorfizm ve metamorfizm devreye girer.

## Polimorfizm (Polymorphism): "Aynı Öz, Farklı Görünüm"

Polimorfik kod, işlevselliği aynı kalırken, her kopyasında farklı görünen koddur. Temel mantık, asıl shellcode'u (payload) **şifrelemek (encrypt)** ve başına küçük bir **şifre çözücü (decoder stub)** eklemektir.

Çalışma anında süreç şöyle işler:
1.  Kontrol, önce şifre çözücü koda geçer.
2.  Şifre çözücü, kendisinden sonra gelen şifreli payload'ı bellekte çözer.
3.  Payload'ın şifresi tamamen çözüldüğünde, kontrol çözülmüş olan asıl shellcode'a atlar ve görev yerine getirilir.

 *(Buraya basit bir diyagram eklenebilir: [DECODER][ENCRYPTED PAYLOAD])*

### Polimorfizmin Avantajı

*   **İmzaları Kırmak:** Her seferinde farklı bir şifreleme anahtarı kullanıldığında, şifreli payload'ın byte dizisi tamamen farklı olur. Bu, statik imza tabanlı tespiti neredeyse imkansız hale getirir.
*   **Basit Şifreleme Yeterlidir:** Amaç askeri düzeyde kriptografi değildir. Güvenlik ürünlerini atlatmak için genellikle basit `XOR`, `ADD`, `SUB`, `NOT` gibi işlemlerle yapılan şifrelemeler yeterlidir. Örneğin, payload'ın her byte'ını `0xAA` ile XOR'lamak popüler bir yöntemdir.

### Polimorfizmin Zayıflığı

Güvenlik ürünleri aptal değildir. İmza tabanlı tespiti atlatabildiğini fark ettiklerinde, şifre çözücü kodun kendisini (`decoder stub`) tespit etmeye çalışırlar. Eğer tüm polimorfik shellcode'lar aynı şifre çözücüyü kullanırsa, bu sefer de şifre çözücünün kendisi bir imza haline gelir.

İşte bu noktada **Metasploit Framework**'teki `shikata_ga_nai` gibi gelişmiş encoder'lar devreye girer. `shikata_ga_nai`, her seferinde sadece şifreleme anahtarını değil, **şifre çözücü kodun kendisini de rastgele komutlar ve teknikler kullanarak yeniden oluşturur**. Bu da tespiti çok daha zor hale getirir.

## Metamorfizm (Metamorphism): "Tamamen Evrim Geçirmek"

Metamorfizm, polimorfizmin bir adım ötesidir. Metamorfik kod, şifreleme kullanmaz. Bunun yerine, kodun kendisi her kopyada **tamamen yeniden yazılır** ama aynı işlevi korur.

Bu, şu gibi tekniklerle yapılır:
*   **Komut Değişimi:** `mov rax, 0` yerine `xor rax, rax` veya `sub rax, rax` kullanmak.
*   **Kod Sırasını Değiştirme:** Birbirine bağımlı olmayan komutların yerini değiştirmek.
*   **Çöp Komut Ekleme (NOP Insertion):** Kodun akışını etkilemeyen `nop`, `mov rbx, rbx` gibi anlamsız komutları aralara serpiştirmek.
*   **Dallanma Değişimi:** `jmp hedef` yerine, `push hedef; ret` gibi eşdeğer bir yapı kullanmak.

### Metamorfizmin Avantaj ve Dezavantajları

*   **Avantaj:** Tespit edilmesi en zor tekniktir çünkü ortada çözülecek bir "payload" veya sabit bir "decoder" yoktur. Her kopya yapısal olarak farklıdır.
*   **Dezavantaj:** Geliştirmesi son derece karmaşıktır. Genellikle bu işi yapan özel "metamorfik motorlar" (Metamorphic Engines) yazmayı gerektirir.

## Shellcode Geliştiricisi İçin Anlamı

*   **Basit Encoder'lar:** Kendi basit XOR tabanlı polimorfik encoder'ınızı yazmak, harika bir öğrenme deneyimidir. Shellcode'u bir byte dizisi olarak ele alıp üzerinde döngü ile işlem yapmayı ve dinamik olarak şifre çözücü bir "stub" oluşturmayı içerir.
*   **Profesyonel Araçlar:** Metasploit gibi araçlar, bu karmaşık işlemleri sizin için otomatikleştirir. Ancak bu araçların **nasıl çalıştığını** anlamak, kendi özel payload'larınızı geliştirmeniz veya tespit sistemlerini daha iyi anlamanız için kritik öneme sahiptir.
*   **Manuel Obfuscation (Gizleme):** Bir antivirüs tarafından tespit edilen bir shellcode'u analiz edip, hangi byte dizisinin imzaya takıldığını bularak bu bölümü manuel olarak değiştirmek (örneğin `add` yerine `sub` ve `neg` kullanmak), pratik bir beceridir.


### Özet

| Teknik       | Yöntem                                                 | Amaç                                                         |
| :----------- | :----------------------------------------------------- | :----------------------------------------------------------- |
| **Statik**   | Kod hep aynıdır.                                       | Sadece çalışır.                                              |
| **Polimorfik** | Şifreli payload + Şifre çözücü (decoder).            | Şifreli kısmın imzasını kırar. Decoder tespit edilebilir.    |
| **Metamorfik** | Kodun yapısı her seferinde yeniden oluşturulur.        | Hem kodun hem de yapının imzasını kırar. Tespiti en zordur. |

Bu teknikler, shellcode geliştirmenin sadece bir mühendislik problemi değil, aynı zamanda güvenlik sistemleriyle sürekli bir kedi-fare oyunu olduğunu gösterir.
