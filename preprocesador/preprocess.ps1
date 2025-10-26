# Build and Run Preprocessor Script
# This script compiles and runs the C preprocessor

# Paths
$flexPath = "C:\Program Files (x86)\GnuWin32\bin"
$gccPath = "C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe"
$preprocessorDir = $PSScriptRoot

Write-Host "=== C Preprocessor Build & Run ===" -ForegroundColor Cyan

# Add Flex to PATH for this session
$env:Path += ";$flexPath"

# Change to preprocessor directory
Set-Location $preprocessorDir

# Step 1: Generate lexer from Flex file
Write-Host ""
Write-Host "[1/3] Generating lexer with Flex..." -ForegroundColor Yellow
flex preprocessor.l
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flex failed!" -ForegroundColor Red
    exit 1
}
Write-Host "OK - Lexer generated successfully" -ForegroundColor Green

# Step 2: Compile with GCC
Write-Host ""
Write-Host "[2/3] Compiling with GCC..." -ForegroundColor Yellow
& $gccPath lex.yy.c -o preprocessor.exe
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "OK - Compiled successfully" -ForegroundColor Green

# Step 3: Run preprocessor
Write-Host ""
Write-Host "[3/3] Running preprocessor..." -ForegroundColor Yellow
Set-Location input
..\preprocessor.exe main.c ..\output.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Preprocessor failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "OK - Preprocessing complete" -ForegroundColor Green
Write-Host "Done! Output saved to output.txt" -ForegroundColor Magenta
