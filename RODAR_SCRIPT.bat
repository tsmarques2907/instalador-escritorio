@echo off
title Abrindo Instalador...
:: Executa o PowerShell como Administrador e passa o script .ps1 usando -File sem conflito de aspas
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoExit -File """%~dp0instalador_fea.ps1"""'"