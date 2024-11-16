<h1>YatraMate</h1>
<img src="https://github.com/Ashish-Pandey62/YatraMate/blob/main/conductor_app/assets/trans.png" alt="YatraMate Logo" 
  style="border-radius: 50%; width: 100px; height: 100px; object-fit: cover;">
QR-Based Offline Cashless System for Public Transport


## Overview
YatraMate is an innovative, QR-based offline cashless system designed to enhance public transportation experiences by streamlining payments, reducing cash dependency, and providing real-time navigation using OpenStreetMap (OSM) data. Built using Flutter for cross-platform mobile applications and Django for the backend, this solution offers seamless integration, security, and scalability.
## Table of Contents
1.  Features
2.  System Architecture
3.  Tech Stack
4.  Installation
- Prerequisites
- Backend Setup (Django)
- Frontend Setup (Flutter)
5.  Deployment
6.  Contributing
7. Documentation
8.  Contact

# Features
- **Offline QR-Based Transactions:** Allows secure, cashless fare transactions without internet requirements.
- **Real-Time Navigation:** Integrates OSM data for route tracking and estimated arrival times.
- **Cross-Platform Mobile App:** Developed using Flutter for seamless performance on Android and iOS.
- **Django Backend:** Robust, scalable, and secure backend handling data, payments, and API integrations.
- **GPS Tracking:** Real-time tracking for better transparency in vehicle location.
## System Architecture
The architecture of YatraMate involves:

- **Frontend (Flutter):** A cross-platform mobile application for passengers and conductors to interact with the system.
- **Backend (Django):** Manages QR code generation, payment processing, real-time data updates, and secure API communication.
- **Database:** Stores user details, transactions, routes, and QR information.
- **OpenStreetMap Integration:** Provides real-time geographic data for route navigation.
## Tech Stack

- **Frontend:** Flutter
- **Backend:** Django (Python)
- **Database:** PostgreSQL (or any preferred database)
- **Mapping:** OpenStreetMap (OSM)
- **IDE:** Visual Studio Code



## Installation
**Prerequisites**

Ensure you have the following installed on your system:

- **Flutter:** [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Django:** [Install Django](https://docs.djangoproject.com/en/stable/topics/install/)
- **VS Code:**  [Install Visual Studio Code](https://code.visualstudio.com/)
- **Python 3.8+** and **pip**
- **Android Studio/Xcode** (for mobile emulators)

**Backend Setup (Django)**
1. Clone the repository:
```

git clone https://github.com/Ashish-Pandey62/KU_Hackfest/tree/main/transport_backend
```
2. Install dependencies:

```
pip install -r requirements.txt

```
3. Database Migrations:
```
python manage.py makemigrations
python manage.py migrate
```
4. Run the Django server:
```
python manage.py runserver
```
**Frontend Setup (Flutter)**
1. Clone the repository:
``` 
git clone https://github.com/Ashish-Pandey62/KU_Hackfest/tree/main/conductor_app

```
2. Install dependencies:
```
flutter pub get

```
3. Run the Flutter app:
- For Android:
```
flutter run
```
- For iOS (requires macOS):
```
flutter run
```
## Deployment

To deploy this project run

Flutter app for Android:
```bash
  flutter build apk --release

```
For ios:
```bash
 flutter build ios --release


```



## Contributing
We welcome contributions! Please follow these steps:

1. Fork the repository.
2. Create a new branch 
    ```
    git checkout -b feature/YourFeature
    ```
3. Commit your changes 
```
git commit -m 'Add some feature
```
4. Push to the branch 
```
git push origin feature/YourFeature
```
5. Create a new Pull Request.




## Documentation
Before setting up the **YatraMate** Flutter app, ensure you have the following tools installed on your machine:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) - Follow the official guide to install Flutter for your development environment.

## Contact
For more information or queries, feel free to contact us at
- anujagyawali000@gmail.com
