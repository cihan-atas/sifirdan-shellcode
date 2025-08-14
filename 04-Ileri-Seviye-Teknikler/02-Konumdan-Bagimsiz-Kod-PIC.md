# Bölüm 9: Konumdan Bağımsız Kod (PIC) - Adres Bilmeden Yol Bulmak

Normal bir program derlendiğinde, linker (bağlayıcı) programın bellekte belirli bir başlangıç adresine (`0x400000` gibi) yükleneceğini varsayar ve tüm fonksiyon/veri adreslerini bu başlangıç adresine göre hesaplar. Buna **mutlak adresleme** denir.

Ancak bir shellcode için bu bir lüks değildir. Shellcode'umuz, bir zafiyet aracılığıyla belleğin herhangi bir yerine, tamamen rastgele bir adrese enjekte edilebilir. Bu, `0x7fffffffdead` gibi bir stack adresi veya `0x1a2b3c4d` gibi bir heap adresi olabilir.

Eğer shellcode'umuz içindeki bir veriye (örneğin `/bin/sh` string'ine) erişmek için `mov rdi, 0x401122` gibi sabit bir adres kullanırsa, %99.9 ihtimalle çalışmayacaktır. Çünkü o adres, shellcode'un yüklendiği gerçek konumda geçerli olmayacaktır.

İşte bu sorunu çözen tekniğe **Konumdan Bağımsız Kod (Position-Independent Code - PIC)** denir. PIC'in temel felsefesi, mutlak adresler yerine **mevcut konuma göreli (relative) adresler** kullanmaktır.

## En Büyük Sorun: Kendi Adresimi Nasıl Bulurum?

PIC yazabilmek için ilk ve en önemli adım, shellcode'un o an çalıştığı komutun bellek adresini bir şekilde öğrenmektir. x86-64 mimarisinde, o an çalıştırılan komutun adresini tutan özel bir yazmaç vardır: **`RIP` (Instruction Pointer)**.

Ancak bir sorun var: `mov rax, rip` gibi bir komut **yoktur**. `RIP` yazmacına doğrudan okuma/yazma erişimimiz kısıtlıdır.

Bu yüzden `RIP`'in değerini dolaylı yoldan elde etmemizi sağlayan akıllıca tekniklere ihtiyacımız var.

## Teknik 1: JMP-CALL-POP (En Klasik Yöntem)

Bu tekniği `spawn-shell` örneğimizde zaten kullandık. Şimdi nasıl çalıştığını adım adım tekrar inceleyelim:

```nasm
_start:
    jmp short etiket_2   ; 2. Adım: 'etiket_2'ye atla.

etiket_1:
    ; 4. Adım: 'pop rdi' komutu çalışır. Stack'in tepesinde ne var?
    ; 'call' komutunun kaydettiği geri dönüş adresi, yani 'veri' etiketinin adresi.
    ; Artık RDI, bizim string'imizin gerçek bellek adresini tutuyor.
    pop rdi
    ; ... shellcode'un geri kalanı ...
    ret ; (Örnek sonu)

etiket_2:
    ; 3. Adım: 'call etiket_1' komutu çalışır. Bu komut iki şey yapar:
    ;   a) Bir sonraki komutun adresini (yani 'veri' etiketinin adresini) stack'e PUSH eder.
    ;   b) 'etiket_1'e atlar (JMP).
    call etiket_1
    
veri:
    db "/bin/sh", 0
```

Bu üç komutluk dans, `RIP`'in değerini dolaylı olarak elde etmemizi ve shellcode içindeki bir verinin mutlak adresini çalışma anında öğrenmemizi sağlar.

## Teknik 2: RIP-Relative Adresleme (Sadece 64-bit'te)

x86-64 mimarisi, PIC yazmayı kolaylaştıran harika bir özellik getirmiştir: **RIP-relative adresleme**. Bu, bir veriye `RIP` yazmacına göreli bir ofsetle erişmemizi sağlar.

Assembler (NASM gibi), bizim için bu ofseti otomatik olarak hesaplar.

```nasm
section .text
_start:
    ; NASM'a 'veri' etiketinin adresini RIP'e göre hesaplamasını söylüyoruz.
    ; Assembler, bu komutun bulunduğu yer ile 'veri' etiketi arasındaki
    ; byte farkını (ofseti) hesaplayıp makine koduna gömer.
    lea rdi, [rel veri]  ; LEA: Load Effective Address

    ; ... execve syscall hazırlığı ...
    ; mov rax, 59
    ; ...
    syscall

veri:
    db "/bin/sh", 0
```

Bu yöntem, JMP-CALL-POP tekniğinden **çok daha basit, daha kısa ve daha okunaklıdır**. Eğer sadece x86-64 için shellcode yazıyorsanız, bu genellikle en iyi yöntemdir.

Ancak, `rel` anahtar kelimesiyle üretilen makine kodu, `call` komutunun yaptığı gibi adresi bir yazmaca doğrudan "koymaz". `lea` gibi komutlarla kullanılması gerekir.

### Neden `mov` Değil de `lea`?

*   `mov rdi, [rel veri]` komutu, `veri` etiketinin **içeriğini** (yani `/bin/sh` string'inin ilk 8 byte'ını) `rdi`'a yüklemeye çalışır.
*   `lea rdi, [rel veri]` komutu ise `veri` etiketinin **adresinin kendisini** `rdi`'a yükler. Bizim de tam olarak buna ihtiyacımız var.

## Özet ve Önemi

*   Shellcode, bellekte nereye yükleneceğini bilmediği için **konumdan bağımsız** olmak zorundadır.
*   Konumdan bağımsızlık, mutlak adresler yerine **göreli (relative) adresler** kullanarak sağlanır.
*   Bunun için shellcode'un kendi konumunu (`RIP`'in değerini) öğrenmesi gerekir.
*   **JMP-CALL-POP**, bu işi yapan klasik ve mimariden bağımsız bir yöntemdir.
*   **RIP-relative adresleme (`rel` anahtar kelimesi)**, 64-bit'te bu işi çok daha kolaylaştıran modern bir yöntemdir.

PIC, "oyuncak" bir shellcode ile gerçek dünyada işe yarayabilecek bir shellcode arasındaki en temel farklardan biridir. Bu tekniğe hakim olmak, güvenilir ve taşınabilir exploit'ler yazmanın ön koşuludur.
