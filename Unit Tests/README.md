# Unit Tests — Train Boarding Optimizer

This folder contains validation tests for both the **hardware sensors (ESP32)** and the **software app (Flutter)**.

---

## Purpose
To verify that:
- The **ultrasonic sensor** correctly detects a passenger when the measured distance is **less than 80 cm** and updates Firebase accordingly.
- The **Flutter app** successfully reads the Firebase data and **simulates a round trip** between stations.

---

## Hardware Test (ESP32)
- The **HC-SR04 sensor** detects when someone sits on the chair.
- If the distance is **< 80 cm**, it counts that as **one passenger** and adds `+1` to the proper cabin in Firebase.
- When the seat becomes empty (> 80 cm), no new count is added until the next detection.
- you should use a proper ssd and password.

---

## Software Test (Flutter App)
- The app simulates a **train moving between stations** (e.g., A ↔ B).  
- Each trip takes **20 seconds** — this is only a **simulation value**, not a real duration.  
- When the train reaches the next station:
  - All passengers in all the lines are **reset to 0** and been assigned to the right capin of the train , and droping off the train randomly 20% of the passengers.  
  - Waiting passengers in station lines are boarded.  

---

