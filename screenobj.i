uses
   classes,
   display;

type
   TScreenBlock = packed record
      Attribute:Byte;
      Character:Char;
   End;
   TVideoMem = Array of Array of TScreenBlock;
   TRegion = packed record
      Width:Word;
      Height:Word;
      Top:Word;
      Left:Word;
      Region:TVideoMem;
   End;

   PScreenObj = ^TScreenObj;
   TScreenObj = Class
      MaxHeight:Word;
      MaxWidth:Word;
      VideoMem:TVideoMem;
      SavedVideoMem:Array of TVideoMem;
      ClrScr:private procedure of object;
      ClrEol:private procedure of object;
      GotoXY:private procedure(X,Y:Word) of object;
      DelLine:private procedure of object;
      InsLine:private procedure of object;
      Window:private procedure(X,Y,W,H:Word) of object;
      RestoreWindow:private procedure of object;
      PrintCh:private procedure(Ch:Char) of object;
      Print:private procedure(S:String) of object;
      PrintLn:private procedure(S:String='') of object;
      GetChar:private function(X,Y:Word):Char of object;
      GetAttr:private function(X,Y:Word):Byte of object;
      SetAttr:private procedure(X,Y:Word;Attr:Byte) of object;
      RegionSave:private procedure(X,Y,W,H:Word;var Dest:TRegion) of object;
      RegionLoad:private procedure(var Source:TRegion) of object;
      WhereIsXY:private procedure(var X,Y:Word) of object;
   end;

Procedure TScreenObj.WhereIsXY(var X,Y:Word);
Begin
   X:=WhereX;
   Y:=WhereY;
End;

Procedure TScreenObj.RegionLoad(Var Source:TRegion);
var
   Loop,Loop2:LongInt;
   SavedX,SavedY:Word;
   SavedAttr:Byte;

Begin
   SavedX:=WhereX;
   SavedY:=WhereY;
   SavedAttr:=TextAttr;
   For Loop:=Source.Height-1 downto 0 do begin
      For Loop2:=0 to Source.Width-1 do begin
         System.GotoXy(Loop2+Source.Left,Loop+Source.Top);
         TextAttr:=Source.Region[Loop][Loop2].Attribute;
         PrintCh(Source.Region[Loop][Loop2].Character);
      End;
      SetLength(Source.Region[Loop],0);
      SetLength(Source.Region,Length(Source.Region)-1);
   End;
   Source.Width:=0;
   Source.Height:=0;
   System.GotoXy(SavedX,SavedY);
   TextAttr:=SavedAttr;
End;

Procedure TScreenObj.RegionSave(X,Y,W,H:Word;Var Dest:TRegion);
var
   Loop,Loop2:Word;

begin
   Dest.Top:=Y;
   Dest.Left:=X;
   Dest.Width:=Succ(W-X);
   Dest.Height:=Succ(H-Y);
//ClrScr;Write(X,'x',Y,': ',Dest.Width,' by ',Dest.Height); readkey;
   SetLength(Dest.Region,Dest.Height);
   For Loop2:=0 to Dest.Height-1 do
      SetLength(Dest.Region[Loop2],Dest.Width);
   For Loop:=0 to Dest.Height-1 do
      For Loop2:=0 to Dest.Width-1 do begin
//         GotoXy(1,23);Write(IntToStr(Loop)+' '+IntToStr(Loop2)+' '+IntToStr(Pred(Loop+X))+' '+IntToStr(Pred(Loop2+Y)));
         Dest.Region[Loop][Loop2].Attribute:=VideoMem[Pred(Loop+Y)][Pred(Loop2+X)].Attribute;
         Dest.Region[Loop][Loop2].Character:=VideoMem[Pred(Loop+Y)][Pred(Loop2+X)].Character;
      End;
//readkey;
end;

procedure TScreenObj.SetAttr(X,Y:Word;Attr:Byte);
var
   SavedX,SavedY:Word;
   SavedAttr:Byte;

begin
   SavedAttr:=TextAttr;
   SavedX:=WhereX;
   SavedY:=WhereY;
   VideoMem[Y-1][X-1].Attribute:=Attr;
   GotoXy(X,Y);
   TextAttr:=Attr;
   PipeWrite(VideoMem[Y-1][X-1].Character);
   TextAttr:=SavedAttr;
   GotoXy(SavedX,SavedY);
