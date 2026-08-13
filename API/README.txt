R4OS API-Gruppen
================

Dieses Verzeichnis beschreibt die fachliche Zuordnung der aktuellen
oeffentlichen Schnittstellen. Die binaere Form steht unter ../ABI/.

ApiContract.json ist die zentrale, sprachneutrale Schema-Wahrheit. Sie
enthaelt Zielarchitektur, R4XStart, R4LQuery, alle neun Gruppen-IDs und die
283 physischen Slots der sechs Kernel-Gruppentabellen. Jeder Funktionsslot
besitzt einen Signatur-Typbaum mit Parameternamen und Rueckgabetyp.

Schema v11 zentralisiert 120 transitive Public-Payloadtypen samt
Zig-Defaultwerten,
Pointer-/Buffervertraege, vier SDK-only-Wurzeln von R4STD, deren Operationen,
oeffentliche Fehlerdomaenen, Konstanten und Limits. Alle 283 Slots und 115
R4STD-Operationen einschliesslich der Text-, Pfad- und Zeiterweiterungen tragen
Sichtbarkeit, Anforderungen, Statusdomaene,
Ownership, Buffer-, Blocking-, Timeout-, Cancel-, Threading-, Reentrancy-,
Callback-, Shutdown-, Close-, Output-, Seiteneffekt-,
Retry- und Sprachparitaetsregeln sowie die Profile console, desktop und
service mit Pflicht-/Optionalgruppen. R4STD, R4IMG und R4FONT sind in allen Profilen
als optionale Gruppen klassifiziert. Date, Time, Settings, Config und die
Rasterbild- und Schriftdekodierung bleiben tabellenlos. Docs/API/PayloadTypes.md und
OperationContracts.md sind
die deterministisch erzeugten lesbaren Referenzen.

ApiContractGen erzeugt daraus die produktive Zig-, Kernel- und C-Program-ABI,
sechs typisierte Kernelprovider, alle neun R4L-Query-/Gruppenidentitaeten,
Contractlayoutbloecke, API-Referenztabellen und Zig-/C-Conformance-Fixtures.
--check vergleicht alle Dateien bytegenau; normale Builds schreiben nicht.

ApiContract.baseline.json ist der bestaetigte interne 0.59.9-
Vergleichssnapshot.
ApiContractGen validiert interne Konsistenz, kanonische Bytes und append-only-
Kompatibilitaet. Normale Builds pruefen nur und schreiben keine Vertragsdatei.

Groups.txt ist die aktuelle Besitzermatrix. Die sechs Kernelgruppen sind
R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO und R4DEV. R4STD, R4IMG und R4FONT sind reine
R4L-Libraries ohne Kernel-Gruppentabelle.

Neue Funktionen werden zuerst einem fachlichen Besitzer zugeordnet.
Tabellen werden append-only erweitert. Consumer pruefen konkrete Felder mit
hasFn und verwenden keine pauschalen Versionsgates.

Werkzeug:

    Code/BuildTools/ApiContractGen/zig-out/bin/api-contract-gen.exe --check
    Code/BuildTools/ApiContractGen/zig-out/bin/api-contract-gen.exe --selftest
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Invoke-PayloadLayoutPreviewGate.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-ApiContractConformance05818.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-AppContractSemantics05819.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-TextPathTimeContract05820.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-TimeoutConcurrencyContract05821.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-AppEntryContract05822.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-StorageFacadeContract05823.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-GuiFacadeContract05824.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests/Gate/Run-ResourceFacadeContract05825.ps1

Ein Baseline-Update ist bewusst nur mit --write --baseline moeglich.
