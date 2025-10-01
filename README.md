# AetherCore-Computer
Diseño de computador bajo la arquitectura John von Neumann


# Generar programa binario
gcc assembler.c cpu.c -o assembler
./assembler program.txt program.bin

# Ejecutar simulacion del computador
gcc AetherComputer.c cpu.c memory.c -o AetherComputer
./AetherComputer