end;

function TScreenObj.GetAttr(X,Y:Word):Byte;
begin
   Result:=VideoMem[Y-1][X-1].Attribute;
end;

function TScreenObj.GetChar(X,Y:Word):Char;
begin
   Result:=VideoMem[Y-1][X-1].Character;
end;

procedure TScreenObj.PrintCh(Ch:Char);
Begin
   case Ch of
      #8:{absorb}; // inherit the X/Y
      #9:{absorb}; // inherit the X/Y
      #10:{absorb}; // inherit the X/Y
      #12:{absorb}; // inherit the X/Y
      #13:{absorb}; // inherit the X/Y
      else begin
         VideoMem[WhereY-1][WhereX-1].Attribute:=TextAttr;
         VideoMem[WhereY-1][WhereX-1].Character:=Ch;
      end;
   end;
   PipeWrite(Ch);
End;

procedure TScreenObj.Print(S:String);
var
   Loop:Longint;

Begin
   For Loop:=1 to Length(S) do PrintCh(S[Loop]);
end;

procedure TScreenObj.PrintLn(S:String);
Begin
   Self.Print(S);//
   Writeln();//+#13#10);
end;

procedure TScreenObj.RestoreWindow;
var
   Loop,Loop2:Longint;
   SavedAttr:Byte;
   SavedX,SavedY:Word;

begin
   System.Window(1,1,MaxWidth,MaxHeight);
   If Length(SavedVideoMem)=0 then exit;
   SavedAttr:=TextAttr;
   SavedX:=WhereX;
   SavedY:=WhereY;
   For Loop:=MaxHeight-1 downto 0 do begin
      System.GotoXy(1,Loop+1);
      For Loop2:=0 to MaxWidth-1 do begin
         TextAttr:=SavedVideoMem[High(SavedVideoMem)][Loop][Loop2].Attribute;
         PipeWrite(SavedVideoMem[High(SavedVideoMem)][Loop][Loop2].Character);
         VideoMem[Loop][Loop2].Attribute:=TextAttr;
         VideoMem[Loop][Loop2].Character:=SavedVideoMem[High(SavedVideoMem)][Loop][Loop2].Character;
      End;
      If Loop=MaxHeight-1 then begin
// compensate for scroll:
         System.GotoXy(1,Loop);
         System.InsLine;
      End;
   End;
// Deallocate Colums, Lines then Parent:
   SetLength(SavedVideoMem,Length(SavedVideoMem)-1);
   TextAttr:=SavedAttr;
   GotoXy(SavedX,SavedY);
end;

procedure TScreenObj.Window(X,Y,W,H:Word);
var
   Loop,Loop2:Longint;

begin
   System.Window(X,Y,W,H);
// extend saved:
   SetLength(SavedVideoMem,Length(SavedVideoMem)+1);
// allocate lines in saved:
   SetLength(SavedVideoMem[High(SavedVideoMem)], MaxHeight);
// allocate columns in saved:
   For Loop:=0 to MaxHeight-1 do
      SetLength(SavedVideoMem[High(SavedVideoMem)][Loop],MaxWidth);
// clone active memory:
   For Loop:=0 to MaxHeight-1 do begin
      For Loop2:=0 to MaxWidth-1 do begin
         SavedVideoMem[High(SavedVideoMem)][Loop][Loop2].Attribute:=VideoMem[Loop][Loop2].Attribute;
         SavedVideoMem[High(SavedVideoMem)][Loop][Loop2].Character:=VideoMem[Loop][Loop2].Character;
      End;
   End;
end;

procedure TScreenObj.InsLine;
var
   Loop,Loop2:Longint;

begin
   System.InsLine;
//
   For Loop:=MaxHeight-1 downto WhereY-2 do begin
      For Loop2:=0 to MaxWidth-1 do begin
         VideoMem[Loop][Loop2].Attribute:=VideoMem[Loop-1][Loop2].Attribute;
         VideoMem[Loop][Loop2].Character:=VideoMem[Loop-1][Loop2].Character;
      End;
   End;
   For Loop:=0 to MaxWidth-1 do begin
      VideoMem[WhereY-1][Loop].Attribute:=System.TextAttr;
      VideoMem[WhereY-1][Loop].Character:=#32;
   End;
