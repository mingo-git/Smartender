package main

import "app/internal/server"


func main() {
	a := app.App{}
	a.Initialize()
	a.Run()
}
