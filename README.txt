R4OS Plattform-Contract
=======================

Dieses Repository ist die zentrale API-/ABI-Wahrheit der R4OS-Plattform.
Es beschreibt den gemeinsamen R4M0-, R4XStart- und R4L-Mechanismus sowie die
sechs vom Kernel bereitgestellten Plattformgruppen.

Wahrheit und Ausgaben
---------------------

- `API/ApiContract.json` ist das kanonische, sprachneutrale Schema.
- `API/ApiContract.baseline.json` ist der kontrollierte
  Append-only-Vergleichsstand.
- `ABI/` enthaelt die lesbaren Container-, Start- und Runtime-R4L-Vertraege.
- `Module/R4MFv2.txt` beschreibt das gemeinsame Modulmanifest.
- `Generated/` enthaelt die daraus erzeugten Zig-, Kernel- und C-Pakete,
  Conformance-Fixtures, Referenzdokumente und das API-Inventar.
- `Tools/ApiContractGen/` besitzt den Generator und seine Negativtests.

Nicht enthalten sind Kernelimplementierungen, handgeschriebene SDK-Fassaden,
Module oder fachliche Vertraege konkreter Runtime-R4Ls. Eine benannte
Runtime-R4L besitzt Implementierung, Contract, Baseline und Bindings
vollstaendig in ihrer eigenen Library-Einheit.

Build und Pruefung
------------------

Voraussetzung ist Zig 0.16.0 oder kompatibel.

    zig build
    zig build check
    zig build test

Ein normaler Build validiert und vergleicht nur; er schreibt keine
versionierte Datei. Nach einer absichtlichen Schemaaenderung materialisiert
`zig build write` die generierten Ausgaben. Ein bestaetigter neuer
Baseline-Stand wird ausschliesslich explizit erzeugt:

    zig build run -- --write --baseline

Verbraucher beziehen die passenden Dateien aus `Generated/` als explizite
Contract-Version. Sie erzeugen daraus keine zweite fachliche Wahrheit.
Zig-Builds beziehen das exportierte Modul `r4os_contract` und dessen
Namespace `abi`; fuer C-Builds exportiert das Paket den Include-Pfad
`r4os_contract_c_include`.

Die Herkunft des uebernommenen 0.64.9-Stands und die repo-neutrale Anpassung
sind in `PROVENANCE.txt` festgehalten.
