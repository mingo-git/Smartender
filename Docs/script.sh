#!/bin/bash

# Array mit den Abschnittsnamen und Nummern
sections=(
  "02_technologischer_hintergrund"
  "03_anforderungen_und_konzept"
  "04_umsetzung_hardware"
  "05_backend_architektur_und_implementierung"
  "06_mobile_app_entwicklung"
  "07_integration_und_tests"
  "08_ergebnisse_und_bewertung"
  "09_fazit_und_ausblick"
  "10_anhang"
  "11_literaturverzeichnis"
)

# Abschnittstitel, die in den Dateien eingefügt werden sollen
titles=(
  "Technologischer Hintergrund und verwandte Arbeiten"
  "Anforderungen und Konzept"
  "Umsetzung der Hardware"
  "Backend-Architektur und Implementierung"
  "Mobile App-Entwicklung"
  "Integration und Tests"
  "Ergebnisse und Bewertung"
  "Fazit und Ausblick"
  "Anhang"
  "Literaturverzeichnis"
)

# Hauptverzeichnis, in dem die Dateien erstellt werden sollen
output_dir="sections"

# Verzeichnis erstellen, falls nicht vorhanden
mkdir -p "$output_dir"

# Dateien erstellen
for i in "${!sections[@]}"; do
  filename="$output_dir/${sections[$i]}.tex"
  echo "Erstelle $filename ..."

  # Standardinhalt für die .tex-Dateien
  cat <<EOF >"$filename"
\section{${titles[$i]}}
% Hier folgt der Inhalt des Abschnitts "${titles[$i]}".
EOF
done

# LaTeX-Code für die Einbindung in die Main-Datei ausgeben
echo "LaTeX-Code für die Einbindung:"
for i in "${!sections[@]}"; do
  echo "\\input{sections/${sections[$i]}}    % ${titles[$i]}"
done
