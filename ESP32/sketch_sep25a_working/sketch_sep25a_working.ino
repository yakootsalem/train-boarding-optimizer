// ===================== USER PINS =====================
#define TRIG1 5
#define ECHO1 18
#define TRIG2 19
#define ECHO2 21

// Seat threshold (<= cm means occupied). Tune per seat geometry.
const int OCCUPIED_THRESHOLD_CM = 80;

// Cabin key must match your app's keys: A, B, C, D, E, F
static const char* CABIN_KEY = "A";
static const char* SEAT1_ID = "seat01";
static const char* SEAT2_ID = "seat02";

// ===================== ENABLES / LIBS =====================
#define ENABLE_USER_AUTH
#define ENABLE_DATABASE
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>

// ===================== Wi-Fi Configuration =====================
// ⚙️ Replace these placeholders with your own Wi-Fi network credentials.
// Example:
//   #define WIFI_SSID     "MyHomeWiFi"
//   #define WIFI_PASSWORD "MyStrongPassword"
#define WIFI_SSID     "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"


// ===================== Firebase Configuration =====================
// ⚙️ Replace the following values with your own Firebase project credentials.
// You can find them in your Firebase Console under Project Settings → General → Web API Key
// and from your Realtime Database URL (e.g., https://your-project-id.firebaseio.com/)
#define WEB_API_KEY   "YOUR_FIREBASE_WEB_API_KEY"
#define DATABASE_URL  "https://your-project-id-default-rtdb.region.firebasedatabase.app/"

// ⚙️ Replace with your Firebase Authentication email and password
// (Used by the ESP32 to log in and access the database)
#define USER_EMAIL    "YOUR_FIREBASE_USER_EMAIL"
#define USER_PASS     "YOUR_FIREBASE_USER_PASSWORD"


// ===================== Firebase objects =====================
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
FirebaseApp app;
RealtimeDatabase Database;
UserAuth user_auth(WEB_API_KEY, USER_EMAIL, USER_PASS);

// ===================== Ultrasound helpers =====================
static inline unsigned long pingUS(uint8_t trigPin, uint8_t echoPin) {
  digitalWrite(trigPin, LOW);  delayMicroseconds(3);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  return pulseIn(echoPin, HIGH, 40000UL);  // 40ms timeout
}

static float distanceCM(uint8_t trigPin, uint8_t echoPin) {
  // Median of 3 to reduce spikes
  unsigned long d1 = pingUS(trigPin, echoPin); delay(20);
  unsigned long d2 = pingUS(trigPin, echoPin); delay(20);
  unsigned long d3 = pingUS(trigPin, echoPin);
  unsigned long a=d1,b=d2,c=d3,t;
  if (a>b){t=a;a=b;b=t;} if (b>c){t=b;b=c;c=t;} if (a>b){t=a;a=b;b=t;}
  unsigned long dur = b;                // median
  if (dur == 0) return NAN;
  return dur / 58.0f;                   // µs → cm
}

// ===================== Firebase callback =====================
void processData(AsyncResult &aResult) {
  if (!aResult.isResult()) return;
  if (aResult.isError()) {
    Serial.printf("ERR %s: %s (%d)\n",
                  aResult.uid().c_str(),
                  aResult.error().message().c_str(),
                  aResult.error().code());
  } else if (aResult.available()) {
    Serial.printf("OK %s: %s\n",
                  aResult.uid().c_str(),
                  aResult.c_str());
  }
}

// ===================== Write helpers =====================
// Seat diagnostics (does NOT affect the app UI)
void writeSeatDetail(const char* seatId, bool occupied, float dist) {
  char base[128];
  snprintf(base, sizeof(base), "/train/cabins_detail/%s/seats/%s", CABIN_KEY, seatId);

  char pOcc[160], pDist[160], pTs[160];
  snprintf(pOcc,  sizeof(pOcc),  "%s/occupied",     base);
  snprintf(pDist, sizeof(pDist), "%s/distance_cm",  base);
  snprintf(pTs,   sizeof(pTs),   "%s/updated_ms",   base);

  char uidOcc[24], uidDist[24], uidTs[24];
  snprintf(uidOcc, sizeof(uidOcc), "occ_%s", seatId);
  snprintf(uidDist, sizeof(uidDist), "dst_%s", seatId);
  snprintf(uidTs,  sizeof(uidTs),  "ts_%s",  seatId);

  Database.set<bool>(aClient,  pOcc,  occupied,            processData, uidOcc);
  Database.set<float>(aClient, pDist, dist,                processData, uidDist);
  Database.set<uint64_t>(aClient, pTs, (uint64_t)millis(), processData, uidTs);
}

