Generierte Contract-Artefakte
=============================

Mit Ausnahme dieser Uebersicht werden alle Dateien unterhalb dieses
Verzeichnisses deterministisch aus `API/ApiContract.json` erzeugt und duerfen
nicht von Hand geaendert werden.

`SDK/Zig/`
  Vollstaendige Zig-ABI und ihr reines Exportpaket.

`SDK/C/include/r4os/`
  Vollstaendiger C-ABI-Header.

`Kernel/Zig/`
  Vollstaendige Kernel-ABI mit typisierten Providerbauern und Exportpaket.

`Groups/`
  Query- und Gruppenidentitaeten der sechs Plattformgruppen.

`Conformance/`
  Aus demselben Schema erzeugte Zig-/C-Kompilierfixturen.

`Docs/` und `Inventory/`
  Lesbare Tabellen, Semantik-/Paritaetsberichte und Maschineninventar.

`zig build check` prueft jede Datei bytegenau. `zig build write` darf nur nach
einer absichtlichen Schemaaenderung verwendet werden.
