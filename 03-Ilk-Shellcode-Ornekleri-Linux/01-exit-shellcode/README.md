# Örnek 1: `exit()` Shellcode'u - "Merhaba Dünya"nın Karşılığı

Shellcode dünyasına "Merhaba Dünya" demek, ekrana bir şey yazdırmakla değil, programı kontrollü bir şekilde sonlandırmakla olur. Bu en basit shellcode, `exit(0)` sistem çağrısını (syscall) kullanarak programdan temiz bir şekilde çıkmayı amaçlar.

Bu örnek, öğrendiğimiz temel kavramları (syscall numaraları, yazmaçlar, Assembly komutları) bir araya getiren mükemmel bir başlangıç noktasıdır.

## 🎯 Amaç

Yalnızca `exit(0)` işlevini yerine getiren, olabilecek en küçük ve en basit x86-64 Linux shellcode'unu oluşturmak.

*   **C Kodu Karşılığı:** `exit(0);`
*   **Hedef Syscall:** `exit`
*   **Syscall Numarası:** 60
*   **Gerekli Argümanlar:** `int status = 0` (başarıyla çıkıldığını belirtir)

## 🛠️ Adım 1: Assembly Kodunu Yazma (`exit.nasm`)

Önceki bölümlerde öğrendiğimiz x86-64 syscall çağrı kuralını hatırlayalım:
1.  Syscall numarası `RAX`'a konulur.
2.  İlk argüman `RDI`'a konulur.

Bu bilgilere göre `exit.nasm` dosyamızın içeriği şu şekilde olmalıdır:

```nasm
; exit.nasm
; Yazar: [Adınız/Kullanıcı Adınız]
; Amaç: exit(0) syscall'u ile programı sonlandırmak.

global _start

section .text

_start:
    ; exit(0) için hazırlık
    mov rax, 60     ; 1. Adım: "exit" syscall'unun numarası (60) rax'a yüklenir.
    mov rdi, 0      ; 2. Adım: "exit"in ilk argümanı olan çıkış kodu (0) rdi'a yüklenir.
    syscall         ; 3. Adım: Çekirdeği çağırarak syscall'u tetikle.
```

**Not:** Bu kodda `mov rdi, 0` yerine `xor rdi, rdi` kullanmak daha verimli ve genellikle daha kısa bir makine kodu üretir. Bu, ileri seviye shellcode'larda sıkça göreceğiniz bir optimizasyondur. Şimdilik anlaşılırlık için `mov` kullanıyoruz.

## ⚙️ Adım 2: Derleme, Bağlama ve Test Etme

Şimdi yazdığımız Assembly kodunu çalıştırılabilir bir dosyaya dönüştürelim.

1.  **Derleme (Assemble):**
    ```bash
    nasm -f elf64 -o exit.o exit.nasm
    ```
    Bu komut, `exit.nasm` kaynak kodunu `elf64` formatında bir nesne dosyasına (`exit.o`) çevirir.

2.  **Bağlama (Link):**
    ```bash
    ld -o exit exit.o
    ```
    Bu komut, nesne dosyasını alıp çalıştırılabilir bir `exit` dosyası oluşturur.

3.  **Çalıştır ve Doğrula:**
    ```bash
    ./exit
    ```
    Program sessizce çalışıp sonlanacaktır. Başarılı olup olmadığını anlamak için, son çalışan programın çıkış kodunu kontrol edelim:
    ```bash
    echo $?
    ```
    Eğer çıktınız **`0`** ise, tebrikler! İlk programınız görevini başarıyla yerine getirdi.

## 💣 Adım 3: Makine Kodunu (Shellcode) Çıkarma

Amacımız çalıştırılabilir bir dosya değil, başka bir programa enjekte edebileceğimiz saf makine kodu dizisidir. `objdump` aracı ile bu kodları ayıklayabiliriz.

```bash
objdump -d ./exit
```

