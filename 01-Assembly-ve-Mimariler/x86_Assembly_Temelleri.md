# Bölüm 4.1: x86 (32-bit) Assembly Temelleri - 64-bit'in Atası

Her ne kadar modern sistemlerin çoğu 64-bit (x86-64) olsa da, 32-bit (x86 veya i386 olarak da bilinir) mimarisiyle yazılmış programlara hala sıkça rastlanır. 32-bit exploit geliştirme, öğrenme aşamasında bazı kavramları daha basit hale getirebilir.

Bu bölümde, x86-64 ile x86 arasındaki temel farklara ve 32-bit Assembly'nin kendine özgü özelliklerine odaklanacağız.

## x86-64 ile Temel Farklar Nelerdir?

1.  **Yazmaç Boyutları ve İsimleri:**
    *   64-bit'teki `R` önekli yazmaçlar (`RAX`, `RBX` vb.) yerine, 32-bit'te `E` önekli yazmaçlar (`EAX`, `EBX` vb.) kullanılır. `E`, "Extended" (Genişletilmiş) anlamına gelir.
    *   Yazmaçlar 64-bit yerine 32-bit (4 byte) genişliğindedir.
    *   x86-64'teki `R8`-`R15` gibi ekstra genel amaçlı yazmaçlar 32-bit'te bulunmaz.

2.  **Sistem Çağrısı (Syscall) Mekanizması:**
    *   Bu en büyük farklardan biridir. 64-bit'teki `syscall` komutu yerine, 32-bit Linux'ta **`int 0x80`** (interrupt 0x80) komutu kullanılır. Bu, çekirdeğe bir "yazılım kesmesi" göndererek syscall'u tetikler.
    *   Çağrı kuralı (Calling Convention) da farklıdır. Argümanlar `RDI`, `RSI` gibi yazmaçlar yerine, belirli bir sırayla **`EBX`, `ECX`, `EDX`** gibi yazmaçlara konulur.

3.  **Bellek Adresleme:**
    *   Doğal olarak, 32-bit sistemler en fazla 2³² byte (4 GB) belleği adresleyebilirler.

## 32-bit (x86) Mimarisi İçin Önemli Yazmaçlar

| Yazmaç | Tam Adı                | 32-bitteki Görevi                                                                                         |
| :------- | :--------------------- | :-------------------------------------------------------------------------------------------------------- |
| **EIP**  | Instruction Pointer    | **(En Önemli)** Bir sonraki çalıştırılacak komutun 32-bit'lik bellek adresini tutar.                      |
| **ESP**  | Stack Pointer          | Stack'in (yığının) en üstünü gösterir.                                                                    |
| **EBP**  | Base Pointer           | Mevcut stack çerçevesinin taban adresini tutar.                                                           |
| **EAX**  | Accumulator            | Fonksiyonların **dönüş değerini** ve syscall'larda **syscall numarasını** tutar.                            |
| **EBX**  | Base Register          | Syscall'larda **1. argümanı** tutar.                                                                      |
| **ECX**  | Counter Register       | Syscall'larda **2. argümanı** tutar.                                                                      |
| **EDX**  | Data Register          | Syscall'larda **3. argümanı** tutar.                                                                      |
| **ESI**  | Source Index           | Syscall'larda **4. argümanı** tutar.                                                                      |
| **EDI**  | Destination Index      | Syscall'larda **5. argümanı** tutar.                                                                      |

## "Merhaba 32-bit Assembly": `exit(0)` Örneği

Şimdi aynı `exit(0)` programını 32-bit için yazalım ve farkları görelim.

```nasm
; exit_32.nasm

global _start

section .text
_start:
    ; Hedef: exit(0) syscall'unu çağırmak
    
    ; Adım 1: syscall numarasını EAX'a koy
    mov eax, 1         ; 32-bit Linux'ta "exit" syscall'unun numarası 1'dir.
    
    ; Adım 2: Argümanları doğru yazmaçlara koy
    mov ebx, 0         ; "exit"in ilk argümanı (çıkış kodu 0) EBX'e konulur.
    
    ; Adım 3: Syscall'u tetikle
    int 0x80           ; Çekirdeği çağır.
```

### Karşılaştırma: x86-64 vs x86

| Özellik        | x86-64 (64-bit)                 | x86 (32-bit)                  |
| :------------- | :------------------------------ | :---------------------------- |
| **Syscall Kodu** | `mov rax, 60`                   | `mov eax, 1`                  |
| **1. Argüman** | `mov rdi, 0`                    | `mov ebx, 0`                  |
| **Tetikleyici**| `syscall`                       | `int 0x80`                    |

Gördüğünüz gibi, mantık aynı olsa da kullanılan yazmaçlar, komut ve syscall numaraları tamamen farklıdır. Bir mimari için yazdığınız shellcode, diğerinde çalışmaz.

### Derleme ve İnceleme (32-bit)

32-bit kod derlemek için assembler ve linker'a doğru formatı belirtmemiz gerekir.

1.  **Derleme (Assembling):**
    ```bash
    # -f elf32 ile 32-bit formatında derle
    nasm -f elf32 -o exit_32.o exit_32.nasm
    ```

2.  **Bağlama (Linking):**
    ```bash
    # -m elf_i386 ile 32-bit çalıştırılabilir dosyası oluştur
    ld -m elf_i386 -o exit_32 exit_32.o
    ```

3.  **Çalıştırma ve Kontrol:**
    ```bash
    ./exit_32
    echo $?
    ```
    Sonuç yine `0` olmalıdır.

Eğer 64-bit bir sistemde 32-bit bir program derlemeye çalışıyorsanız, `multilib` desteğinizin (örneğin `gcc-multilib`) kurulu olması gerekebilir.


### Özet

*   x86, 32-bit mimariyi ifade eder ve yazmaçları `E` harfiyle başlar (`EAX`, `EIP`).
*   x86 için Linux syscall mekanizması, `syscall` komutu yerine **`int 0x80`** kesmesini kullanır.
*   Syscall argümanları `EBX`, `ECX`, `EDX`... sırasıyla gider.
*   Bir shellcode yazarken **hedef mimariyi** bilmek mutlak bir zorunluluktur.
