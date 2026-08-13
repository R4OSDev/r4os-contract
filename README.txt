R4OS API- und ABI-Vertrag
==========================

Zweck
-----

Dieses Verzeichnis ist die zentrale Vertragsquelle fuer R4OS-Module und
oeffentliche Programmierschnittstellen. Es beschreibt ausschliesslich den
aktuell akzeptierten Vertrag. Historische Migrationen und entfernte APIs sind
keine Vertragsquelle.

Wahrheitsebenen
---------------

1. Maschinenlesbarer API-/ABI-Vertrag:
   API/ApiContract.json
2. Interne append-only-Drift-Baseline:
   API/ApiContract.baseline.json
3. Generierte Zig-, Kernel- und C-Program-ABI samt stabilen Fassaden:
   Code/System/SDK/r4os/abi_generated.zig und Code/System/SDK/r4os/abi.zig
   Code/Kernel/program/r4x_api_generated.zig und r4x_api.zig
   Code/System/SDK/Shared/C/include/r4os/abi_generated.h und abi.h
4. Kernelimplementierung und lesbare Providerzuordnung:
   Code/Kernel/program/r4x.zig sowie r4sys.zig bis r4dev.zig
5. Sprachbindungen:
   Code/System/SDK/r4os/ und Code/System/SDK/Shared/C/include/r4os/
6. Vertragsbeschreibung:
   dieses Verzeichnis
