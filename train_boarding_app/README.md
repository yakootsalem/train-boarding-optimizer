# Train Boarding Optimizer — Flutter App

This Flutter application is part of the **IoT-based Train Boarding Optimizer** project, developed under the **Technion IoT Laboratory** guidelines.

It serves as the **user and operator interface** for the smart train-boarding system, providing real-time visualization and control of passenger flow data collected by ESP32 sensors.

---

## Overview

The app connects to a **Firebase Realtime Database**, where the ESP32 microcontrollers continuously update:
- Seat occupancy sensors
- Line/queue lengths
- Cabin capacity data

The app displays this data live, allowing users to:
- View each train cabin’s occupancy status  
- Monitor passenger boarding and offboarding  
- Assign passengers to optimal lines to minimize waiting time  
- Simulate train movement between stations

---

