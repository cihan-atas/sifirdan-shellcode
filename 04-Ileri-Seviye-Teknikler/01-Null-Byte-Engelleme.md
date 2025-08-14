# Bölüm 8: NULL Byte Engelleme - En Büyük Düşmanla Savaşmak

Şimdiye kadar yazdığımız shellcode'larda zaman zaman bahsettiğimiz ama üzerinde çok durmadığımız bir konuya geldik: **NULL byte (`\x00`)**.

Shellcode geliştirme dünyasında, NULL byte en büyük ve en yaygın düşmanınızdır. Yazdığınız kod ne kadar dâhiyane olursa olsun, içinde tek bir `\x00` byte'ı varsa, büyük ihtimalle çalışmayacaktır. Bu bölümde nedenini ve bu sorunu nasıl aşacağımızı öğreneceğiz.

## NULL Byte Neden Bu Kadar "Kötü"?

NULL byte'ın "kötü karakter" (bad character) olarak anılmasının sebebi, birçok programlama dilinin ve protokolünün onu özel bir anlamla yorumlamasıdır.

En yaygın örnek, **C programlama dilindeki string (karakter dizisi) işleme fonksiyonlarıdır**. `strcpy()`, `strcat()`, `printf()` gibi fonksiyonlar, bir string'in bittiğini anlamak için NULL byte'ı bir **sonlandırıcı (terminator)** olarak kullanır.

### Senaryo:

Diyelim ki bir programda `strcpy()` fonksiyonunu kullanan bir tampon taşması (buffer overflow) zafiyeti buldunuz. Shellcode'unuzu bu tampona enjekte edeceksiniz.

Eğer shellcode'unuz şöyle bir şeyse:
`\xeb\x1f\x5f\x48\x31\xc0\x88\x47\x07\x48\x89\xe6\x48\xc7\xc0\x3c\x00\x00\x00\x0f\x05`
*(Not: Bu, `mov rax, 60` komutunu içeren optimize edilmemiş bir kod parçasıdır)*

`strcpy()` fonksiyonu bu byte dizisini kopyalamaya başlar. Her şey yolunda giderken, `\x00` byte'ına rastladığı an durur ve "Tamam, string burada bitti" der. Sonuç olarak, shellcode'unuzun sadece `\x00`'a kadar olan kısmı belleğe kopyalanır ve kodunuz yarım kaldığı için çalışmaz.

Bu sorun sadece `strcpy` için değil, ağ üzerinden veri alan, dosyadan okuyan veya komut satırı argümanı alan birçok fonksiyonda da mevcuttur.

## NULL Byte Üreten Yaygın Komutlar

Assembly'de masum görünen bazı komutlar, makine koduna çevrildiklerinde NULL byte'lar üretebilirler.

*   **Bir yazmaca küçük bir değer yüklemek:**
    `mov rax, 60` -> Makine Kodu: `48 c7 c0 3c 00 00 00`
    Burada 64-bit'lik `rax` yazmacını doldurmak için sayının önüne bir sürü `\x00` eklenir.

*   **Bir yazmacı sıfırlamak:**
    `mov rax, 0` -> Makine Kodu: `48 c7 c0 00 00 00 00`
    Bu, en bariz NULL byte kaynağıdır.

*   **Bellekteki bir adrese sıfır yazmak:**
    `mov dword [rdi], 0` -> Makine Kodu: `c7 07 00 00 00 00`

## NULL Byte'sız Kod Yazma Teknikleri

Neyse ki, bu sorunu aşmak için birçok akıllıca teknik mevcuttur. Amaç, aynı işi yapan ama makine kodunda `\x00` üretmeyen alternatif komutlar bulmaktır.

### Teknik 1: Bir Yazmacı Sıfırlamak için `XOR` Kullanmak

Bir sayıyı kendisiyle XOR'lamak her zaman sıfır sonucunu verir. Bu, bir yazmacı sıfırlamanın en popüler ve en verimli yoludur.

*   **Kötü:** `mov rax, 0` (`48 c7 c0 00 00 00 00` - 7 byte, 4'ü NULL)
*   **İyi:** `xor rax, rax` (`48 31 c0` - 3 byte, NULL yok)
    *   32-bit için: `xor eax, eax` (`31 c0` - 2 byte, NULL yok)

### Teknik 2: Küçük Değerler İçin Daha Küçük Yazmaçları Kullanmak

64-bit'lik `rax`'a küçük bir değer atamak yerine, onun daha küçük alt bölümlerini (`eax`, `ax`, `al`) kullanabiliriz.

*   **Kötü:** `mov rax, 60` (`48 c7 c0 3c 00 00 00` - 7 byte)
*   **İyi:** `mov al, 60` (`b0 3c` - 2 byte)
    *   Bu tekniği kullanmadan önce, `rax`'ın üst bitlerinin temiz (sıfır) olduğundan emin olmalıyız. Genellikle hemen öncesinde bir `xor rax, rax` komutu kullanılır.

**Örnek Kombinasyon:**
```nasm
xor rax, rax   ; rax'ı tamamen sıfırla (NULL'suz)
mov al, 59     ; rax'ın sadece alt 8-bit'ini 59 yap. Sonuç: rax = 59 (NULL'suz)
```

### Teknik 3: Aritmetik İşlemlerle Değer Oluşturmak

İstediğimiz değeri doğrudan yüklemek yerine, aritmetik işlemlerle elde edebiliriz. Bu, diğer teknikler işe yaramadığında kullanılır.

Örneğin, `eax`'a `0x01010101` değerini (içinde NULL byte olmayan) yükleyip sonra `eax`'tan `0x01010101` çıkararak sıfır elde edebiliriz.

```nasm
mov eax, 0x01010101
sub eax, 0x01010101  ; eax artık 0, ama NULL byte kullanmadık.
```

### Teknik 4: Stack'i Kullanarak NULL Oluşturmak

Bazen `execve` gibi syscall'larda argüman dizisini sonlandırmak için mutlaka bir NULL değere ihtiyacımız olur. Bunu shellcode'un içine gömmek yerine, çalışma zamanında oluşturabiliriz.

```nasm
xor rax, rax    ; rax = 0
push rax        ; Stack'e 8 byte'lık NULL (0x0000000000000000) at.
```
Burada `push rax` komutunun kendisi NULL byte içermez, ama stack'e NULL yazar. Bu, shellcode'un kendisinin kopyalanmasını engellemez.


### Özet

*   NULL byte (`\x00`), C string fonksiyonları tarafından sonlandırıcı olarak kullanıldığı için shellcode'un yarım kopyalanmasına neden olur.
*   **Asla `mov reg, 0` kullanma.** Yerine `xor reg, reg` kullan.
*   Küçük bir değeri büyük bir yazmaca atarken dikkatli ol. `mov rax, 60` yerine `xor rax, rax; mov al, 60` gibi kombinasyonları tercih et.
*   Gerekli NULL byte'ları (örneğin string sonlandırmak için) shellcode'un içine statik olarak yazmak yerine, çalışma anında dinamik olarak oluştur.
