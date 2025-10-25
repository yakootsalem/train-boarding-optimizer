#ifndef _SECRETS_H
#define _SECRETS_H

// ===================== USER WIFI CONFIG =====================
// Replace with your local Wi-Fi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// ===================== FIREBASE / GOOGLE API CONFIG =====================
// Example placeholder (do not commit real keys)
const char* server = "speech.googleapis.com";

// Root certificate (optional, used for secure HTTPS)
const char* root_ca =
"-----BEGIN CERTIFICATE-----\n"
"YOUR_CERTIFICATE_CONTENT\n"
"-----END CERTIFICATE-----\n";

// Optional Google or Firebase API Key
const char* ApiKey = "YOUR_API_KEY_HERE";

#endif  // _SECRETS_H
