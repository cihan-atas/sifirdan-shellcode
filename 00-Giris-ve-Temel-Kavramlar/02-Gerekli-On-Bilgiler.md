# Bölüm 2: Gerekli Ön Bilgiler - Cephaneliğinizi Hazırlayın

Shellcode geliştirmek, bir binayı temelden inşa etmeye benzer. Çatıyı koymadan önce sağlam duvarlara, duvarlardan önce de sağlam bir temele ihtiyacınız vardır. Bu bölümde, shellcode geliştirmenin "temelini" oluşturan üç ana konuyu inceleyeceğiz.

Bu konulara %100 hakim olmanız beklenmiyor. Amacımız, bu kavramların ne olduğunu ve shellcode ile neden ilişkili olduğunu anlamaktır. Repo'nun ilerleyen bölümlerinde her birini daha detaylı ele alacağız.

## 1. Düşük Seviye Programlama Dili: Assembly (ASM)

**Bu Nedir?**
Assembly, programlama dilleri hiyerarşisinin en alt basamaklarından biridir. C, Python veya Java gibi yüksek seviyeli dillerin aksine, Assembly komutları doğrudan işlemcinin (CPU) anlayacağı makine koduna çok yakındır. Her bir Assembly komutu (`mov`, `add`, `xor`) genellikle tek bir işlemci komutuna karşılık gelir.

**Neden Gerekli?**
Shellcode, saf makine kodudur. Makine kodunu doğrudan sayılarla (`\x48\x89\xe5`) yazmak neredeyse imkansız olduğu için, onu yazmanın en pratik yolu Assembly dilini kullanmaktır. Assembly ile yazdığımız kodu bir "assembler" (örneğin NASM) aracılığıyla doğrudan makine koduna çeviririz.

> **Analoji:** Yüksek seviyeli bir dilde "garsona sipariş vermek" gibi bir komut verirsiniz. Assembly'de ise "sağ elini kaldır", "parmağını uzat", "menüdeki şu satırı göster" gibi çok daha temel adımları tek tek tarif edersiniz. Shellcode yazarken bu kadar detaya inmek zorundayız.

## 2. Bilgisayar Mimarisi: Bellek ve Yazmaçlar (Registers)

**Bu Nedir?**
Bilgisayar mimarisi, bir bilgisayarın donanım bileşenlerinin (CPU, bellek) nasıl organize edildiğini ve birlikte nasıl çalıştığını tanımlar. Shellcode için en kritik iki bileşen şunlardır:

*   **Bellek (Memory / RAM):** Programların ve verilerin geçici olarak depolandığı yerdir. Özellikle programın çalıştığı **yığın (stack)** adı verilen bellek bölgesi, shellcode enjeksiyonu için en yaygın hedeftir.
*   **Yazmaçlar (Registers):** CPU'nun içinde bulunan çok küçük ve aşırı hızlı depolama alanlarıdır. CPU, hesaplama yaparken veya veri taşırken sürekli olarak yazmaçları kullanır. `RAX`, `RBX`, `RSP`, `RIP` gibi isimleri vardır ve her birinin özel bir görevi bulunur.

**Neden Gerekli?**
Shellcode, belleğin bir köşesinde yaşar ve görevini yerine getirmek için CPU'nun yazmaçlarını manipüle etmek zorundadır.

*   Bir sayıyı başka bir sayıya eklemek için onu bir yazmaca yüklememiz gerekir.
*   Programın bir sonraki adımda hangi komutu çalıştıracağını belirleyen `RIP` (Instruction Pointer) yazmacının kontrolünü ele geçirmemiz gerekir.
*   Bir fonksiyonu çağırmak için gerekli olan parametreleri doğru yazmaçlara yerleştirmemiz gerekir.

Yazmaçları ve belleği anlamadan Assembly yazmak, nota bilmeden enstrüman çalmaya çalışmak gibidir.

## 3. İşletim Sistemi Arayüzü: Sistem Çağrıları (System Calls / Syscalls)

**Bu Nedir?**
Modern işletim sistemlerinde (Linux, Windows, macOS), programlar donanıma (disk, ağ kartı vb.) veya çekirdek (kernel) fonksiyonlarına doğrudan erişemez. Bu, güvenlik ve kararlılık için bir koruma katmanıdır. Bir program, ekrana bir şey yazdırmak, bir dosya açmak veya bir program çalıştırmak istediğinde, bunu işletim sisteminden "talep etmek" zorundadır. Bu talebe **sistem çağrısı (syscall)** denir.

**Neden Gerekli?**
Shellcode'umuzun anlamlı bir iş yapmasını istiyorsak (örneğin bir komut satırı başlatmak), bunu işletim sistemine yaptırmamız gerekir. Shellcode, `printf()` veya `system()` gibi C kütüphane fonksiyonlarını kullanamaz çünkü bağımsız olmalıdır.

Bunun yerine, doğrudan işletim sisteminin çekirdeğiyle konuşur. Bunu yapmanın yolu, doğru syscall numarasını ve parametrelerini belirli yazmaçlara koyup ardından özel bir komut (`syscall` veya `int 0x80`) çalıştırmaktır.

> **Örnek:** Linux'ta `/bin/sh` programını çalıştırmak için `execve` isimli syscall'u kullanırız. Bu syscall'un numarası `59`'dur. Shellcode'umuzun yapması gereken şey, `RAX` yazmacına `59` sayısını, diğer ilgili yazmaçlara da `/bin/sh` gibi argümanları koyup `syscall` komutunu çağırmaktır.

---

### Özetle Yol Haritamız

Bu üç temel taşı anladıktan sonra, shellcode yazma süreci şu adımlara indirgenir:

1.  **Hedefi Belirle:** Ne yapmak istiyorsun? (Örn: `exit()` veya `execve("/bin/sh")`)
2.  **Syscall'u Bul:** Bu işi hangi syscall yapar? Numarası ve parametreleri neler?
3.  **Assembly Kodunu Yaz:** Gerekli değerleri doğru yazmaçlara koyan Assembly komutlarını yaz.
4.  **Assemble Et:** Yazdığın Assembly kodunu saf makine koduna (shellcode) çevir.
5.  **Test Et:** Oluşturduğun shellcode'u küçük bir test programı içinde çalıştırarak doğru çalışıp çalışmadığını kontrol et.

Bu temel bilgilerle, artık bir sonraki bölüme, yani bellek ve yazmaçlara daha yakından bakmaya hazırız.
