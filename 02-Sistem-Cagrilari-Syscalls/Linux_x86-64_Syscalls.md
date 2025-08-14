# Bölüm 6: Linux x86-64 Sistem Çağrıları - Komut Listemiz

Önceki bölümde bir sistem çağrısının nasıl çalıştığını öğrendik. Şimdi ise hangi komutları verebileceğimizi, yani hangi syscall'ların mevcut olduğunu ve bunları nasıl kullanacağımızı göreceğiz. Bu bölüm, shellcode yazarken sık sık geri dönüp bakacağınız bir referans sayfası niteliğindedir.

## Syscall Numaralarını Nerede Bulabiliriz?

Linux sistemlerde, x86-64 mimarisi için syscall numaraları ve isimleri genellikle çekirdek başlık dosyalarında bulunur. Sisteminize göz atmak isterseniz, bu dosyayı inceleyebilirsiniz:

`/usr/include/x86_64-linux-gnu/asm/unistd_64.h`

Bu dosyayı açtığınızda şuna benzer satırlar göreceksiniz:

```c
#define __NR_read 0
#define __NR_write 1
#define __NR_open 2
#define __NR_close 3
...
#define __NR_execve 59
#define __NR_exit 60
```

`__NR_` öneki "Number" (Numara) anlamına gelir ve her bir syscall'ın `RAX` yazmacına konulması gereken numarasını belirtir.

## x86-64 Çağrı Kuralı (Calling Convention) Tekrarı

Unutmayalım, syscall yaparken parametreleri (argümanları) doğru yazmaçlara doğru sırayla koymalıyız:

*   **Syscall Numarası:** `RAX`
*   **1. Argüman:** `RDI`
*   **2. Argüman:** `RSI`
*   **3. Argüman:** `RDX`
*   **4. Argüman:** `R10`
*   **5. Argüman:** `R8`
*   **6. Argüman:** `R9`

## Shellcode İçin En Yaygın Kullanılan Syscall'lar

Aşağıda, shellcode geliştirirken en sık karşılaşacağınız ve kullanacağınız bazı temel syscall'ların bir listesi bulunmaktadır.


### `exit` - Programı Sonlandırma

Programın çalışmasını sonlandırır ve işletim sistemine bir çıkış kodu döndürür.

*   **Syscall Numarası:** 60
*   **C Karşılığı:** `void exit(int status);`
*   **Assembly Uygulaması:**
    ```nasm
    ; exit(0) -> Başarıyla çık
    mov rax, 60     ; syscall numarası: exit
    mov rdi, 0      ; 1. argüman (status): 0 (Başarı)
    syscall
    ```


### `write` - Veri Yazma

Bir dosya tanımlayıcısına (file descriptor) veri yazar. Ekrana yazı yazdırmak için de kullanılır.

*   **Syscall Numarası:** 1
*   **C Karşılığı:** `ssize_t write(int fd, const void *buf, size_t count);`
*   **Assembly Uygulaması:**
    ```nasm
    ; "Merhaba\n" yazısını ekrana (stdout) yaz
    section .data
        mesaj db 'Merhaba', 0x0a ; 0x0a = newline karakteri
        mesaj_len equ $ - mesaj  ; Mesajın uzunluğunu hesapla

    section .text
    _start:
        mov rax, 1              ; syscall numarası: write
        mov rdi, 1              ; 1. argüman (fd): 1 (stdout - standart çıktı/ekran)
        mov rsi, mesaj          ; 2. argüman (buf): Mesajın adresi
        mov rdx, mesaj_len      ; 3. argüman (count): Mesajın uzunluğu
        syscall
    ```
    *Not: Bu örnekte `.data` bölümü kullanılmıştır. Gerçek bir shellcode'da bu string'i stack'e yazmak gibi teknikler kullanılır.*


### `read` - Veri Okuma

Bir dosya tanımlayıcısından veri okur. Kullanıcıdan girdi almak için de kullanılır.

*   **Syscall Numarası:** 0
*   **C Karşılığı:** `ssize_t read(int fd, void *buf, size_t count);`
*   **Assembly Uygulaması:**
    ```nasm
    ; Klavyeden (stdin) 100 byte veri oku ve bir tampona yaz
    section .bss
        buffer resb 100         ; 100 byte'lık bir tampon alanı ayır

    section .text
    _start:
        mov rax, 0              ; syscall numarası: read
        mov rdi, 0              ; 1. argüman (fd): 0 (stdin - standart girdi/klavye)
        mov rsi, buffer         ; 2. argüman (buf): Verinin yazılacağı tamponun adresi
        mov rdx, 100            ; 3. argüman (count): Okunacak maksimum byte sayısı
        syscall
    ```


### `execve` - Program Çalıştırma

**Shellcode'un Kutsal Kasesi!** Yeni bir program çalıştırır. Genellikle `/bin/sh` çalıştırarak bir komut satırı (shell) elde etmek için kullanılır.

*   **Syscall Numarası:** 59
*   **C Karşılığı:** `int execve(const char *filename, char *const argv[], char *const envp[]);`
*   **Assembly Uygulaması (Konsept):** Bu en karmaşık olanıdır.
    ```nasm
    ; execve("/bin/sh", ["/bin/sh", NULL], NULL) çağrısını yap
    
    ; 1. Gerekli string'leri ve pointer dizisini stack'e veya belleğe hazırla.
    ;    "/bin/sh" string'i
    ;    Bu string'in adresini içeren bir pointer dizisi (argv)
    ;    NULL ile sonlandırılmış argüman ve ortam değişkeni dizileri
    
    ; 2. Syscall'u çağır
    mov rax, 59             ; syscall numarası: execve
    mov rdi, [adres_of_"/bin/sh"] ; 1. arg (filename): "/bin/sh" string'inin adresi
    mov rsi, [adres_of_argv]      ; 2. arg (argv): Argüman dizisinin adresi
    mov rdx, 0              ; 3. arg (envp): NULL (ortam değişkeni yok)
    syscall
    ```
    Bu syscall'un tam uygulaması, konumdan bağımsız kod (PIC) gibi ileri seviye teknikler gerektirir ve **`03-Ilk-Shellcode-Ornekleri-Linux`** bölümünde detaylıca incelenecektir.


### Diğer Faydalı Syscall'lar

*   **`open` (2):** Bir dosya açar ve bir file descriptor döndürür.
*   **`close` (3):** Bir file descriptor'ı kapatır.
*   **`socket` (41), `connect` (42), `bind` (49), `listen` (50):** Ağ işlemleri için kullanılır (örneğin reverse shell yazmak için).
*   **`dup2` (33):** Bir file descriptor'ı kopyalar. `stdin`, `stdout` ve `stderr`'i bir ağ soketine yönlendirmek için çok kullanışlıdır.
