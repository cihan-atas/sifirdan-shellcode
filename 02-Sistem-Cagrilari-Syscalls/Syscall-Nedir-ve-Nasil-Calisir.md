# Bölüm 5: Sistem Çağrıları (Syscalls) - İşletim Sisteminden İş İstemek

Önceki bölümde Assembly ile CPU'ya nasıl komut vereceğimizi öğrendik. Ancak programlarımızın dosya okuma, ekrana yazı yazdırma, ağ bağlantısı kurma veya yeni bir program başlatma gibi anlamlı işler yapabilmesi için CPU'dan daha fazlasına ihtiyacı vardır: **İşletim Sisteminin Çekirdeği (Kernel)**.

Sistem çağrıları (syscalls), programlarımızın çekirdekten bu tür hizmetleri talep etmesinin resmi ve güvenli yoludur.

## Kullanıcı Modu (User Mode) ve Çekirdek Modu (Kernel Mode)

Modern işletim sistemleri, sistemi korumak için iki temel çalışma modunda çalışır:

1.  **User Mode (Kullanıcı Modu):** Normal programlarımızın (web tarayıcınız, metin düzenleyiciniz, yazdığımız C programları) çalıştığı kısıtlı moddur. Bu moddaki bir program, donanıma doğrudan erişemez veya diğer programların belleğine keyfi olarak müdahale edemez. Bu, sistemin kararlılığını ve güvenliğini sağlar.

2.  **Kernel Mode (Çekirdek Modu):** İşletim sisteminin çekirdeğinin çalıştığı ayrıcalıklı moddur. Bu modda çalışan kodun donanım ve bellek üzerinde tam kontrolü vardır.

Bir programın User Mode'dan Kernel Mode'daki bir hizmete ihtiyaç duyması durumunda arada bir köprüye ihtiyaç vardır. İşte bu köprü, **sistem çağrılarıdır**.


*(Görsel: User Mode'daki bir uygulamanın donanıma erişmek için Kernel Mode'a syscall ile geçişini gösteren basit bir diyagram)*

## Sistem Çağrısı (Syscall) Nasıl Çalışır?

Bir program bir syscall yapmak istediğinde, aslında işlemciye kontrollü bir şekilde "beni durdur ve bu isteğimi çekirdeğe ilet" der. Bu süreç, hedef mimariye göre farklılık gösterse de genel mantık aynıdır.

### x86-64 Linux Örneği:

1.  **Ne İstediğini Belirle (Syscall Numarası):** Her sistem çağrısının benzersiz bir numarası vardır. Örneğin, `exit` için `60`, `write` için `1`, `execve` için `59` gibi. Program, hangi işlemi yapmak istediğini bu numarayı kullanarak belirtir. Bu numara, **`RAX`** yazmacına konulur.

2.  **Parametreleri Hazırla (Argümanlar):** Yapılacak işlemin parametreleri (örneğin `write` için "nereye yazılacağı", "ne yazılacağı" ve "ne kadar yazılacağı") belirli bir sırayla diğer yazmaçlara yerleştirilir. Bu sıraya **"Calling Convention" (Çağrı Kuralı)** denir.
    *   1. Argüman: `RDI`
    *   2. Argüman: `RSI`
    *   3. Argüman: `RDX`
    *   4. Argüman: `R10` (RCX değil, dikkat!)
    *   5. Argüman: `R8`
    *   6. Argüman: `R9`

3.  **Kapıyı Çal (Tetikleme):** Tüm hazırlıklar tamamlandıktan sonra program, **`syscall`** komutunu çalıştırır. Bu özel komut, bir "trap" (tuzak) veya "interrupt" (kesme) oluşturarak işlemcinin User Mode'dan Kernel Mode'a geçmesini sağlar.

4.  **Çekirdek Devralır:** Çekirdek, kontrolü devralır. `RAX` yazmacındaki syscall numarasını okur ve ne istendiğini anlar. Ardından diğer yazmaçlardaki (RDI, RSI, vb.) parametreleri alarak istenen işlemi güvenli bir şekilde gerçekleştirir.

5.  **Geri Dönüş:** İşlem bittikten sonra çekirdek, sonucunu (genellikle bir başarı/hata kodu) yine `RAX` yazmacına yazar ve kontrolü tekrar programın kaldığı yerden, User Mode'a geri verir.

## Neden `printf()` Değil de Doğrudan Syscall?

Normal bir C programı yazarken dosyaya yazmak için `fprintf()` veya ekrana yazdırmak için `printf()` gibi kütüphane fonksiyonları kullanırız. Bu fonksiyonlar aslında bizim için yukarıdaki karmaşık syscall sürecini yöneten birer "ara katmandır". `printf`, arka planda `write` syscall'unu çağırır.

Ancak shellcode yazarken:

*   **Bağımsız Olmalıyız:** Shellcode, `libc` gibi harici kütüphanelerin bellekte nerede olduğunu bilemez ve onlara bağımlı olamaz.
*   **Küçük Olmalıyız:** Kütüphane fonksiyonlarını çağırmak için gereken kod, doğrudan syscall yapmaktan çok daha büyüktür.

Bu yüzden, shellcode'da aracıları atlayıp doğrudan işletim sisteminin kapısını çalarız.


### Özet

*   Programlarımız kısıtlı **User Mode**'da, işletim sistemi ise ayrıcalıklı **Kernel Mode**'da çalışır.
*   **Syscall'lar**, bu iki mod arasında güvenli bir geçişi ve iletişimi sağlayan köprülerdir.
*   Bir syscall yapmak için:
    1.  Syscall numarasını ilgili yazmaca koy (x64 için `RAX`).
    2.  Argümanları doğru sırayla diğer yazmaçlara koy.
    3.  Tetikleyici komutu çalıştır (x64 için `syscall`).
*   Shellcode, bağımsız ve küçük kalmak için C kütüphaneleri yerine doğrudan syscall'ları kullanır.

Artık syscall'ların nasıl çalıştığını teorik olarak anladığımıza göre, bir sonraki bölümde Linux x86-64 sistemlerde hangi syscall'ların olduğunu ve bunları nasıl kullanacağımızı pratik örneklerle göreceğiz.
