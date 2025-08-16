package query

func CreateHardwareForUser() string {
	return "INSERT INTO hardware (hardware_name, mac_address) VALUES ($1, $2) RETURNING hardware_id;"
}

func CreateUserHardware() string {
	return "INSERT INTO user_hardware (user_id, hardware_id, role) VALUES ($1, $2, $3);"
}

func GetAllHardwareForUser() string {
	return `SELECT
					h.hardware_id,
					h.hardware_name,
					h.mac_address,
					uh.user_id
				FROM
					hardware h
				LEFT JOIN
					user_hardware uh ON h.hardware_id = uh.hardware_id
				WHERE
					uh.user_id = $1
				GROUP BY
					h.hardware_id, h.hardware_name, h.mac_address, uh.user_id;`
}

func GetHardwareForUserByID() string {
	return `SELECT
					h.hardware_id,
					uh.user_id
				FROM
					hardware h
				LEFT JOIN
					user_hardware uh ON h.hardware_id = uh.hardware_id
				WHERE
					h.hardware_id = $1 AND uh.user_id = $2
				GROUP BY
					h.hardware_id, h.hardware_name, h.mac_address, uh.user_id;`
}

func GetHardwareForMAC_Adress() string {
	return `SELECT hardware_id FROM hardware WHERE mac_address = $1`
}
