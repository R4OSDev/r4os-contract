R4OS ABI
========

Geltungsbereich
---------------

Die Dateien in diesem Verzeichnis beschreiben die binaeren Grenzen zwischen
R4M0-Modulen, Programmen, Runtime-R4Ls und Kernel. Ziel ist x86_64, Little
Endian, mit 8-Byte-Pointern und C-Aufrufkonvention.

Vertraege
---------

`R4M0.txt`
  Gemeinsames Containerformat fuer R4X, R4L, R4D und R4P.

`R4XStart.txt`
  Einstieg eines R4X-Programms, Startkontext und importierte
  Plattformtabellen.

`R4LQuery.txt`
  Generischer Query-Export eines R4L-Moduls.

`R4LInterface.txt`
  Versionierter Tabellenheader fuer unabhaengige, benannte Runtime-R4Ls.

Plattformtabellen
-----------------

R4SYS, R4DESK, R4DRAW, R4NET, R4AUDIO und R4DEV beginnen jeweils mit Magic,
ABI-Version, Groesse und Flags. Danach folgen Funktionszeiger und reservierte
Slots in fester Reihenfolge. Die aktuellen Werte und Tabellenfelder werden
aus `API/ApiContract.json` nach `Generated/Docs/API/` erzeugt.

Eine benannte Runtime-R4L besitzt dagegen keine zentrale Kernel-Tabelle. Sie
liefert eine libraryeigene, versionierte Funktionstabelle ueber den
gemeinsamen Query-/Interface-Mechanismus.

Aenderungen
-----------

- Bestehende Tabellen wachsen ausschliesslich am Ende.
- Reservierte oder tombstoned Slots werden nicht still umgedeutet.
- Fixed-layout-Typen werden nicht in-place erweitert.
- Extensible Typen folgen ihrem Versions- und Groessenvertrag.
- Zig- und C-Projektionen muessen binaer identisch bleiben.

Maschinelle Abnahme
-------------------

    zig build check
    zig build test

Die generierten Paketquellen, Layoutassertions und Conformance-Fixtures
liegen vollstaendig im Repository unter `Generated/`.
