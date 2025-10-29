# AetherCore Computer - Build and Run Script

$gccPath = "C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe"

Write-Host "=== Building AetherCore Computer ===" -ForegroundColor Cyan

# Build the assembler
Write-Host "`nCompiling assembler..." -ForegroundColor Yellow
& $gccPath assembler.c cpu.c -o assembler.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Assembler compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Assembler compiled successfully!" -ForegroundColor Green

# Build the computer
Write-Host "`nCompiling AetherComputer..." -ForegroundColor Yellow
& $gccPath AetherComputer.c cpu.c memory.c -o AetherComputer.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AetherComputer compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "AetherComputer compiled successfully!" -ForegroundColor Green

# Check if program.txt exists
if (Test-Path "program.txt") {
    Write-Host "`nAssembling program.txt..." -ForegroundColor Yellow
    .\assembler.exe program.txt program.bin
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Assembly failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Program assembled successfully!" -ForegroundColor Green
} else {
    Write-Host "`nWARNING: program.txt not found. Skipping assembly." -ForegroundColor Yellow
    Write-Host "Create a program.txt file with assembly code to assemble it." -ForegroundColor Yellow
}

# Run the computer
Write-Host "`n=== Running AetherComputer ===" -ForegroundColor Cyan
.\AetherComputer.exe

Write-Host "`n=== Execution Complete ===" -ForegroundColor Cyan