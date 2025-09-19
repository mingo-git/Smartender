▌Hallo, hier diesem Ordner siehst du 3 Programme, welche in Verbindung alle einen Cocktail automaten steuern, genannt haben wir diesen
▌"Smartender", Das Frontend ist eine Flutter App, das Backend ein Server von mir selbst gehostet und das programm starten wir immer
▌per docker-compose. Die Hardware läuft auf einem Raspberry Pi Zero 2 W.
▌
▌Folgende Verbesserungen sind gewünscht bitte erstelle dafür einen Plan für die Umsetzung den wir nach und nach abarbeiten können,
▌bitte dokumentiere diesen Plan als Markdown File in unserem jetzigen Root Ordner mit dem namen "implementierung.md" bitte schau dir
▌den Code den wir bereits haben gut an. Hier sind die Punkte die wir verbessern möchten:
▌
▌
▌1. in der Flutter app gibt es unter Maintenance die noch nicht fertige implementierung Flush single slot, diese soll die 6 Pumpen
▌wiederspiegeln in Kacheln 2 breit 3 nach unten mit der Beschriftung "Pumpe 1-6" sobald die taste gedrückt wird soll solange sie
▌gehalten wird die pumpe angesprochen werden und es soll gepumpt werden, damit man nach dem gebrauch der maschine die maschine
▌durchspühlen kann.
▌2. Kommentiere die funktion Flush complete system zunächst aus, lösche Sie aber noch nicht, sie soll aber nicht mehr in der App
▌erscheinen solange sie nicht richtig implementiert wird (ist zukuenftig geplant)
▌3. Über Light Settings sollen die LEDs angesprochen werden bitte schaffe sowohl in der App, dem Backend und der Hardware die
▌vorraussetzungen, dass die Lichter beliebig eingestellt werden können. Auch mit aus und an machen der Lichter
▌4. In der Hardware ist eine Waage verbaut und testcode dafür gibt es auch schon, bitte zeige mir wie ich diesen Testcode ausführen
▌kann und wie wir es schaffen die Waage benutzen zu können um die völle des Getränks zu ermitteln, Sobald gestartet wird soll sich die
▌waage nullen und beim füllvorgang ermitteln wie lange der Piston und die Pumpen pumpen müssen um die richtige menge im becher zu
▌haben
▌5. Zeige mir wie ich mehrere Getränke als Standard anlegen kann, bisher sind nur 3 Getränke als Standard drinks hinterlegt
▌6. Zeige mir wo ich die geschwindigkeit des Stepper motors erhöhen kann damit das getränke abfüllen schneller geht (nicht
▌implementiern da ich die geschwindigkeit selbst stück für stück erhöhen möchte)
▌7. Der Piston Motor wird aktuell über Relais geschalten die die Polung umkehren damit er sowohl aus als auch einfahren kann, dies
▌führt aber dazu das das system kurzzeitig spannungspitzen hat was zu fehlern führ hierfür habe ich 2 Motor driver parat, welchen
▌sollte ich nutzen und wie wird es am besten implementiert, bitte schreibe auch hierfür einen kleinen test um die steuerung zu testen
▌(Driver sind:
▌Dual Channel 5–12 V DC Motor Controller H Brücke 0 A-30 A Motortreibermodul Zubehöraustausch und/oder DAOKAI BTS7960 Stepper Motor
▌Driver Modul 43A Dual H-Bridge Current Limit Control Semiconductor Refrigeration PWM Hohe Energie Doppel-DC Smart Car Driver Modul
▌für Arduino) Motor ist der: DC 12V 750N Linearantrieb 50mm 100mm 150mm 200mm 250mm 300mm Hub Linearantrieb Elektromotor Linearmotor
▌10mm/s Geschwindigkeit