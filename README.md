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
