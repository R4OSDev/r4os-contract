R4OS ABI
=========

Geltungsbereich
---------------

Die ABI-Dateien beschreiben die binaeren Grenzen zwischen R4M0-Modulen,
R4L-Systemlibraries, Kernel und Programmen. Zielarchitektur ist x86_64,
Little Endian, Pointergroesse 8 Byte. Oeffentliche Structs verwenden feste
Integerbreiten oder uintptr_t/usize an Pointerplaetzen.

Aktuelle Vertraege
------------------

R4M0.txt
  Containerformat fuer R4X, R4L, R4D und R4P.

R4XStart.txt
  Einstieg eines R4X-Programms, Startkontext und importierte
  Gruppentabellen.

R4LQuery.txt
  Exportierter Query-Anker einer R4L-Systemlibrary.

R4M0 Modularten
---------------

    1 = R4X
    2 = R4L
    3 = R4D
    4 = R4P
    5 = KernelProvider
    6 = reserviert fuer Kernelmodule

R4X-Laufzeit
------------

Ein aktuelles R4X exportiert R4XStart Version 1 und besitzt die Metadaten:

    r4x.start=r4xstart
    r4x.entry=R4XStart
    r4x.context=R4XStartContext

R4SYS:Query:1 ist der implizite Basisimport. Weitere Imports kommen
ausschliesslich aus module.R4MF.

Tabellen
--------

    R4SYS   v7   824 Byte
    R4DESK  v7   424 Byte
    R4DRAW  v1   216 Byte
    R4NET   v1   288 Byte
    R4AUDIO v1   184 Byte
    R4DEV   v4   280 Byte

Jede Tabelle beginnt mit magic, abi_version, size und flags. Danach folgen
Funktionszeiger und reservierte Slots in fester Reihenfolge. Der Consumer
prueft size bis zum benoetigten Feld und anschliessend den Zeiger auf ungleich
0. R4STD wird ueber R4LQuery importiert und besitzt keine Kernel-Tabelle.

Der normale Zig-SDK-Pfad loest die Imports einmal in program.Bundle auf.
Alle Gruppen-Contexts verwenden danach denselben feldbasierten Zugriff in
program.Context. Eine kuerzere, gueltige Tabelle darf vorhandene fruehe Felder
bereitstellen; Felder hinter size gelten als nicht vorhanden. Nullzeiger und
reservierte Tombstones sind ebenfalls keine aufrufbaren Funktionen.

r4xstart.Context und die rohen R4Sys-/R4Desk-/R4Draw-Typen sind nur fuer
Low-Level-ABI-, Loader- und gezielte Diagnosetests vorgesehen. Normale
Anwendungen und Services erzeugen keine parallelen Raw-Contexts.

Aenderungen
-----------

- Append-only fuer bestehende Tabellen.
- Keine Wiederverwendung reservierter Slots ohne neuen ausdruecklichen
  Vertrag.
- Keine implizite Typkonvertierung zwischen C- und Zig-Payloads.
- Neue Majorversion nur bei bewusst inkompatiblem Vertrag.
- Neue Minorversion darf aeltere Consumer nicht allein wegen ihrer Zahl
  ausschliessen.

Maschinelle Abnahme
-------------------

    Tests/Gate/Invoke-CurrentApiContractGate.ps1 -Source
    Tests/Gate/Invoke-CurrentApiContractGate.ps1 -SelfTest
