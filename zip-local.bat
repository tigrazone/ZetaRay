@echo off
copy cb.bat bin\
copy cb-e.bat bin\
call b.bat
"C:\Program Files\7-Zip\7z.exe" a ZetaRay.zip  ./Assets/   ./bin/ -mmt -mx9
"C:\Program Files\7-Zip\7z.exe" d ZetaRay.zip bin/*.pdb bin/*.lib bin/*.exp
move /Y ZetaRay.zip j:\
