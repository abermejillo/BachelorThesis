:: # Command line commads to run simulation in batch with no prompts.
:: # Author: izpilab, gaudee, UPV/EHU
:: # Contact: inigo.arredondo@ehu.eus

:: Print date and time at start
date /T 
time /T 

:: Format time at start
set CUR_HH=%time:~0,2%
if %CUR_HH% lss 10 (set CUR_HH=0%time:~1,1%)
set CUR_NN=%time:~3,2%
set CUR_SS=%time:~6,2%

set FILENAME=solenoid_fe_log_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%CUR_HH%%CUR_NN%%CUR_SS%.txt

cd %~dp0

:: save the starting time
echo start:_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%CUR_HH%%CUR_NN%%CUR_SS% >> %FILENAME%

:: Execute simion script
simion-8.1.3.9-TEST-20190401.exe --nogui --noprompt fly solenoid_fe.iob | find /v "status2" | find /v "status" >> %FILENAME%
:: simion-8.1.3.9-TEST-20190401.exe --noprompt fly solenoid_fe.iob | find /v "status2" | find /v "status" >> %FILENAME%

:: Format time at end
set CUR_HH=%time:~0,2%
if %CUR_HH% lss 10 (set CUR_HH=0%time:~1,1%)
set CUR_NN=%time:~3,2%
set CUR_SS=%time:~6,2%

:: save the ending time
echo end:_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%CUR_HH%%CUR_NN%%CUR_SS% >> %FILENAME%

:: Print date and time at end
date /T 
time /T 
pause