7. Generierte R4L-Identitaeten und Feldreferenz:
   Code/System/Libraries/*/src/api_contract_generated.zig
   Docs/API/R4SYS.md bis Docs/API/R4DEV.md
8. Generierte Payload-/Reachability-Referenz:
   Docs/API/PayloadTypes.md
9. Generierte Operationsmatrix und handgeschriebener App-Vertrag:
   Docs/API/OperationContracts.md und Docs/API/AppContract.md
10. Handgeschriebener Text-, Pfad- und Zeitvertrag:
   Docs/API/TextPfadZeitVertrag.md
11. Handgeschriebener SDK-App-Einstiegsvertrag:
   Docs/API/AppEntry.md
12. Handgeschriebener Storage-/Registry-Fassadenvertrag:
   Docs/API/StorageFacade.md
13. Handgeschriebener Fenster-/Nachrichten-/Zeichenfassadenvertrag:
   Docs/API/GuiFacade.md
14. Maschinenlesbar ausgewerteter Projekt-/Modulvertrag:
   Module/R4MFv2.txt, Code/BuildTools/ModuleCatalog/ und
   Inventory/Modules.json

ApiContract.json ist die zentrale Schema-Wahrheit. ApiContractGen erzeugt
daraus die produktive Zig-, Kernel- und C-Program-ABI, die Query-/Gruppenbasis
aller sieben R4L-Projekte, die Layoutbloecke der ABI-Contracts, die sechs
API-Referenztabellen und Zig-/C-Conformance-Fixtures. abi.zig, r4x_api.zig und
die C-Header bleiben Fassaden. Im Kernel werden die sechs Gruppentabellen
ueber generierte, exakt typisierte Provider gebaut; nur die Feld-zu-
Implementierung-Zuordnung bleibt handgeschrieben. Die Baseline ist nur ein
unveraenderlicher Vergleichsstand, keine zweite Quelle und keine externe
Kompatibilitaetszusage.

Dateien
-------

ABI/R4M0.txt
  Gemeinsamer Modulcontainer fuer R4X, R4L, R4D und R4P.

ABI/R4XStart.txt
  Startkontext, Import-Bundle und sechs Kernel-Gruppentabellen.

ABI/R4LQuery.txt
  Query-Export der R4L-Systemlibraries.

API/Groups.txt
  Fachliche Besitzer R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO, R4DEV und
  die tabellenlosen R4L-Libraries R4STD, R4IMG und R4FONT.

API/ApiContract.json
  Sprachneutrales Schema fuer R4XStart, R4LQuery, Gruppen, Slots und
  Signatur-Typbaeume sowie Public-Payloadtypen, Pointervertraege, tabellenlose
  SDK-Libraries, stabile Statusdomaenen, Operationssemantiken,
  Fehlerdomaenen, App-Profile, Konstanten und Limits. UTF-8 ohne BOM und kanonisch
  formatiert.

API/ApiContract.baseline.json
  Interner bestaetigter Vergleichssnapshot des aktuellen API-Vertrags.
  Aenderung nur kontrolliert ueber ApiContractGen --write --baseline.

Module/R4MFv2.txt
  Current-only Projekt-, Build- und Imagevertrag fuer R4X, R4L, R4D und R4P.
  Der gemeinsame Zig-Parser leitet fuer R4X Buildprofil, Artefakt, Export,
  Contracts und feste Startmetadaten ab.

Stabilitaetsregeln
------------------

- Bestehende Tabellenfelder werden nicht umsortiert oder umgedeutet.
- Neue Funktionsfelder werden nur am Tabellenende angefuegt.
- Reservierte Felder bleiben an ihrem Offset und werden mit 0 geliefert.
- Nutzbarkeit wird ueber Feldpraesenz und einen Funktionszeiger ungleich 0
  geprueft, nicht ueber Versionsraten.
- Oeffentliche Payload-Typen und Funktionssignaturen muessen in Kernel, Zig
  und C binaer identisch sein.
- Extensible Payloadtypen wachsen nur am Ende, mit Versions-/Groessenvertrag.
  Fixed-layout-Typen werden nicht in-place erweitert oder umsortiert.
- Pointer und Buffer besitzen Richtung, Nullability, Laengenbezug, Ownership
  und Lebensdauer. Hostabhaengige Typen duerfen keine ABI-Grenze kreuzen.
- module.R4MF ist die Import-, Export- und Build-Wahrheit eines Projekts.
- R4MF v2 deklariert R4SYS und alle weiteren Imports exakt; Profile oder
  Builder fuegen keine Gruppe hinzu und filtern keine deklarierte Gruppe weg.
- R4STD, R4IMG und R4FONT sind R4L-Libraries ohne Kernel-Gruppentabelle.
- Public-/Advanced-Operationen besitzen einen vollstaendigen Semantikvertrag
  und verlangen Zig-/C-Paritaet; reservierte/Tombstone-Slots bleiben intern.

Pruefung
--------

Build.bat ruft in jedem Build-/Imagepfad zuerst ApiContractGen --check auf.
Vor jedem Kernel- oder App-Build folgen permanent:

    Tests/Gate/Invoke-CurrentApiContractGate.ps1 -Source
    DevTools/Zig/zig.exe test Code/Kernel/program/r4x_start.zig

Das Gate prueft R4M0/R4XStart, alle module.R4MF, R4XStartContext,
Version/Groesse und die Feldreihenfolge aller sechs Tabellen zwischen Kernel,
Zig und C sowie das maschinenlesbare Schema. Payload-, Signatur-, Provider-,
R4L-, Contractlayout- und Conformance-Proben stammen aus derselben Quelle.
Weitere permanente Gates pruefen Operationssemantik, Statusrohcodes,
Handleinvalidierung, App-Profile, Text/Pfad/Zeit, Timeout/Cancel/Threading,
Storage, GUI, Ressourcenobjekte, Service/Netzwerk und Audio/Geraete jeweils in
Zig und C. Die maschinenlesbaren Mengen und Versionswerte werden nicht hier,
sondern in den generierten Referenzen festgehalten.
ApiContractGen wird als
BuildTool gebaut und schreibt bei normalen Builds nie:

    Code/BuildTools/ApiContractGen/zig-out/bin/api-contract-gen.exe --validate
    Code/BuildTools/ApiContractGen/zig-out/bin/api-contract-gen.exe --check
    Code/BuildTools/ApiContractGen/zig-out/bin/api-contract-gen.exe --selftest

--write erzeugt neben der kanonischen JSON-Datei alle genannten Artefakte.
--check vergleicht sie bytegenau und schreibt nichts. Einen separaten
regexbasierten API-Referenzgenerator gibt es nicht mehr.

ModuleCatalog wird ebenfalls als BuildTool gebaut. Die permanenten Gates

    Tests/Gate/Run-ModuleCatalogContract05828.ps1
    Tests/Gate/Run-CatalogAggregateContract05831.ps1
    Tests/Gate/Run-ManifestImageContract05832.ps1
    Tests/Gate/Run-R4CodeR4MFContract05833.ps1
    Tests/Gate/Run-R4CodePadR4MFContract05834.ps1
    Tests/Gate/Run-InTreeApiClosure05835.ps1

Sie pruefen den einen current-only Parser fuer alle vier Modularten, die
SDK-Profilbindung, deterministische Katalog-/Build-/Imageplaene,
case-insensitive Identitaets- und Zielkollisionen sowie den exakten Satz
begruendeter Low-Level-R4X. Der Builder uebernimmt Quellen, Entry-Modus,
App-Profil, gemeinsame Zig-Module, Imports und Metadaten aus R4MF v2; Imports
werden weder ergaenzt noch gefiltert. Root- und SDK-Smoke-Aggregat erzeugen
ihre R4X-Schritte direkt aus dem Katalog. R4D, R4P und R4L nutzen denselben
Parser und dieselbe Imagewahrheit. Projektlokale Builddateien bleiben nur fuer
echte Hosttests zulaessig und enthalten keine zweite Moduldefinition.

R4CODE, R4BUILD und ModuleCatalog verwenden denselben Runtimeparser und den
umgebungsneutralen `R4MF_PLAN=1`-Vertrag. R4CC akzeptiert in seinen
unterstuetzten C-Profilen den normalen C-App-Einstieg. R4CP ist kein Projekt-
oder Buildvertrag; der bewusst separate Importkonverter ist der einzige Leser
dieses externen Altformats. R4CodePad konsumiert fuer Plan und Build ebenfalls
ModuleCatalog statt einer eigenen Manifestsemantik.
