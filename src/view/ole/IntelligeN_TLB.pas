unit IntelligeN_TLB;

// ************************************************************************ //
// WARNUNG
// -------
// Die in dieser Datei deklarierten Typen wurden aus Daten einer Typbibliothek
// generiert. Wenn diese Typbibliothek explizit oder indirekt (�ber eine
// andere Typbibliothek) reimportiert wird oder wenn der Befehl
// 'Aktualisieren' im Typbibliotheks-Editor w�hrend des Bearbeitens der
// Typbibliothek aktiviert ist, wird der Inhalt dieser Datei neu generiert und
// alle manuell vorgenommenen �nderungen gehen verloren.
// ************************************************************************ //

// $Rev: 17244 $
// Datei am 26.12.2012 23:28:24 erzeugt aus der unten beschriebenen Typbibliothek.

// ************************************************************************  //
// Typbib.: C:\Users\geskill\Documents\RAD Studio\Projekte\IntelligeN 2009\src\ole\IntelligeN (1)
// LIBID: {81C4A9A6-6D8E-4077-99DB-AD246E0FBD51}
// LCID: 0
// Hilfedatei:
// Hilfe-String:
// Liste der Abh�ng.:
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit muss ohne Typ�berpr�fung f�r Zeiger compiliert werden.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}
interface

uses Windows, ActiveX, Classes, Graphics, OleServer, StdVCL, Variants;

// *********************************************************************//
// In der Typbibliothek deklarierte GUIDS. Die folgenden Pr�fixe werden verwendet:
//   Typbibliotheken      : LIBID_xxxx
//   CoClasses            : CLASS_xxxx
//   DISPInterfaces       : DIID_xxxx
//   Nicht-DISP-Interfaces: IID_xxxx
// *********************************************************************//
const
  // Haupt- und Nebenversionen der Typbibliothek
  IntelligeNMajorVersion = 1;
  IntelligeNMinorVersion = 0;

  LIBID_IntelligeN: TGUID = '{81C4A9A6-6D8E-4077-99DB-AD246E0FBD51}';

  IID_IIntelligeN2009: TGUID = '{49828A90-6AD0-4451-A5B9-B5E999509D4D}';
  CLASS_IntelligeN2009: TGUID = '{33F80641-1EE9-4DB1-BD02-744B0FAFB085}';
type

// *********************************************************************//
// Forward-Deklaration von in der Typbibliothek definierten Typen
// *********************************************************************//
  IIntelligeN2009 = interface;
  IIntelligeN2009Disp = dispinterface;

// *********************************************************************//
// Deklaration von in der Typbibliothek definierten CoClasses
// (HINWEIS: Hier wird jede CoClass ihrem Standard-Interface zugewiesen)
// *********************************************************************//
  IntelligeN2009 = IIntelligeN2009;


// *********************************************************************//
// Interface: IIntelligeN2009
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {49828A90-6AD0-4451-A5B9-B5E999509D4D}
// *********************************************************************//
  IIntelligeN2009 = interface(IDispatch)
    ['{49828A90-6AD0-4451-A5B9-B5E999509D4D}']
    procedure openfile(const AFileName: WideString); safecall;
    procedure savefile(const AFileName: WideString); safecall;
    procedure close; safecall;
    procedure callcrawler; safecall;
    procedure callremoteupload; safecall;
    procedure callcheckdirectlinks; safecall;
    procedure callcrypter; safecall;
    procedure callpublish; safecall;
    function crawleractive: SYSINT; stdcall;
    function hostermanageractive: SYSINT; stdcall;
    function publishactive: SYSINT; stdcall;
  end;

// *********************************************************************//
// DispIntf:  IIntelligeN2009Disp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {49828A90-6AD0-4451-A5B9-B5E999509D4D}
// *********************************************************************//
  IIntelligeN2009Disp = dispinterface
    ['{49828A90-6AD0-4451-A5B9-B5E999509D4D}']
    procedure openfile(const AFileName: WideString); dispid 1;
    procedure savefile(const AFileName: WideString); dispid 2;
    procedure close; dispid 3;
    procedure callcrawler; dispid 5;
    procedure callremoteupload; dispid 6;
    procedure callcheckdirectlinks; dispid 7;
    procedure callcrypter; dispid 8;
    procedure callpublish; dispid 9;
    function crawleractive: SYSINT; dispid 10;
    function hostermanageractive: SYSINT; dispid 11;
    function publishactive: SYSINT; dispid 12;
  end;

// *********************************************************************//
// Die Klasse CoIntelligeN2009 stellt die Methoden Create und CreateRemote zur
// Verf�gung, um Instanzen des Standard-Interface IIntelligeN2009, dargestellt
// von CoClass IntelligeN2009, zu erzeugen. Diese Funktionen k�nnen
// von einem Client verwendet werden, der die CoClasses automatisieren
// will, die von dieser Typbibliothek dargestellt werden.
// *********************************************************************//
  CoIntelligeN2009 = class
    class function Create: IIntelligeN2009;
    class function CreateRemote(const MachineName: string): IIntelligeN2009;
  end;

implementation

uses ComObj;

class function CoIntelligeN2009.Create: IIntelligeN2009;
begin
  Result := CreateComObject(CLASS_IntelligeN2009) as IIntelligeN2009;
end;

class function CoIntelligeN2009.CreateRemote(const MachineName: string): IIntelligeN2009;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_IntelligeN2009) as IIntelligeN2009;
end;

end.

