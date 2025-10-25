# Train Boarding Optimizer  
### Project by: **Yakoot Salem , Banan abu-helow , Qais Abu-shah**

---

## Details about the Project

The **Train Boarding Optimizer** is an IoT-based system designed to **optimize and simulate passenger boarding** in a train environment.  
It combines **ESP32 microcontrollers**, **ultrasonic sensors**, a **Firebase Realtime Database**, and a **Flutter application**.

The system uses ultrasonic sensors mounted on train seats to detect when a passenger sits down (distance < 80 cm).  
The ESP32 sends this data to Firebase, which is then visualized in real-time through a Flutter app that simulates train movement between two stations.

---

## Folder Description

| Folder | Description |
|---------|-------------|
| **ESP32/** | Source code for the ESP32 (firmware) that handles sensor readings and Firebase communication. |
| **Documentation/** | Contains the wiring diagram, hardware setup instructions, and Firebase configuration steps. |
| **Unit Tests/** | Tests for validating individual sensors and simulation logic (distance detection, app simulation). |
| **train_boarding_app/** | The Flutter application that visualizes cabin occupancy and simulates train trips between stations. |
| **Parameters/** | Contains descriptions of configurable constants and system parameters used in the firmware or app. |


---

## ESP32 SDK Version Used

- **ESP-IDF / Arduino Core for ESP32:** v2.0.x  
- **Arduino IDE:** v2.3.x  

---

## Arduino/ESP32 Libraries Used

| Library | Version | Description |
|----------|----------|-------------|
| **WiFi.h** | Built-in | Handles Wi-Fi connection. |
| **FirebaseClient** | v4.x.x | Connects ESP32 to Firebase Realtime Database. |
| **ArduinoJson** | v6.x.x | JSON parsing for Firebase requests. |
| **WiFiClientSecure.h** | Built-in | Handles HTTPS secure communication. |

---

## System Description

### ESP32 Firmware
- Each ESP32 board represents one **train cabin** (A, B, C…).
- It connects to **two HC-SR04 ultrasonic sensors**, one per seat.
- When an object is detected within **80 cm**, the seat is marked as **occupied**.
- Data is pushed to Firebase:
