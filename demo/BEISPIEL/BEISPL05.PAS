program Beispiel; {$X+} { Beispiel Nr.5 }

uses

	Gem,OTypes,OProcs,OWindows,ODialogs;

const

	{$I beispiel.i}

type

	TMyApplication = object(TApplication)
		procedure InitInstance; virtual;
		procedure InitMainWindow; virtual;
	end;

	PBeispielWindow = ^TBeispielWindow;
	TBeispielWindow = object(TWindow)
		Veraendert: boolean;
		Dicke,
		Farbe,
		Art       : integer;
		Pfad,
		Datei     : string;
		constructor Init(AParent: PWindow; ATitle: string);
		function CanClose: boolean; virtual;
		procedure WMButton(mX,mY,BStat,KStat,Clicks: integer); virtual;
		{ neue Methoden: }
		procedure SetAttr(Width,Color,Style: integer); virtual;
		procedure CreateTitle; virtual;
	end;

	PAttrDialog = ^TAttrDialog;
	TAttrDialog = object(TDialog)
		function OK: boolean; virtual;
		function Help: boolean; virtual;
	end;

	PLineData = ^TLineData;
	TLineData = record
		Farben: array [0..7] of integer;
		Stile : array [1..6] of integer;
		Breite: string[5]
	end;

	PAbout  = ^TAbout;
	TAbout  = object(TKeyMenu)
		procedure Work; virtual;
	end;

	PNew    = ^TNew;
	TNew    = object(TKeyMenu)
		procedure Work; virtual;
	end;

	POpen   = ^TOpen;
	TOpen   = object(TKeyMenu)
		procedure Work; virtual;
	end;

	PSave   = ^TSave;
	TSave   = object(TKeyMenu)
		procedure Work; virtual;
	end;

	PSaveAs = ^TSaveAs;
	TSaveAs = object(TKeyMenu)
		procedure Work; virtual;
	end;

	PInfo   = ^TInfo;
	TInfo   = object(TKeyMenu)
		procedure Work; virtual;
	end;

	PAttrib = ^TAttrib;
	TAttrib = object(TKeyMenu)
		LineData: TLineData;
		procedure Work; virtual;
	end;

var

	MyApp: TMyApplication;


procedure MyResource; external; {$L beispiel.o}


procedure TMyApplication.InitInstance;

	begin
		InitResource(@MyResource,nil);
		LoadMenu(BSPMENU);
		new(PAbout,Init(@self,K_CTRL,Ctrl_A,MABOUT,MTITLE1));
		new(PNew,Init(@self,K_CTRL,Ctrl_N,MNEW,MTITLE2));
		new(POpen,Init(@self,K_CTRL,Ctrl_O,MOPEN,MTITLE2));
		new(PSave,Init(@self,K_CTRL,Ctrl_S,MSAVE,MTITLE2));
		new(PSaveAs,Init(@self,K_CTRL,Ctrl_D,MSAVEAS,MTITLE2));
		new(PInfo,Init(@self,K_CTRL,Ctrl_I,MINFO,MTITLE3));
		new(PAttrib,Init(@self,K_CTRL,Ctrl_T,MATTR,MTITLE3));
		inherited InitInstance;
		SetQuit(MQUIT,MTITLE2)
	end;


procedure TMyApplication.InitMainWindow;

	begin
		new(PBeispielWindow,Init(nil,'Beispiel  [unbenannt]'));
		if (MainWindow=nil) or (ChkError<em_OK) then
			Status:=em_InvalidMainWindow
	end;


constructor TBeispielWindow.Init(AParent: PWindow; ATitle: string);

	begin
		if not(inherited Init(AParent,ATitle)) then fail;
		Veraendert:=false;
		SetAttr(3,Blue,LT_SOLID);
		Datei:='';
		Pfad:=''
	end;


function TBeispielWindow.CanClose: boolean;
	var valid: boolean;

	begin
		valid:=inherited CanClose;
		if valid and Veraendert then
			valid:=(Application^.Alert(@self,1,WAIT,
				' Die Grafik wurde ver�ndert!| Wollen Sie sie speichern?',
			  '&Ja|  &Nein  ')=2);
		CanClose:=valid
	end;


procedure TBeispielWindow.WMButton(mX,mY,BStat,KStat,Clicks: integer);
	var xalt,yalt,btn,dummy: integer;
	    pxyarray           : ptsin_ARRAY;

	begin
		if bTst(BStat,1) then
			if GetDC>=0 then
				begin
					wind_update(BEG_MCTRL);
					repeat
						xalt:=mX;
						yalt:=mY;
						repeat
							graf_mkstate(mX,mY,btn,dummy)
						until (mX<>xalt) or (mY<>yalt) or not(bTst(btn,1));
						pxyarray[0]:=xalt;
						pxyarray[1]:=yalt;
						pxyarray[2]:=mX;
						pxyarray[3]:=mY;
						v_pline(vdiHandle,2,pxyarray)
					until not(bTst(btn,1));
					wind_update(END_MCTRL);
					ReleaseDC;
					Veraendert:=true;
					CreateTitle
				end;
		if bTst(BStat,2) then
			begin
				ForceRedraw;
				Veraendert:=false;
				CreateTitle
			end
	end;


procedure TBeispielWindow.SetAttr(Width,Color,Style: integer);
	const farben: array [0..7] of string[7] =
		('wei�','schwarz','rot','gr�n','blau','t�rkis','gelb','violett');
				arten: array [1..6] of string[16] =
		('durchgehend','langer Strich','Punkte','Strich, Punkt',
		                             'Strich','Strich, 2 Punkte');

	begin
		Dicke:=Width;
		Farbe:=Color;
		Art:=Style;
		vsl_width(vdiHandle,Dicke);
		vsl_color(vdiHandle,Farbe);
		vsl_type(vdiHandle,Art);
		vsl_ends(vdiHandle,LE_ROUNDED,LE_ROUNDED);
		SetSubTitle(' Dicke: '+ltoa(Dicke)+'  Farbe: '+farben[Farbe]+
								'   Art: '+arten[Art])
	end;


procedure TBeispielWindow.CreateTitle;
	var titel: string;

	begin
		if length(Datei)=0 then titel:='[unbenannt]'
		else
			titel:=Pfad+Datei;
		if Veraendert then titel:='*'+titel;
		titel:='Beispiel  '+titel;
		SetTitle(titel)
	end;


function TAttrDialog.OK: boolean;
	var valid   : boolean;
	    d,f,s,vh: integer;
	    attrb   : ARRAY_4;

	begin
		valid:=inherited OK;
		if valid then
			begin
				vh:=Application^.MainWindow^.vdiHandle;
				with PLineData(TransferBuffer)^ do
					begin
						f:=0;
						while Farben[f]<>bf_Checked do inc(f);
						s:=1;
						while Stile[s]<>bf_Checked do inc(s);
						vsl_width(vh,atol(Breite))
					end;
				vql_attributes(vh,attrb);
				PBeispielWindow(Application^.MainWindow)^.SetAttr(attrb[3],f,s)
			end;
		OK:=valid
	end;


function TAttrDialog.Help: boolean;

	begin
		Application^.Alert(@self,1,NO_ICON,'In dieser Dialogbox werden die|Attribute der Linien eingestellt.|Die neuen Werte gelten ab der|ersten Linie, die nach dem|Schlie�en der Box gezeichnet|wird.','   &OK   ');
		Help:=false
	end;


procedure TAbout.Work;

	begin
		if ADialog=nil then
			begin
				new(ADialog,Init(nil,'�ber Beispiel',BSPABOUT));
				if ADialog<>nil then
					begin
						new(PGroupBox,Init(ADialog,IGROUP,'ObjectGEM '+
																'Beispielprogramm','"42"'));
						new(PButton,Init(ADialog,IOK,id_OK,true,'Mit diesem '+
											'Button|kann die Infobox|verlassen werden.'))
					end
			end;
		if ADialog<>nil then ADialog^.MakeWindow
	end;


