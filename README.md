# AetherCore-Computer
Emulación del diseño de un computador con arquitectura John von Neumann.
El computador cuenta con un lenguaje assembly y un ensamblador que permite programarlo.


## Generar programa binario
Primero compilamos el assembler con
```sh
gcc assembler.c cpu.c -o assembler
```
Luego escribimos el código assembly en algún archivo (llamémoslo program.txt)
y generamos el programa binario (llamémoslo program.bin) con
```sh
./assembler program.txt program.bin
```

## Ejecutar simulacion del computador
Primero nos aseguramos de tener compilado el ejecutable del computador con el comando
```sh
gcc AetherComputer.c cpu.c memory.c -o AetherComputer
```
Y ahora lo ejecutamos con el siguiente comando
```sh
./AetherComputer
```
Por ahora el computador ejecutará el programa binario con nombre program.bin tan pronto
como inicie.

## Ejecución Analizador léxico

Es necesario tener instalado FLEX
- En Ubuntu/Debian
sudo apt-get install flex

- En macOS
brew install flex

- En Fedora/RHEL
sudo dnf install flex

Generar el código C desde el archivo Flex
```sh
flex lexer.l
```
→ crea: lex.yy.c

Compilar el código generado
```sh
gcc lex.yy.c main.c -o lexer -lfl
```
→ crea: lexer (ejecutable)

Ejecución:
```sh
./lexer test_lexer.txt
```
