cd  /d  %~dp0
nakama --database.address postgres:password@127.0.0.1:5432 >> nakama.log 2>&1

pause