// This is what the Flutter app reads: /train/cabins/A = <int>
void writeCabinTotal(int total) {
  char path[64];
  snprintf(path, sizeof(path), "/train/cabins/%s", CABIN_KEY);
  Database.set<int>(aClient, path, total, processData, "cabin_total");

  // Optional timestamp
  char tsPath[80];
  snprintf(tsPath, sizeof(tsPath), "/train/cabins_detail/%s/updated_ms", CABIN_KEY);
  Database.set<uint64_t>(aClient, tsPath, (uint64_t)millis(), processData, "cabin_ts");
}

// ===================== Change-only state =====================
struct SeatState {
  bool valid = false;
  bool occupied = false;
  float lastDist = NAN;
};
SeatState s1, s2;
int lastTotal = -1;

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(150);

  pinMode(TRIG1, OUTPUT); digitalWrite(TRIG1, LOW);
  pinMode(ECHO1, INPUT);
  pinMode(TRIG2, OUTPUT); digitalWrite(TRIG2, LOW);
  pinMode(ECHO2, INPUT);

  // Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  Serial.print("Connecting Wi-Fi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(300); Serial.print("."); }
  Serial.printf(" connected. IP=%s\n", WiFi.localIP().toString().c_str());

  // Firebase
  ssl_client.setInsecure(); // dev only
  initializeApp(aClient, app, getAuth(user_auth), processData, "authTask");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Ready...");
}

// ===================== LOOP =====================
void loop() {
  app.loop();  // keep async engine alive

  static unsigned long lastSample = 0;
  unsigned long now = millis();
  if (now - lastSample < 800) return;  // ~1.25 Hz sampling
  lastSample = now;

  // ---- Seat 1 ----
  float d1 = distanceCM(TRIG1, ECHO1);
  if (!isnan(d1)) {
    bool occ1 = (d1 <= OCCUPIED_THRESHOLD_CM);
    if (!s1.valid || s1.occupied != occ1 || fabsf(s1.lastDist - d1) > 1.0f) {
      Serial.printf("[seat01] %.1f cm | occupied=%s\n", d1, occ1 ? "true" : "false");
      writeSeatDetail(SEAT1_ID, occ1, d1);
      s1.valid = true; s1.occupied = occ1; s1.lastDist = d1;
    }
  } else {
    Serial.println("[seat01] No echo / out of range");
  }

  // ---- Seat 2 ----
  float d2 = distanceCM(TRIG2, ECHO2);
  if (!isnan(d2)) {
    bool occ2 = (d2 <= OCCUPIED_THRESHOLD_CM);
    if (!s2.valid || s2.occupied != occ2 || fabsf(s2.lastDist - d2) > 1.0f) {
      Serial.printf("[seat02] %.1f cm | occupied=%s\n", d2, occ2 ? "true" : "false");
      writeSeatDetail(SEAT2_ID, occ2, d2);
      s2.valid = true; s2.occupied = occ2; s2.lastDist = d2;
    }
  } else {
    Serial.println("[seat02] No echo / out of range");
  }

  // ---- Cabin aggregate sent to the exact key the app uses ----
  if (s1.valid || s2.valid) {
    int total = (s1.valid && s1.occupied ? 1 : 0) + (s2.valid && s2.occupied ? 1 : 0);
    if (total != lastTotal) {
      Serial.printf("[cabin %s] total=%d\n", CABIN_KEY, total);
      writeCabinTotal(total);          // <-- writes /train/cabins/A = total
      lastTotal = total;
    }
  }
}
