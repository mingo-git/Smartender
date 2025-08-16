package models

type ResponseMsg struct {
	Type    LogLevel `json:"type"`
	Message string   `json:"message"`
}

type LogLevel string

const (
	Info    LogLevel = "INFO"
	Warn    LogLevel = "WARN"
	Error   LogLevel = "ERROR"
	Fatal   LogLevel = "FATAL"
	Success LogLevel = "SUCCESS"
)