end;

procedure TScreenObj.DelLine;
var
   Loop,Loop2:Longint;

Begin
   System.DelLine;
//
   If WhereY<MaxHeight then begin
      For Loop:=WhereY-1 to MaxHeight-2 do begin
         For Loop2:=0 to MaxWidth-1 do begin
            VideoMem[Loop][Loop2].Attribute:=VideoMem[Loop+1][Loop2].Attribute;
            VideoMem[Loop][Loop2].Character:=VideoMem[Loop+1][Loop2].Character;
         End;
      End;
   end;
   For Loop:=0 to MaxWidth-1 do begin
      VideoMem[WhereY-1][Loop].Attribute:=System.TextAttr;
      VideoMem[WhereY-1][Loop].Character:=#32;
   End;
end;

procedure TScreenObj.GotoXy(X,Y:Word);
begin
   System.GotoXy(X,Y)
end;

procedure TScreenObj.ClrEol;
var
   Loop:Longint;

Begin
   System.ClrEol;
   For Loop:=WhereX to MaxWidth-1 do begin
      VideoMem[WhereY-1][Loop].Attribute:=System.TextAttr;
      VideoMem[WhereY-1][Loop].Character:=#32;
   End;
end;

procedure TScreenObj.ClrScr;
var
   Loop,Loop2:Longint;

begin
   System.ClrScr;
// Adds 0.02s to this call:
   For Loop:=0 to MaxHeight-1 do
      For Loop2:=0 to MaxWidth-1 do begin
         VideoMem[Loop][Loop2].Attribute:=System.TextAttr;
         VideoMem[Loop][Loop2].Character:=#32;
      End;
end;

procedure TScreenObj.Free;
var
   Loop:Longint;

begin
   For Loop:=0 to MaxHeight-1 do
      SetLength(VideoMem[Loop],0);
   SetLength(VideoMem,0);
end;

procedure TScreenObj.Init;
var
   Loop:Longint;

Begin
   with Self do begin
      TMethod(@WhereIsXY) := [@TScreenObj.WhereIsXY, @Self];
      TMethod(@RegionLoad) := [@TScreenObj.RegionLoad, @Self];
      TMethod(@RegionSave) := [@TScreenObj.RegionSave, @Self];
      TMethod(@SetAttr) := [@TScreenObj.SetAttr, @Self];
      TMethod(@GetAttr) := [@TScreenObj.GetAttr, @Self];
      TMethod(@GetChar) := [@TScreenObj.GetChar, @Self];
      TMethod(@PrintLn) := [@TScreenObj.PrintLn, @Self];
      TMethod(@PrintLn) := [@TScreenObj.PrintLn, @Self];
      TMethod(@Print) := [@TScreenObj.Print, @Self];
      TMethod(@PrintCh) := [@TScreenObj.PrintCh, @Self];
      TMethod(@RestoreWindow) := [@TScreenObj.RestoreWindow, @Self];
      TMethod(@Window) := [@TScreenObj.Window, @Self];
      TMethod(@InsLine) := [@TScreenObj.InsLine, @Self];
      TMethod(@DelLine) := [@TScreenObj.DelLine, @Self];
      TMethod(@GotoXY) := [@TScreenObj.GotoXY, @Self];
      TMethod(@ClrEol) := [@TScreenObj.ClrEol, @Self];
      TMethod(@ClrScr) := [@TScreenObj.ClrScr, @Self];
      TMethod(@Free) := [@TScreenObj.Free, @Self];
      MaxHeight:=Max(ScreenHeight,25);
      MaxWidth:=Max(ScreenWidth,80);
      SetLength(VideoMem, MaxHeight);
      For Loop:=0 to MaxHeight-1 do
         SetLength(VideoMem[Loop],MaxWidth);
   end;
End;

{$IFDEF STANDALONE}
var
   Screen:TScreenObj;
{$ENDIF}
