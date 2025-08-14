/*
 * calistirici.c
 * Amaç: Bir karakter dizisi olarak tanımlanmış shellcode'u
 *       belleğe yükleyip çalıştırmak için bir test ortamı sağlar.
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h> // Gerekli değil ama iyi bir alışkanlık

/*
 * Shellcode'umuzun makine kodu karşılığı.
 * Bu byte'lar "mov rax, 60; mov rdi, 0; syscall" Assembly kodundan üretilmiştir.
 * Bu diziyi kendi derlediğiniz shellcode ile değiştirebilirsiniz.
 * ÖNEMLİ: objdump çıktınıza göre bu byte dizisi farklılık gösterebilir!
 * Bu örnek, "mov eax, 0x3c" ve "mov edi, 0x0" komutlarını kullanan
 * bir derleyicinin çıktısıdır.
 *
 * \xb8\x3c\x00\x00\x00 -> mov eax, 60 (0x3c)
 * \xbf\x00\x00\x00\x00 -> mov edi, 0
 * \x0f\x05             -> syscall
 */
unsigned char shellcode[] = "\xb8\x3c\x00\x00\x00\xbf\x00\x00\x00\x00\x0f\x05";

int main() {
    printf("Shellcode test programi baslatildi.\n");
    printf("Shellcode bellege enjekte edilecek ve calistirilacak...\n");
    printf("Shellcode boyutu: %zu byte\n", sizeof(shellcode) - 1); // -1 null terminator içindir

    /*
     * Burası sihrin gerçekleştiği yer.
     * 1. Bir fonksiyon göstericisi (pointer) tanımlıyoruz. Bu gösterici,
     *    hiçbir argüman almayan ve hiçbir şey döndürmeyen bir fonksiyonu
     *    işaret edecek şekilde tanımlanır: void (*func)().
     *
     * 2. Bu göstericinin adresini, shellcode'umuzun bulunduğu karakter
     *    dizisinin başlangıç adresine eşitliyoruz. Bu tehlikeli bir
     *    tür dönüşümüdür (casting) ve normalde yapılmaz.
     *
     * 3. Göstericiyi bir fonksiyon gibi çağırıyoruz: func();
     *    Bu, CPU'ya "shellcode dizisinin başlangıcındaki adrese git ve
     *    oradaki byte'ları komut olarak çalıştırmaya başla" talimatını verir.
     */
    void (*calistir_shellcode)() = (void(*)())shellcode;
    calistir_shellcode();

    /*
     * Eğer shellcode'umuz (exit(0)) doğru çalışırsa, program bu satıra
     * HİÇBİR ZAMAN ulaşamaz, çünkü syscall programı sonlandırmıştır.
     * Bu satırı görüyorsanız, bir şeyler yanlış gitmiş demektir.
     */
    printf("HATA: Shellcode calistiktan sonra bu mesaj gorunmemeliydi!\n");

    return 1; // Hata durumunu belirtmek için 1 ile çık
}
