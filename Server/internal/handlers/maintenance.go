package handlers

import (
    "database/sql"
    "encoding/json"
    "log"
    "net/http"
)

// PerformMaintenance handles POST /api/user/maintenance
// It validates the payload, builds a maintenance message and forwards it to the
// corresponding hardware over the existing WebSocket connection.
func PerformMaintenance(db *sql.DB, w http.ResponseWriter, r *http.Request) {
    log.Default().Println("📬 [POST] /maintenance")

    // decode generically to allow forward-compat fields
    var body map[string]interface{}
    if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
        http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
        return
    }

    // Determine target hardware_id (optional in single-device mode)
    // If not provided, pick the first available connection.
    var hardwareID int
    if hwRaw, ok := body["hardware_id"]; ok {
        switch v := hwRaw.(type) {
        case float64:
            hardwareID = int(v)
        case int:
            hardwareID = v
        default:
            http.Error(w, "Invalid hardware_id", http.StatusBadRequest)
            return
        }
    } else {
        // pick first connection
        if len(hardwareConnections) == 0 {
            http.Error(w, "Hardware not connected", http.StatusNotFound)
            return
        }
        for id := range hardwareConnections {
            hardwareID = id
            break
        }
    }

    // maintenance_type can be used to normalize payload; optional here
    maintType, _ := body["maintenance_type"].(string)

    // optional user id from middleware
    if uid := r.Context().Value("user_id"); uid != nil {
        log.Default().Printf("👤 user_id=%v | hardware_id=%d | maintenance_type=%q", uid, hardwareID, maintType)
    } else {
        log.Default().Printf("👤 user_id=? | hardware_id=%d | maintenance_type=%q", hardwareID, maintType)
    }

    // Build maintenance message for hardware.
    // Start with an inner object and map a few common cases; fall back to pass-through.
    maintenance := map[string]interface{}{}

    switch maintType {
    case "manual_move":
        // X/Z values expected (range -100..100 in App)
        if x, ok := body["x"].(float64); ok {
            maintenance["x"] = x
        }
        if z, ok := body["z"].(float64); ok {
            maintenance["z"] = z
        }
        maintenance["type"] = "manual_move"
    case "emergency_stop":
        maintenance["type"] = "emergency_stop"
    case "light_mode":
        // forward as generic light command; include optional params
        if mode, ok := body["light_mode"].(string); ok {
            maintenance["mode"] = mode
        }
        if col, ok := body["color"].(string); ok { maintenance["color"] = col }
        if b, ok := body["brightness"].(float64); ok { maintenance["brightness"] = int(b) }
        if s, ok := body["speed_hz"].(float64); ok { maintenance["speed_hz"] = s }
        maintenance["type"] = "light"
    case "flush_all":
        maintenance["type"] = "flush_all"
    case "flush_slot":
        maintenance["type"] = "flush_slot"
        if slot, ok := body["slot_number"].(float64); ok {
            maintenance["slot_number"] = int(slot)
        }
    case "pump_hold":
        // optional: index + action
        maintenance["type"] = "pump"
        if idx, ok := body["pump_index"].(float64); ok {
            maintenance["index"] = int(idx)
        }
        if act, ok := body["action"].(string); ok {
            maintenance["action"] = act
        }
        log.Default().Printf("🪫 pump_hold idx=%v action=%v", maintenance["index"], maintenance["action"])
    default:
        // Forward unknown payload defensively
        // Copy everything except sensitive keys; still wrap into {maintenance: {...}}
        maintenance["type"] = maintType
        for k, v := range body {
            switch k {
            case "hardware_id":
                continue
            default:
                maintenance[k] = v
            }
        }
    }

    // Wrap as the message sent to hardware
    message := map[string]interface{}{"maintenance": maintenance}
    payload, err := json.Marshal(message)
    if err != nil {
        http.Error(w, "Failed to encode maintenance payload", http.StatusInternalServerError)
        return
    }

    // Lookup active hardware connection
    conn, exists := hardwareConnections[hardwareID]
    if !exists {
        log.Default().Printf("⚠️  Hardware %d not connected. Dropping maintenance: %s", hardwareID, string(payload))
        http.Error(w, "Hardware not connected", http.StatusNotFound)
        return
    }

    log.Default().Printf("➡️  Sending maintenance to HW %d: %s", hardwareID, string(payload))
    if err := conn.WriteMessage(1 /*Text*/, payload); err != nil {
        log.Default().Println("Failed to send maintenance message:", err)
        http.Error(w, "Failed to send maintenance message", http.StatusInternalServerError)
        return
    }
    log.Default().Printf("✅ Sent maintenance to HW %d", hardwareID)

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    _ = json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