Çıktıda şuna benzer bir bölüm göreceksiniz:
```
0000000000401000 <_start>:
  401000:       b8 3c 00 00 00          mov    eax,0x3c
  401005:       bf 00 00 00 00          mov    edi,0x0
  40100a:       0f 05                   syscall
```
*Not: Sizin derleyiciniz `mov rax, 60` yerine `mov eax, 0x3c` gibi eşdeğer bir komut kullanmış olabilir. Sonuç aynıdır.*

Bu çıktıdaki hex kodlar (`b8 3c 00 00 00 bf 00 00 00 00 0f 05`) bizim shellcode'umuzdur. Ancak içinde çok sayıda NULL byte (`\x00`) var. Daha "profesyonel" bir shellcode şöyle yazılırdı:

**Optimize Edilmiş Kod (`xor` ile):**
```nasm
_start:
    xor rdi, rdi    ; rdi = 0 (Null byte içermez)
    mov rax, 60     ; rax = 60
    syscall
```
Bunu derleyip `objdump` ile baktığınızda daha kısa ve NULL byte'sız bir shellcode elde edersiniz: `\x48\x31\xff\x48\xc7\xc0\x3c\x00\x00\x00\x0f\x05`. (Not: Bu bile tam optimize değil, en iyisi `mov al, 60` olurdu: `\x31\xff\xb0\x3c\x0f\x05`).

Şimdilik basit versiyonu kullanalım. Shellcode'umuzu C formatına çevirelim:
`\xb8\x3c\x00\x00\x00\xbf\x00\x00\x00\x00\x0f\x05`

## 💉 Adım 4: Shellcode'u Test Edici Bir Programla Çalıştırma (`calistirici.c`)

Şimdi bu shellcode'u bir C programının içine gömerek çalışıp çalışmadığını test edelim. Bu, gerçek bir zafiyet sömürme senaryosunu simüle eder.

`calistirici.c` dosyasının içeriği şu şekilde olmalıdır:

```c
// calistirici.c
#include <stdio.h>
#include <string.h>

// objdump ile çıkardığımız shellcode
// Bu, "mov rax, 60; mov rdi, 0; syscall" komutlarının makine kodudur.
// Derleyicinize göre değişiklik gösterebilir.
unsigned char shellcode[] = "\xb8\x3c\x00\x00\x00\xbf\x00\x00\x00\x00\x0f\x05";

int main() {
    printf("Shellcode calistirilmadan once...\n");
    printf("Shellcode uzunlugu: %zu byte\n", strlen(shellcode));

    // Bir fonksiyon göstericisi (pointer) oluşturup
    // adresini shellcode dizimizin başlangıcına ayarlıyoruz.
    // Sonra bu adrese atlayıp kodu çalıştırıyoruz.
    void (*calistir)() = (void(*)())shellcode;
    calistir();
    
    // Eğer shellcode doğru çalışırsa, bu satır HİÇBİR ZAMAN çalışmaz.
    printf("Shellcode calistirildiktan sonra...\n");

    return 0;
}
```

### Derleme ve Çalıştırma

Bu C kodunu derlerken iki önemli güvenlik mekanizmasını devre dışı bırakmamız gerekiyor:
*   **Stack Koruması:** `-fno-stack-protector`
*   **Çalıştırılamaz Bellek (NX Bit):** `-z execstack` (Stack'i çalıştırılabilir olarak işaretler)

```bash
gcc -fno-stack-protector -z execstack -o calistirici calistirici.c
./calistirici
```

### Beklenen Çıktı

```
Shellcode calistirilmadan once...
Shellcode uzunlugu: 12 byte
```
Program `Shellcode calistirildiktan sonra...` mesajını **yazdırmadan** sonlanacaktır. Bu, shellcode'umuzun başarıyla çalıştığını ve `exit()` syscall'unu çağırarak programı sonlandırdığını gösterir.

