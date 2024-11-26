package query

// InitSlotsForHardware returns a query that initializes the slots table with the hardware_id and
// slot_number.
//
// Query-Parameters:
//   - $1 : hardware_id
//   - $2 : slot_number
//
// Returns:
//   - string : the query
func InitSlotsForHardware() string {
	return `INSERT INTO slots (hardware_id, slot_number, drink_id) VALUES ($1, $2, NULL)`
}

// GetAllSlotsForSelectedHardware returns a query that selects all slots from the slots table
//
// Query-Parameters:
//   - $1 : hardware_id
//
// Returns:
//   - string : the query
func GetAllSlotsForSelectedHardware() string {
	return `
	SELECT 
		hardware_id, 
		slot_number, 
		drink_id 
	FROM 
		slots 
	WHERE 
		hardware_id = $1 
	ORDER BY 
		slot_number`
}

func CheckHardwareForUser() string {
	return `SELECT * FROM user_hardware WHERE hardware_id = $1 AND user_id = $2 AND role = 'admin'`
}

// GetSlotForHardwareAndID returns a query that selects a slot from the slots table
//
// Query-Parameters:
//   - $1 : hardware_id
//   - $2 : slot_number
//
// Returns:
//   - string : the query
func GetSlotForHardwareAndID() string {
	return `SELECT * FROM slots WHERE hardware_id = $1 AND slot_number = $2`
}

// SetSlotForHardwareAndID returns a query that updates a slot from the slots table
//
// Parameters:
//   - $1 : drink_id
//   - $2 : hardware_id
//   - $3 : slot_number
//
// Returns:
//   - string : the query
func SetSlotForHardwareAndID() string {
	return `UPDATE slots SET drink_id = $1 WHERE hardware_id = $2 AND slot_number = $3`
}

// ClearSlotForHardwareAndID returns a query that clears a slot from the slots table
//
// Parameters:
//   - $1 : hardware_id
//   - $2 : slot_number
//
// Returns:
//   - string : the query
func ClearSlotForHardwareAndID() string {
	return `UPDATE slots SET drink_id = NULL WHERE hardware_id = $1 AND slot_number = $2`
}
