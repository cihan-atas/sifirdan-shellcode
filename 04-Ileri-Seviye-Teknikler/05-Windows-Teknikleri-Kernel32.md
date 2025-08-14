# Bölüm 12: Windows Tekniği - Kernel32'nin Sırlarını Çözmek

Linux shellcode'unda hayat nispeten basittir: sabit bir syscall numarasını bilir, argümanları yazmaçlara koyar ve `syscall`'u çağırırsınız. Windows'ta ise bu lükse sahip değiliz. ASLR (Address Space Layout Randomization) ve DLL'lerin farklı versiyonları nedeniyle `LoadLibraryA` veya `GetProcAddress` gibi kritik fonksiyonların adreslerini önceden bilemeyiz.

Bu yüzden Windows shellcode'unun ilk görevi bir dedektif gibi çalışarak bu fonksiyonların adreslerini çalışma anında bulmaktır. Bu sürecin kalbinde ise `kernel32.dll` yatar.

## Yol Haritası: Hedef `GetProcAddress`

Nihai amacımız, herhangi bir fonksiyonun adresini sadece ismini kullanarak bulmamızı sağlayan `GetProcAddress` fonksiyonunun adresini ele geçirmektir. `GetProcAddress`'in kendisi de `kernel32.dll` içinde bulunur. Dolayısıyla yol haritamız şöyledir:

1.  **`kernel32.dll`'in Yüklü Olduğu Adresi (Base Address) Bul.**
2.  **`kernel32.dll`'in Dışa Aktarma Tablosunu (Export Address Table - EAT) Bul.**
3.  **Bu Tabloyu Tarayarak `GetProcAddress`'in Adresini Bul.**
4.  (İsteğe bağlı) Aynı yöntemle `LoadLibraryA`'nın da adresini bulmak, diğer DLL'leri (`ws2_32.dll` gibi) yüklemek için gereklidir.

## Adım 1: `kernel32.dll`'in Adresini Bulmak (PEB Üzerinden)

Windows'ta her sürecin (process), hakkında bir ton bilgi içeren **PEB (Process Environment Block)** adında bir veri yapısı vardır. PEB'e, `FS` (32-bit'te) veya `GS` (64-bit'te) segment yazmacı üzerinden erişilebilir.

PEB'in içinde, sürece yüklenmiş olan tüm DLL'lerin listesini tutan `Ldr` adında bir pointer bulunur. Bu liste (genellikle `InMemoryOrderModuleList`) çift yönlü bir bağlı listedir. `kernel32.dll` genellikle bu listedeki ikinci veya üçüncü elemandır.

Shellcode'un yapacağı şey şudur:
1.  `FS:[0x30]` (32-bit) veya `GS:[0x60]` (64-bit) ofsetinden PEB'in adresini al.
2.  PEB'den `Ldr` pointer'ını al.
3.  `Ldr`'dan modül listesini al.
4.  Bu bağlı listede `kernel32.dll`'i bulana kadar ilerle ve base adresini bir yazmaca kaydet.

Bu işlem, belirli ofsetleri ezbere bilmeyi gerektiren karmaşık bir Assembly rutinidir.

## Adım 2: Dışa Aktarma Tablosunu (EAT) Bulmak

`kernel32.dll`'in (ve her DLL/EXE'nin) yapısı **PE (Portable Executable)** formatındadır. Bu formatın içinde, o dosyanın dışarıya hangi fonksiyonları sunduğunu listeleyen tablolar bulunur.

`kernel32.dll`'in base adresini bulduktan sonra, PE başlıklarını okuyarak Dışa Aktarma Tablosu'nun (Export Address Table - EAT) adresini bulmamız gerekir.

Süreç:
1.  Base adresten **DOS Header**'ı oku.
2.  DOS Header'ın sonundaki `e_lfanew` alanından **NT Headers**'ın ofsetini bul.
3.  NT Headers'tan **Optional Header**'a geç.
4.  Optional Header'ın içindeki **Data Directory**'den **Export Directory**'nin adresini ve boyutunu al. İşte bu bizim EAT'mizdir.

## Adım 3: EAT'ı Tarayarak Fonksiyon Adresini Bulmak

EAT'ın yapısı biraz karmaşıktır ve üç ana tablodan oluşur:
1.  **AddressOfFunctions:** Fonksiyonların gerçek adreslerini (daha doğrusu RVA - Relative Virtual Address) tutan bir dizi.
2.  **AddressOfNames:** Fonksiyonların isimlerini (string) gösteren pointer'ları tutan bir dizi.
3.  **AddressOfNameOrdinals:** İsim dizisi ile adres dizisi arasında bir köprü kuran, indisleri (ordinal) tutan 2 byte'lık bir dizi.

Shellcode'umuzun `GetProcAddress`'i bulmak için yapacağı şey şudur:

1.  **Fonksiyon İsimleri Dizisinde (`AddressOfNames`) Döngüye Başla:** İlk isimden başlayarak tüm isimleri tek tek kontrol et.
2.  **İsimleri Karşılaştır:** Her bir fonksiyon ismini, aradığımız "GetProcAddress" string'i ile karşılaştır.
    *   **Önemli:** Shellcode'un içinde "GetProcAddress" gibi bariz bir string bulundurmak tespiti kolaylaştırır. Bu yüzden profesyonel shellcode'lar bu string'in bir **hash**'ini (örneğin ROR13 hash'i) saklar ve tarama yaparken her fonksiyon isminin hash'ini alıp kendi hash'i ile karşılaştırır. Bu, hem shellcode'u küçültür hem de gizler.
3.  **Doğru İsmi Bulunca İndisi Al:** "GetProcAddress" string'ini (veya hash'ini) bulduğumuzda, döngüdeki mevcut **indisimizi** (örneğin 10. sırada bulduysak, indis 9'dur) not alırız.
4.  **Ordinal Tablosuna Git:** `AddressOfNameOrdinals` tablosunda bu indise karşılık gelen değeri (ordinal) okuruz.
5.  **Adres Tablosuna Git:** Son olarak, `AddressOfFunctions` tablosunda bu ordinal'e karşılık gelen RVA'yı (göreli sanal adres) okuruz.
6.  **Gerçek Adresi Hesapla:** Bu RVA'yı, en başta bulduğumuz `kernel32.dll`'in base adresi ile topladığımızda, `GetProcAddress`'in bellekteki **gerçek mutlak adresini** elde etmiş oluruz!

Bu uzun ve zahmetli sürecin sonunda, elimizde artık sihirli bir anahtar vardır. `GetProcAddress`'i kullanarak, ihtiyacımız olan diğer tüm fonksiyonların (`LoadLibraryA`, `CreateProcessA`, `WinExec` vb.) adreslerini kolayca bulabilir ve Windows üzerinde istediğimiz işlemi yapabiliriz.



### Özet

Windows shellcode'u yazmak, bir define avına çıkmaya benzer:
- **Hazine Haritası:** PEB
- **İlk İpucu:** `kernel32.dll`'in base adresi
- **İkinci İpucu:** Export Address Table (EAT)
- **Hazine:** `GetProcAddress` ve `LoadLibraryA`'nın adresleri

Bu teknikler, Assembly, işletim sistemi yapıları (PEB) ve dosya formatları (PE) hakkında derin bir bilgi gerektirir. Bu nedenle Windows shellcode geliştirme, genellikle bu alandaki en zorlu konulardan biri olarak kabul edilir.
