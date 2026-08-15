R4OS API-Contract
=================

`ApiContract.json` ist die kanonische, sprachneutrale Wahrheit fuer
R4XStart, R4LQuery, die sechs Plattformgruppen, alle Slots, oeffentliche
Payloadtypen, Signaturen, Status- und Fehlerdomaenen, Konstanten, Limits und
Operationssemantiken.

`ApiContract.baseline.json` ist der bestaetigte interne Vergleichsstand. Er
ist keine zweite Quelle und wird nur gemeinsam mit einer bewusst akzeptierten
Contract-Aenderung aktualisiert.

ApiContractGen
--------------

Der repo-lokale Generator erzeugt deterministisch:

- Zig-ABI und Exportpaket fuer das SDK;
- Zig-ABI und Exportpaket fuer den Kernel;
- den C-ABI-Header;
- Zig-/C-Conformance-Fixtures;
- Gruppenidentitaeten und Tabellenreferenzen;
- Payload-, Operations- und Paritaetsdokumentation;
- das maschinenlesbare API-Inventar.

Alle Ausgaben liegen unter `Generated/`. `zig build check` vergleicht sie
bytegenau. `zig build test` fuehrt zusaetzlich die Generator-Negativtests aus
und kompiliert die generierten Zig-/C-Vertraege.

Besitzgrenze
------------

Das zentrale Schema kennt genau R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO und
R4DEV. Fachliche Tabellen benannter Runtime-R4Ls sind kein Bestandteil dieses
Schemas. Sie liegen mit Baseline, Bindings und Tests in der jeweiligen
Library-Einheit; gemeinsam ist nur der generische Mechanismus unter `ABI/`.

Bestehende Tabellen und fixed-layout-Payloads bleiben binaer stabil.
Erweiterungen erfolgen append-only; Consumer pruefen Feldgroesse und
Funktionszeiger statt pauschaler Versionszahlen.
