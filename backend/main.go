package main

import "smartender/internal/app"

func main() {
	a := app.App{}
	a.Initialize()
	a.Run()
}
