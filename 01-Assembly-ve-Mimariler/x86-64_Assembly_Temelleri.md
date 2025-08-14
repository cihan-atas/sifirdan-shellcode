# Bölüm 4: x86-64 Assembly Temelleri - Makineyle Konuşmak

Temel kavramları öğrendiğimize göre, artık shellcode yazarken kullanacağımız ana dil olan Assembly'ye (ASM) giriş yapabiliriz. Bu bölümde, günümüzdeki 64-bit sistemlerin büyük çoğunluğunda kullanılan **x86-64** mimarisine odaklanacağız.

Kullanacağımız sözdizimi (syntax), bu alanda çok yaygın olan **NASM (Netwide Assembler)** sözdizimidir.

## Temel Sözdizimi (Syntax)

Bir Assembly kodu satırı genellikle şu yapıdadır:

`[etiket:] komut [operan1], [operan2] ; yorum`

*   **`etiket:` (Label):** Kod içinde belirli bir konumu işaretlemek için kullanılır. Genellikle `jmp` (atlama) veya `call` (çağırma) komutları için bir hedef belirtir. Kullanımı zorunlu değildir.
*   **`komut` (Instruction):** İşlemcinin yapacağı iştir. `mov`, `add`, `xor` gibi komutlardır.
*   **`operan1` (Hedef / Destination):** İşlemin sonucunun yazılacağı yerdir. Genellikle bir yazmaç (register) veya bellek adresidir.
*   **`operan2` (Kaynak / Source):** İşlem için kullanılacak verinin kaynağıdır. Bir yazmaç, bellek adresi veya sabit bir değer olabilir.
*   **`; yorum` (Comment):** Noktalı virgülden sonra yazılan her şey bir yorum olarak kabul edilir ve derleyici tarafından dikkate alınmaz. Kodu anlaşılır kılmak için çok önemlidir.

**En Önemli Kural:** Çoğu komutta veri akışı **sağdan sola** doğrudur. `mov rax, rbx` komutu, `rbx` yazmacının değerini `rax` yazmacına **kopyalar**.

## Shellcode İçin En Kritik Komutlar

Tüm Assembly komutlarını bilmenize gerek yok. Başlangıç için aşağıdaki komutlar hayati önem taşır:


#### Veri Taşıma Komutları

*   **`mov` (Move):** Bir yerden bir yere veri kopyalar. En temel ve en çok kullanılan komuttur.
    *   `mov rax, 60` ; `rax` yazmacına 60 değerini ata.
    *   `mov rdi, rax` ; `rax`'ın değerini `rdi`'a kopyala.

*   **`push` (Push to Stack):** Veriyi yığının (stack) en üstüne ekler ve stack pointer'ı (`rsp`) aşağı çeker.
    *   `push rax` ; `rax`'ın 8 byte'lık değerini stack'e ekle.

*   **`pop` (Pop from Stack):** Veriyi yığının en üstünden bir yazmaca çeker ve stack pointer'ı (`rsp`) yukarı iter.
    *   `pop rdi` ; Stack'in en üstündeki 8 byte'lık veriyi `rdi` yazmacına al.


#### Aritmetik ve Mantıksal Komutlar

*   **`add` / `sub` (Add / Subtract):** Toplama ve çıkarma yapar.
    *   `add rax, 10` ; `rax = rax + 10`
    *   `sub rbx, rax` ; `rbx = rbx - rax`

*   **`inc` / `dec` (Increment / Decrement):** Bir değeri 1 artırır veya 1 azaltır.
    *   `inc rcx` ; `rcx`'i bir artır.

*   **`xor` (Exclusive OR):** İki operan üzerinde bitsel XOR işlemi yapar.
    *   `xor rax, rax` ; **ÇOK ÖNEMLİ!** Bir yazmacı kendisiyle XOR'lamak, onu sıfırlamanın en verimli ve **NULL byte (`\x00`) içermeyen** yoludur. `mov rax, 0` komutu NULL byte'lar üretebilir.


#### Kontrol Akışı Komutları

