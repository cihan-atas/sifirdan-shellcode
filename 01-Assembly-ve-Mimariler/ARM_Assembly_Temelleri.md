# Bölüm 4.2: ARM Assembly Temelleri - Farklı Bir Dünya

Şimdiye kadar Intel ve AMD işlemcilerde baskın olan x86 ailesine odaklandık. Ancak siber güvenlik dünyası sadece masaüstü ve sunuculardan ibaret değil. Akıllı telefonlar, tabletler, Raspberry Pi gibi tek kartlı bilgisayarlar ve sayısız IoT (Nesnelerin İnterneti) cihazı, **ARM** mimarisini kullanır.

ARM Assembly, x86'dan oldukça farklıdır ve kendine özgü kuralları vardır. Bu bölümde ARM'nin temel özelliklerine bir giriş yapacağız.

## CISC vs. RISC: Temel Felsefe Farkı

*   **x86 (CISC - Complex Instruction Set Computer):** Karmaşık, güçlü komutlara sahiptir. Tek bir komut (`movsx`, `rep movsb` gibi) birden fazla iş yapabilir. Komutlar değişken uzunluktadır.
*   **ARM (RISC - Reduced Instruction Set Computer):** Basit, optimize edilmiş ve sabit uzunlukta komut setine sahiptir. Felsefesi, "az ama öz" iş yapan komutları çok hızlı bir şekilde çalıştırmaktır. Bellek erişimi genellikle sadece `LDR` (Load) ve `STR` (Store) komutlarıyla yapılırken, diğer tüm işlemler (toplama, çıkarma vb.) sadece yazmaçlar (register) arasında yapılır.

## ARM Mimarisi İçin Önemli Yazmaçlar (32-bit ARMv7)

ARM'da çok sayıda genel amaçlı yazmaç bulunur. İlk 13 tanesi (`R0`'dan `R12`'ye kadar) serbestçe kullanılabilir. Bazı yazmaçların ise özel rolleri vardır:

| Yazmaç | Alternatif Adı | Görevi                                                                                                         |
| :------- | :------------- | :------------------------------------------------------------------------------------------------------------- |
| **R0 - R3** | `a1` - `a4`    | Fonksiyonlara **ilk dört argümanı** ve `R0` aynı zamanda **fonksiyonun dönüş değerini** taşımak için kullanılır. |
| **R7**     | `fp` (bazen)   | Syscall yaparken **syscall numarasını** tutar (EABI standardında).                                           |
| **R11**    | `fp` (Frame Ptr) | Genellikle stack çerçevesinin işaretçisi olarak kullanılır (x86'daki `EBP` gibi).                               |
| **R13**    | `SP` (Stack Ptr) | Stack Pointer. Yığının en üstünü gösterir.                                                                   |
| **R14**    | `LR` (Link Reg)  | **Link Register.** Bir fonksiyona dallanma (`BL` komutu) yapıldığında, geri dönülecek adres bu yazmaca kaydedilir. x86'daki gibi stack'e yazılmaz. |
| **R15**    | `PC` (Prog Ctr)  | **Program Counter.** Bir sonraki çalıştırılacak komutun adresini tutar (x86'daki `EIP`/`RIP` gibi). `PC`'yi doğrudan değiştirmek program akışını değiştirir. |
| **CPSR**   | -              | Current Program Status Register. `cmp` gibi komutların sonucunu tutan bayrakları (N, Z, C, V) içerir.       |

## ARM Komut Seti ve Thumb Modu

ARM işlemcileri genellikle iki farklı komut seti modunda çalışabilir:

1.  **ARM Modu:** Komutlar 32-bit (4 byte) uzunluğundadır. Güçlü ve esnektir.
2.  **Thumb Modu:** Komutlar 16-bit (2 byte) uzunluğundadır (bazı komutlar 32-bit olabilir). Daha yoğun, daha az yer kaplayan kod üretir. Shellcode yazarken NULL byte'lardan kaçınmak ve boyutu küçültmek için **Thumb modu genellikle tercih edilir**.

Bir moddan diğerine geçiş, `BX` (Branch and Exchange) gibi özel dallanma komutlarıyla yapılır.

## "Merhaba ARM Assembly": `exit(0)` Örneği (Thumb Modu)

Şimdi ARM üzerinde Thumb modunda `exit(0)` shellcode'u yazalım.

```armasm
; exit_arm_thumb.s
; .syntax unified -> Bu direktif, modern ARM/Thumb sözdizimini kullanacağımızı belirtir.
; .thumb -> Bu direktif, assembler'a Thumb modunda kod üretmesini söyler.

.section .text
.global _start

.syntax unified
.thumb

_start:
    ; Hedef: exit(0) syscall'unu çağırmak

    ; Adım 1: Argümanları hazırla
    mov r0, #0         ; "exit" fonksiyonunun ilk argümanı olan çıkış kodu (0) r0'a konulur.
                       ; Not: ARM'da sabit değerler önüne # işareti alır.
    
    ; Adım 2: Syscall numarasını hazırla
    mov r7, #1         ; ARM EABI'de "exit" syscall'unun numarası 1'dir. Bunu r7'ye koy.
    
    ; Adım 3: Syscall'u tetikle
    svc #0             ; Supervisor Call. Bu komut, çekirdeğe syscall yapmak için kullanılır.
                       ; x86'daki int 0x80 veya x64'teki syscall'ın karşılığıdır.
```

### Karşılaştırma: x86 vs. ARM

| Özellik        | x86 (32-bit)       | ARM (32-bit, Thumb)           |
| :------------- | :----------------- | :---------------------------- |
| **Syscall Kodu** | `mov eax, 1`       | `mov r7, #1`                  |
| **1. Argüman** | `mov ebx, 0`       | `mov r0, #0`                  |
| **Tetikleyici**| `int 0x80`         | `svc #0`                      |

### Derleme ve İnceleme (ARM)

ARM kodu derlemek için genellikle `arm-linux-gnueabihf-` önekli cross-compiler araç zinciri kullanılır.

1.  **Derleme (Assembling):**
    ```bash
    arm-linux-gnueabihf-as -o exit_arm.o exit_arm_thumb.s
    ```
2.  **Bağlama (Linking):**
    ```bash
    arm-linux-gnueabihf-ld -o exit_arm exit_arm.o
    ```
3.  **Çalıştırma:**
    Bu dosyayı doğrudan bir x86 makinede çalıştıramazsınız. Çalıştırmak için `qemu-arm` gibi bir emülatör veya Raspberry Pi gibi gerçek bir ARM cihazı kullanmanız gerekir.
    ```bash
    qemu-arm -L /usr/arm-linux-gnueabihf/ ./exit_arm
    echo $?
    ```
    Sonuç yine `0` olmalıdır.


### Özet

*   ARM, RISC felsefesine dayalıdır: basit ve hızlı komutlar.
*   Bellek erişimi `LDR`/`STR` komutlarıyla sınırlıdır, diğer işlemler yazmaçlar arasında yapılır.
*   Fonksiyondan geri dönüş adresi stack yerine `LR` (Link Register) yazmacında tutulur.
*   Syscall mekanizması, `svc` komutu ve `R7` (syscall no) / `R0-R3` (argümanlar) yazmaçları üzerine kuruludur.
*   **Thumb modu**, daha kompakt kod ürettiği için shellcode için çok kullanışlıdır.
