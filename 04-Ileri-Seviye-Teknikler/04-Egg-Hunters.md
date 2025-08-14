# Bölüm 11: Egg Hunters - Büyük Payload'lar İçin Yer Bulmak

Bazen bir zafiyeti sömürürken karşılaştığımız en büyük kısıtlama, shellcode'umuzu enjekte edebileceğimiz alanın (buffer) çok küçük olmasıdır. Örneğin, sadece 32 byte'lık bir alanımız olabilir. Bu alana `execve` gibi karmaşık bir shellcode'u (genellikle 60-100 byte) sığdırmak imkansızdır.

Peki, büyük shellcode'umuzu çalıştıramayacak mıyız? İşte bu sorunu çözmek için geliştirilen zarif tekniğe **Egg Hunter** (Yumurta Avcısı) denir.

## Egg Hunter'ın Temel Felsefesi

Egg Hunter tekniği iki aşamadan oluşur:

1.  **Büyük Payload'ı (Yumurta) Belleğe Farklı Bir Yerden Enjekte Etmek:** Programın başka bir girdisini (örneğin kullanıcı adı, HTTP User-Agent başlığı, başka bir parametre) kullanarak, asıl büyük shellcode'umuzu belleğin daha geniş bir alanına yerleştiririz. Bu büyük shellcode'un başına, onu tanımamızı sağlayacak özel, benzersiz bir etiket (tag) koyarız. Bu etikete **"egg" (yumurta)** denir. Genellikle 4 veya 8 byte'lık, tekrar eden bir dizedir (örn: `w00t`). Yumurtayı iki kez yazarız (`w00tw00t`) ki yanlışlıkla bellekte bu deseni bulmayalım.

2.  **Küçük "Avcı" Shellcode'unu Zafiyetli Alana Enjekte Etmek:** Zafiyetin bulunduğu o küçücük (örn: 32 byte) alana, "egg hunter" adı verilen çok daha küçük bir shellcode yerleştiririz. Bu avcının tek bir görevi vardır: **Tüm bellek alanını (process memory space) adım adım tarayarak "w00tw00t" etiketini aramaktır.**

### Çalışma Süreci

1.  Program çalışır ve kontrol zafiyetli alandaki **egg hunter**'a geçer.
2.  Egg hunter, bellekteki adresleri (`0x00000000`'dan başlayarak) tek tek kontrol etmeye başlar.
3.  Her adreste, "Burada `w00tw00t` etiketi var mı?" diye kontrol eder.
4.  Eğer bir bellek adresi okunamıyorsa (segmentation fault'a neden olacaksa), bunu atlayacak bir hata yönetimi (exception handling) mekanizması kullanır.
5.  Sonunda `w00tw00t` etiketini bulduğunda, aramayı durdurur.
6.  Kontrolü, etiketten hemen sonra gelen asıl büyük shellcode'umuza (payload) atlatır (`jmp`).
7.  Büyük shellcode'umuz çalışır ve görevini yerine getirir.

*(Buraya süreci özetleyen bir diyagram eklenebilir: [EGG HUNTER] ---> Belleği Tarar ---> [w00tw00t][ASIL SHELLCODE] ---> Bulur ve Zıplar)*

## Egg Hunter Nasıl Yazılır?

Bir egg hunter yazmak, kendine özgü zorlukları olan bir iştir. Linux'ta bu iş için genellikle `access` veya `sigaction` gibi sistem çağrıları kullanılır.

İşte Linux x86 için `access` syscall'unu kullanan bir egg hunter'ın temel mantığı:

```nasm
; Bu kod konsept amaçlıdır, doğrudan çalışmayabilir.
; Amacımız bellekte 'w00t' (0x74303077) etiketini aramak.

section .text
global _start

_start:
    xor ecx, ecx         ; ECX = Bellek tarama adresimiz, 0'dan başla
    mov ebx, 0x74303077  ; EBX = Aradığımız "yumurta" (egg)

next_address:
    inc ecx              ; Bir sonraki bellek adresine geç
    ; ECX'in 0 olup olmadığını kontrol et (tüm belleği taradık mı?)
    ; Sayfa hizalaması gibi optimizasyonlar yapılabilir...

check_memory:
    ; access syscall'u (no: 33) bir bellek adresinin geçerli olup olmadığını
    ; kontrol etmek için kullanılabilir. Hata verirse, o adresi atlarız.
    mov al, 33           ; access syscall
    int 0x80
    cmp al, 0xf2         ; Hata kodu EFAULT mu? (Geçersiz adres)
    jz next_address      ; Evetse, bir sonraki adrese geç.

    ; Adres geçerliyse, "yumurtayı" ara
    cmp [ecx], ebx       ; [ecx] adresindeki değer 'w00t' mu?
    jnz next_address     ; Değilse, bir sonraki adrese geç.

    ; Yumurtayı bulduk!
    ; İkinci etiketi de kontrol edip emin olabiliriz...
    ; cmp [ecx + 4], ebx

    ; Şimdi asıl payload'a atla
    jmp ecx
```

### Windows'ta Egg Hunting

Windows'ta bu işlem genellikle `NtAccessCheckAndAuditAlarm` veya `IsBadReadPtr` gibi yapılandırılmış hata yönetimi (SEH - Structured Exception Handling) ile entegre çalışan API'lar kullanılarak yapılır. Mantık aynıdır: geçersiz bir adresi okumaya çalıştığında programın çökmesini engellemek ve taramaya devam etmek.

## Özet

**Egg Hunter'ı Ne Zaman Kullanmalıyız?**
*   Exploit için elimizdeki alan (buffer) çok küçük olduğunda.
*   Büyük shellcode'umuzu belleğe başka bir yolla (farklı bir girdi) sokma imkanımız olduğunda.

**Temel Bileşenler:**
*   **Yumurta (Egg):** Büyük payload'un başına konulan, `w00t` gibi benzersiz bir etiket.
*   **Avcı (Hunter):** Belleği tarayarak yumurtayı arayan ve bulunca payload'a zıplayan küçük shellcode.

Egg hunter tekniği, kısıtlı alanlarda çalışmak zorunda olan exploit geliştiricilerinin ne kadar yaratıcı olabileceğinin harika bir örneğidir.