*   **`jmp` (Jump):** Programın akışını belirtilen etikete koşulsuz olarak yönlendirir.
    *   `jmp hedef_etiket`

*   **`cmp` (Compare):** İki değeri karşılaştırır. Sonucu kendisi bir yere yazmaz, sadece işlemcinin durum bayraklarını (flags) ayarlar. Genellikle hemen ardından bir koşullu `jmp` komutu gelir.
    *   `cmp rax, 10` ; `rax`'ın değeri 10'a eşit mi, büyük mü, küçük mü?

*   **Koşullu Jumps:** `cmp` komutunun sonucuna göre atlama yaparlar.
    *   `je` (Jump if Equal): Eşitse atla.
    *   `jne` (Jump if Not Equal): Eşit değilse atla.
    *   `jg` (Jump if Greater): Büyükse atla.
    *   `jl` (Jump if Less): Küçükse atla.

*   **`call` / `ret` (Call / Return):** Fonksiyon çağırmak ve fonksiyondan geri dönmek için kullanılır.
    *   `call fonksiyon_etiketi`: Bu komut iki şey yapar: 1) Bir sonraki komutun adresini (`RIP`) stack'e `push` eder. 2) Belirtilen fonksiyona `jmp` eder.
    *   `ret`: Bu komut, stack'ten adresi `pop` edip `RIP` yazmacına yükler, böylece program kaldığı yerden devam eder. **Exploit'lerde en çok hedeflenen yerlerden biri, stack'teki bu geri dönüş adresidir.**


#### Diğer Önemli Komutlar

*   **`syscall`:** Çekirdeğe sistem çağrısı yapmak için kullanılan komuttur. `rax` yazmacındaki syscall numarasına ve diğer yazmaçlardaki argümanlara göre işlem yapar. **Linux shellcode'larının kalbidir.**
*   **`nop` (No Operation):** Hiçbir şey yapmaz, sadece bir byte'lık yer kaplar. Genellikle bellek hizalaması veya exploit'lerde "kaydırak" (NOP sled) oluşturmak için kullanılır.

## "Merhaba Assembly": İlk Programımız

Şimdi bu komutları kullanarak basit bir program yazalım: Programdan çıkış kodu 0 ile ayrılan `exit(0)` programı.

```nasm
; exit.nasm

global _start         ; Linker'a programın başlangıç noktasını bildirir

section .text
_start:
    mov rax, 60       ; "exit" syscall'unun numarası x86-64'te 60'tır. Bunu rax'a koy.
    mov rdi, 0        ; "exit" fonksiyonunun ilk argümanı olan çıkış kodunu (0) rdi'a koy.
    syscall           ; Çekirdeği çağır ve bu işlemi gerçekleştir.
```

### Derleme ve İnceleme

Bu kodu makine diline çevirmek için NASM ve `ld` (linker) kullanacağız.

1.  **Derleme (Assembling):**
    ```bash
    nasm -f elf64 -o exit.o exit.nasm
    ```
    Bu komut, `exit.nasm` dosyasını `elf64` formatında bir obje dosyasına (`exit.o`) çevirir.

2.  **Bağlama (Linking):**
    ```bash
    ld -o exit exit.o
    ```
    Bu komut, obje dosyasını alıp çalıştırılabilir bir `exit` dosyası oluşturur.

3.  **Çalıştırma ve Kontrol:**
    ```bash
    ./exit
    echo $?
    ```
    Program çalışacak ve hiçbir şey yazdırmadan sonlanacaktır. `echo $?` komutu, en son çalışan programın çıkış kodunu gösterir. Ekranda `0` görmelisiniz.

4.  **İnceleme (Disassembly):**
    ```bash
    objdump -d exit
    ```
    Bu komut, çalıştırılabilir dosyanın içindeki makine kodunu tekrar Assembly'ye çevirerek bize gösterir. Çıktıda yazdığımız kodun makine kodu karşılıklarını (`\x48\xc7\xc0\x3c...` gibi) görebilirsiniz. İşte o hex kodlar, bizim shellcode'umuzun ta kendisidir!


