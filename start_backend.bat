@echo off

:: Navigate to Django project directory
cd transport_backend
echo Starting Django server...
start cmd /k "myenv\Scripts\activate.bat && python manage.py runserver 0.0.0.0:8000"

:: Open Django codebase with preferred editor (e.g., VS Code)
echo Opening Django project in VS Code...
start cmd /k "myenv\Scripts\activate.bat && code ."

