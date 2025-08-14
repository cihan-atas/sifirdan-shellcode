# Bölüm 13: Araçlar - Shellcode Geliştiricinin Cephaneliği

Shellcode geliştirmek, doğru araçlar olmadan karanlıkta yol bulmaya benzer. Bu süreçte hata ayıklamak, kodu derlemek ve analiz etmek için çeşitli araçlara ihtiyacımız olacak. İşte bu yolculukta en iyi dostlarınız olacak temel araçlar:

## 1. Assembler'lar: Kodu Makine Diline Çevirenler

Assembly dilinde yazdığımız kaynak kodları, işlemcinin anlayacağı saf makine koduna (yani shellcode'a) çeviren programlardır.

*   **NASM (The Netwide Assembler)**
    *   **Nedir?** En popüler ve yaygın kullanılan x86/x86-64 assembler'larından biridir. Sözdizimi (syntax) basit ve anlaşılırdır. Bu repo'daki tüm örnekler NASM kullanılarak yazılmıştır.
    *   **Kurulum (Debian/Ubuntu):** `sudo apt-get install nasm`
    *   **Temel Kullanım:** `nasm -f <format> -o <output_file> <input_file.nasm>`
        *   `-f elf64`: 64-bit Linux için
        *   `-f elf32`: 32-bit Linux için
        *   `-f win32` / `-f win64`: Windows için

*   **YASM**
    *   **Nedir?** NASM projesinin yeniden yazılmış bir versiyonudur. NASM ile büyük ölçüde uyumludur ve bazı ek özellikler sunar. Tercihe bağlı olarak kullanılabilir.

## 2. Linker'lar: Parçaları Birleştirenler

Assembler'ın ürettiği nesne dosyalarını (`.o` uzantılı) alıp çalıştırılabilir bir program haline getiren araçlardır.

*   **`ld` (GNU Linker)**
    *   **Nedir?** GNU projesinin standart linker'ıdır. Linux sistemlerde varsayılan olarak bulunur.
    *   **Temel Kullanım:** `ld -o <executable_name> <object_file.o>`

## 3. Disassembler'lar ve Debugger'lar: Kodu Analiz Edenler

Bu araçlar, bir programın içini açıp nasıl çalıştığını Assembly seviyesinde görmemizi sağlar. Hata ayıklama ve shellcode'u ayıklama için vazgeçilmezdirler.

*   **`objdump` (Object Dump)**
    *   **Nedir?** Derlenmiş programlar hakkında bilgi gösteren bir komut satırı aracıdır. En çok, makine kodunu tekrar Assembly'ye çevirmek (disassemble) için kullanılır. Shellcode'umuzu ayıklamak için bu aracı kullandık.
    *   **Temel Kullanım:** `objdump -d <executable>`

*   **GDB (GNU Debugger)**
    *   **Nedir?** Linux'taki en güçlü komut satırı debugger'ıdır. Programları satır satır çalıştırmamıza, yazmaçların (register) değerlerini görmemize, belleği incelememize olanak tanır.
    *   **Geliştirilmiş Arayüzler:** GDB tek başına biraz "kaba" görünebilir. Bu yüzden onu çok daha kullanışlı hale getiren eklentiler kullanılır:
        *   **GEF (GDB Enhanced Features)**
        *   **Pwndbg**
        *   **PEDA (Python Exploit Development Assistance for GDB)**
    *   Bu eklentiler, GDB çalışırken stack'i, yazmaçları ve kodu aynı anda renkli ve düzenli bir şekilde göstererek hata ayıklamayı inanılmaz kolaylaştırır.

*   **`strace` ve `ltrace`**
    *   **`strace`:** Bir programın çalışırken yaptığı tüm **sistem çağrılarını (syscalls)** listeler. Bir programın arka planda ne yaptığını anlamak için harikadır.
    *   **`ltrace`:** Bir programın çalışırken çağırdığı **kütüphane fonksiyonlarını** listeler.

*   **IDA Pro / Ghidra**
    *   **Nedir?** Bunlar, GDB gibi dinamik analiz yerine **statik analiz** yapan, yani programı çalıştırmadan kodunu analiz eden çok gelişmiş "decompiler" ve disassembler'lardır. Özellikle büyük programları veya zararlı yazılımları tersine mühendislik (reverse engineering) için kullanılırlar. Ghidra, NSA tarafından geliştirilmiş ücretsiz bir alternatiftir.

*   **x64dbg**
    *   **Nedir?** Windows için modern, açık kaynaklı ve kullanıcı dostu bir debugger'dır. Windows üzerinde shellcode veya exploit geliştiriyorsanız mutlaka bilmeniz gereken bir araçtır.

## 4. Yardımcı Betikler ve Kütüphaneler

*   **Pwntools**
    *   **Nedir?** Python'da exploit geliştirmeyi ve CTF çözmeyi çok kolaylaştıran devasa bir kütüphanedir. Shellcode'u enjekte etme, process'lerle etkileşim kurma, Assembly/disassembly yapma gibi birçok özelliği bünyesinde barındırır.
    *   **Kurulum:** `pip install pwn`

