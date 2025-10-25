# ESP32 Firmware — Train Boarding Optimizer

This folder contains the source code running on the **ESP32** microcontroller.  
The firmware uses two **HC-SR04 ultrasonic sensors** to detect if seats inside the train cabin are occupied,  
and it updates this information live in the **Firebase Realtime Database**, where the Flutter app reads and displays it.

---

## Overview

Each ESP32 unit corresponds to a **train cabin** (e.g., A, B, C...).  
It monitors 2 seats using ultrasonic distance sensors and calculates whether a seat is occupied based on a fixed **distance threshold (≤ 80 cm)**.

If a passenger is detected (object closer than 80 cm):
- The seat is marked as **occupied** in Firebase.
- The total cabin count is incremented.
- The app displays the live cabin occupancy in real time.

---

## Hardware Setup

| Component | ESP32 Pin | Description |
|------------|------------|-------------|
| HC-SR04 #1 (Trig) | D5 | Trigger pin for seat 1 |
| HC-SR04 #1 (Echo) | D18 | Echo pin for seat 1 |
| HC-SR04 #2 (Trig) | D19 | Trigger pin for seat 2 |
| HC-SR04 #2 (Echo) | D21 | Echo pin for seat 2 |
| VCC | 5 V | Power |
| GND | GND | Ground |

- Threshold: **80 cm**  
- Sample rate: ~1.25 Hz (every 800 ms)

---

## Wi-Fi & Firebase Configuration

Wi-Fi credentials, Firebase URL, and authentication details are defined in the file **`SECRETS.h`**,  
not directly inside the main `.ino` sketch.

Each user must **edit these values manually** before uploading the code:

```cpp
// In SECRETS.h:
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

const String ApiKey = "YOUR_FIREBASE_API_KEY";
const char* DATABASE_URL = "https://<your-project>.firebaseio.com/";
const char* USER_EMAIL = "your_firebase_user@email.com";
const char* USER_PASS  = "your_firebase_password";