procedure TNew.Work;

	begin
		with PBeispielWindow(Application^.MainWindow)^ do
			begin
				ForceRedraw;
				Veraendert:=false;
				Pfad:='';
				Datei:='';
				CreateTitle
			end
	end;


procedure TOpen.Work;

	begin
		Application^.Alert(nil,1,NOTE,'Die Funktion ist noch|'+
													'nicht implementiert.',' &Schade ')
	end;


procedure TSave.Work;

	begin
		Application^.Alert(nil,1,NOTE,'Die Funktion ist noch|'+
													'nicht implementiert.',' &Schade ')
	end;


procedure TSaveAs.Work;

	begin
		Application^.Alert(nil,1,NOTE,'Die Funktion ist noch|'+
													'nicht implementiert.',' &Schade ')
	end;


procedure TInfo.Work;

	begin
		Application^.Alert(nil,1,NOTE,'Die Funktion ist noch|'+
													'nicht implementiert.',' &Schade ')
	end;


procedure TAttrib.Work;
	var q: integer;

	begin
		if ADialog=nil then
			begin
				ADialog:=new(PAttrDialog,Init(nil,'Attribute',BSPATTR));
				if ADialog<>nil then
					begin
						new(PGroupBox,Init(ADialog,ACGROUP,'Farbe',
														'Bestimmt die|Linienfarbe'));
						new(PGroupBox,Init(ADialog,ASGROUP,'Stil',
														'Bestimmt den|Linienstil'));
						new(PRadioButton,Init(ADialog,AWHITE,true,
														'Setzt Wei� als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,ABLACK,true,
														'Setzt Schwarz als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,ARED,true,
														'Setzt Rot als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,AGREEN,true,
														'Setzt Gr�n als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,ABLUE,true,
														'Setzt Blau als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,ACYAN,true,
														'Setzt T�rkis als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,AYELLOW,true,
														'Setzt Gelb als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,AMAGENTA,true,
														'Setzt Violett als|neue Linienfarbe'));
						new(PRadioButton,Init(ADialog,ASOLID,true,
														'Setzt LT_SOLID als|neuen Linienstil'));
						new(PRadioButton,Init(ADialog,ALONG,true,
														'Setzt LT_LONGDASH als|neuen Linienstil'));
						new(PRadioButton,Init(ADialog,ADOTS,true,
														'Setzt LT_DOTTED als|neuen Linienstil'));
						new(PRadioButton,Init(ADialog,ALINEDOT,true,
														'Setzt LT_DASHDOT als|neuen Linienstil'));
						new(PRadioButton,Init(ADialog,ALINE,true,
														'Setzt LT_DASHED als|neuen Linienstil'));
						new(PRadioButton,Init(ADialog,ALIN2DOT,true,
														'Setzt LT_DASHDOTDOT|als neuen Linienstil'));
						new(PEdit,Init(ADialog,AWIDTH,5,
									'Gibt die Linien-|st�rke an (1,3,..).|Immer UNgerade!'));
						new(PButton,Init(ADialog,ACANCEL,id_Cancel,true,
							'Bricht den Dialog ab,|ohne die neuen Werte|zu �bernehmen'));
						new(PButton,Init(ADialog,AOK,id_OK,true,
													'Beendet den Dialog und|setzt die neuen Werte'));
						new(PButton,Init(ADialog,AHELP,id_Help,false,
							'Zeigt einen allgemeinen|Hilfstext �ber diesen|Dialog an.'));
						with PBeispielWindow(Application^.MainWindow)^ do
							with LineData do
								begin
									for q:=0 to 7 do Farben[q]:=bf_Unchecked;
									for q:=1 to 6 do Stile[q]:=bf_Unchecked;
									Farben[Farbe]:=bf_Checked;
									Stile[Art]:=bf_Checked;
									Breite:=ltoa(Dicke)
								end;
						ADialog^.TransferBuffer:=@LineData
					end
			end;
		if ADialog<>nil then ADialog^.MakeWindow
	end;


begin
	MyApp.Init('Beispiel');
	MyApp.Run;
	MyApp.Done
end.