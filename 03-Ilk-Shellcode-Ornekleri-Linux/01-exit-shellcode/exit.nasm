; exit.nasm
; Yazar: [Kendi Adınız / Kullanıcı Adınız]
; Tarih: [Güncel Tarih]
; Amaç: x86-64 Linux üzerinde exit(0) sistem çağrısını kullanarak
;       programı temiz bir şekilde sonlandırmak.

; global direktifi, _start etiketini linker için görünür kılar.
; Bu, programın başlangıç noktasının burası olduğunu belirtir.
global _start

; .text bölümü, çalıştırılabilir kodun bulunduğu segmenttir.
section .text

_start:
    ; exit() syscall'unu çağırmak için hazırlık yapılıyor.
    ; C karşılığı: exit(0);

    ; Adım 1: Syscall numarasını RAX yazmacına yükle.
    ; x86-64 mimarisinde 'exit' syscall'unun numarası 60'tır.
    mov rax, 60

    ; Adım 2: İlk argümanı RDI yazmacına yükle.
    ; 'exit' fonksiyonunun ilk ve tek argümanı, programın çıkış
    ; durum kodudur. 0, başarılı bir sonlanma anlamına gelir.
    mov rdi, 0

    ; Adım 3: syscall komutunu çalıştır.
    ; Bu komut, işletim sistemi çekirdeğine bir kesme (interrupt) gönderir
    ; ve hazırlanan syscall'un çalıştırılmasını tetikler.
    syscall

; --- Programın sonu ---
; syscall'dan sonraki kodlar çalışmayacaktır çünkü program sonlanmıştır.
