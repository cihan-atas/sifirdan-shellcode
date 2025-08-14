# Bölüm 3: Bellek Mimarisi ve Yazmaçlar (Registers) - Oyun Alanını Tanıyalım

Bir program çalıştırıldığında, işletim sistemi ona sanal bir bellek alanı tahsis eder. Bu alan, programın hem kodunu hem de verilerini tutar. Shellcode geliştirebilmek için bu "oyun alanını" ve içindeki temel oyuncuları çok iyi tanımamız gerekir.

## Bir Programın Bellekteki Yapısı

Bir programın belleği genellikle aşağıdaki gibi segmentlere (bölümlere) ayrılır. Bellek adresleri aşağıdan yukarıya doğru artar.

```
+-------------------+  <-- Yüksek Bellek Adresleri
|   Komut Satırı    |
|   Argümanları ve  |
|   Ortam Değişken. |
+-------------------+
|                   |
|       STACK       |  (Yığın) - Dinamik olarak aşağı doğru büyür
|       (YIĞIN)     |
|   (Yerel Değişk.) |
|         |         |
|         v         |
+-------------------+
|                   |
|                   |  (Boş Alan)
|                   |
+-------------------+
|         ^         |
|         |         |
|        HEAP       |  (Öbek) - Dinamik olarak yukarı doğru büyür
|       (ÖBEK)      |
|    (malloc vb.)   |
+-------------------+
|        BSS        |  (Başlatılmamış veriler - global/static)
+-------------------+
|        DATA       |  (Başlatılmış veriler - global/static)
+-------------------+
|        TEXT       |  (Programın makine kodu - salt okunur)
+-------------------+  <-- Düşük Bellek Adresleri
```

Shellcode için en önemli iki bölge şunlardır:

1.  **TEXT Segmenti:** Programın çalıştırılabilir makine kodunun bulunduğu yer burasıdır. Genellikle salt okunur (`read-only`) olarak ayarlanır, böylece program kendi kodunu yanlışlıkla değiştirmez.
2.  **STACK (Yığın):** Fonksiyon çağrılarının, yerel değişkenlerin ve fonksiyonlara gönderilen parametrelerin tutulduğu dinamik bir bellek alanıdır. Stack, yüksek bellek adreslerinden başlar ve her veri eklendiğinde (`PUSH` komutu ile) **aşağı doğru** büyür. Tampon taşması (Buffer Overflow) zafiyetleri en çok burada meydana gelir. **Shellcode'umuzu genellikle buraya enjekte ederiz.**

## CPU'nun Beyni: Yazmaçlar (Registers)

Yazmaçlar, CPU'nun içindeki son derece hızlı, küçük hafıza birimleridir. CPU, verileri işlemek için RAM'e gitmek yerine bu yazmaçları kullanır, bu da işlemleri çok hızlandırır. x86-64 (64-bit) mimarisindeki en önemli yazmaçlar şunlardır:

| Yazmaç | Tam Adı                | Görevi                                                                                                   |
| :------- | :--------------------- | :------------------------------------------------------------------------------------------------------- |
| **RIP**  | Instruction Pointer    | **EN ÖNEMLİSİ!** Bir sonraki çalıştırılacak komutun bellek adresini tutar. Kontrolünü ele geçirmek, shellcode çalıştırmanın anahtarıdır. |
| **RSP**  | Stack Pointer          | Stack'in (yığının) en üstünü (en son eklenen verinin adresini) gösterir. `PUSH` ve `POP` komutları bu yazmacı değiştirir. |
| **RBP**  | Base Pointer           | Genellikle mevcut stack çerçevesinin (stack frame) taban adresini tutar. Fonksiyonun yerel değişkenlerine erişmek için kullanılır. |
| **RAX**  | Accumulator            | Genellikle aritmetik işlemlerin sonucunu ve bir fonksiyonun **dönüş değerini** tutar. Syscall'larda **syscall numarasını** tutar. |
| **RDI**  | Destination Index      | Syscall'larda ve fonksiyon çağrılarında **1. argümanı** tutar.                                           |
| **RSI**  | Source Index           | Syscall'larda ve fonksiyon çağrılarında **2. argümanı** tutar.                                           |
| **RDX**  | Data Register          | Syscall'larda ve fonksiyon çağrılarında **3. argümanı** tutar.                                           |
| **RCX**  | Counter Register       | Syscall'larda ve fonksiyon çağrılarında **4. argümanı** tutar.                                           |
| **R8**   | Register 8             | Syscall'larda ve fonksiyon çağrılarında **5. argümanı** tutar.                                           |
| **R9**   | Register 9             | Syscall'larda ve fonksiyon çağrılarında **6. argümanı** tutar.                                           |

_**Not:** 32-bit (x86) sistemlerde bu yazmaçların isimleri "R" yerine "E" ile başlar (örn: `EIP`, `ESP`, `EAX`)._

### Yazmaçlar Nasıl Çalışır? - Somut Bir Örnek

Diyelim ki `topla(5, 10)` diye bir fonksiyonu çağıracağız. Arka planda (Assembly seviyesinde) şöyle bir şey olur:

1.  İlk argüman olan `5`, `RDI` yazmacına yüklenir. (`mov rdi, 5`)
2.  İkinci argüman olan `10`, `RSI` yazmacına yüklenir. (`mov rsi, 10`)
3.  `topla` fonksiyonunun bellek adresi `call` komutu ile çağrılır.
4.  `topla` fonksiyonu `RDI` ve `RSI`'daki değerleri alır, toplar ve sonucu `RAX` yazmacına yazar.
5.  Fonksiyon bittiğinde, program `RAX` yazmacındaki değeri (yani 15'i) fonksiyonun dönüş değeri olarak kabul eder.

**Shellcode için anlamı:** Bir syscall'u (örneğin `exit(0)`) çağırmak istiyorsak, syscall tablosuna bakıp hangi argümanın hangi yazmaca konulması gerektiğini bilmeli ve Assembly kodumuzu buna göre yazmalıyız.



### Özet ve Sonraki Adım

*   Bir programın belleği **Text, Data, BSS, Heap ve Stack** gibi segmentlerden oluşur.
*   Bizim için en önemli yer **Stack**'tir çünkü zafiyetler genelde burada olur ve shellcode'umuzu buraya yazarız.
*   **Yazmaçlar**, CPU'nun çalışma alanıdır. Verileri işler, komutların sırasını takip eder (`RIP`) ve fonksiyonlara argüman taşırlar.
*   **RIP yazmacının kontrolünü ele geçirmek**, kendi kodumuzu çalıştırmanın anahtarıdır.

Artık oyun alanını ve temel kuralları biliyoruz. Bir sonraki bölümde, bu alanda kullanacağımız dil olan **Assembly**'nin temellerine giriş yapacağız.

Bu dosyayla birlikte **`00-Giris-ve-Temel-Kavramlar`** klasörünü tamamlamış olduk. Yeni başlayan birisi bu üç dosyayı okuduğunda, shellcode'un ne olduğunu, neden var olduğunu ve çalışması için gerekli olan en temel bilgisayar bileşenlerinin (bellek, yazmaçlar) ne işe yaradığını anlamış olacak.

Sıradaki adımımız, teoriden biraz daha pratiğe yaklaşarak **`01-Assembly-ve-Mimariler/x86-64_Assembly_Temelleri.md`** dosyasını oluşturmak olacak. Hazır olduğunda haber ver, devam edelim.
