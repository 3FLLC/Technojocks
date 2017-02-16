{%Unit TMPT v7.0}

(*
   Technojock Modern Pascal Toolkit
   Pull Down Menu
   By: G.E. Ozz Nixon Jr.

   Inspired by Technojock's Turbo Toolkit
   Coded while jammin' to Scorpions!   \m/
*)

/////////////////////////////////////////////////
//// REQUIRES FASTTMPT7.i TO BE LOADED FIRST ////
//// {$I FASTTMPT7.i} in main application... ////
/////////////////////////////////////////////////

(*
   Now we use a TStringList for the Array! There
   are other suble changes to the design, like
   supporting all 5 built-in styles now, add
   support for more keystrokes, and your highlight
   can be first capital or character after & like
   windows development.
*)

Const
   Max_Pull_Topics = 60;
   Max_Pull_Width = 30;
   Max_Main_Picks = 8;
   Max_SubPicks = 10;
   MainIndent = '\';     // Symbol indicating main menu item

Type
   MenuConfiguration = Packed Record
      Left:Byte;
      Top:Byte;
      Style:Byte;
      NormalFG:Byte;     // Normal operation FG
      NormalBG:Byte;     // Normal operation BG
      FirstCharFG:Byte;  // First Character FG
      MainPickBG:Byte;   // BG of picked main menu item
      HighlightFG:Byte;  // Highlighter FG
      HighlightBG:Byte;  // Highlighter BG
      BorderFG:Byte;     // Border FG
      Gap:Byte;          // Gap between Picks
      LeftChar:Char;     // Left-hand topic character
      RightChar:Char;    // Right-hand topic character
      AllowESC:Boolean;  // Allow Escape to collapse
      RemoveMenu:Boolean;// ClrScr on Exit
      AlwaysDown:Boolean;//
      Initialized:Boolean;// If you init anything set this to true!
      _Internal:TRegion; // Capture of background before drop-down!
   End;

Var
   PTTT:MenuConfiguration;

Procedure PullMenu(Definition:TStringList;var MainPicked,SubmenuPicked:Byte);
Type
   Sub_Details = Packed Record
      Text:Array[0..Max_SubPicks] of String[Max_Pull_Width];
      Total:Byte;
      Width:Byte;
      LastPick:Byte;
   End;

Var
   SubMenu:Array[1..Max_Main_Picks] of Sub_Details;
   Tot_Main:Byte;        // Total number of main picks
   Main_Wid:Byte;        // Width of Main Menu Box
   Finished:Boolean;     // Has used selected an option
   Down:Boolean;         // Sub-Menu is displayed
   ChM,ChT:Char;         // Keypressed Char
   X1,Y1,X2,Y2:Byte;     // Lower Menu Borders
   Cap,Count:Byte;       // If key is = first char
   I:Longint;            //
   TLChar:Char;          // Border top left char
   TRChar:Char;          // Border top right char
   BLChar:Char;          // Border bottom left char
   BRChar:Char;          // Border bottomr right char
   JoinChar:Char;        // Border Joining Char
   JoinDownChar:Char;    // Border Joining Char
   JoinLeftChar:Char;    // Border Joining Char
   VertChar:Char;        // Border Vert Char
   HorizChar:Char;       // Border Horiz Char

  Procedure ShowErr(ErrNo:Byte);
  Begin
     Writeln();
     Case ErrNo of
        1:Writeln("Menu definition must start with a '\' main choice");
        2:Writeln("Main menu definition must be at least 1 character");
        3:Writeln("Too many main menu items");
        4:Writeln("Too many sub-menu items");
        5:Writeln("No end of menu indicator found");
        6:Writeln("Must be at least two main menu items");
        7:Writeln("Main Menu will not fit in "+IntToStr(TMPTSO.MaxWidth));
        8:Writeln('Error saving screen.');
     end;
     Halt(12);
  end;

   Procedure Default_Settings;
   Begin
      With PTTT do begin
         Left:=1;
         Top:=1;
         Style:=0;
         NormalFG:=Yellow;
         NormalBG:=Blue;
         FirstCharFG:=LightCyan;
         MainPickBG:=Red;
         HighlightFG:=Yellow;
         HighlightBG:=Red;
         BorderFG:=Cyan;
         Gap:=1;
         LeftChar:=#32;//'>';
         RightChar:=#32;//'<';
         AllowESC:=True;
         RemoveMenu:=True;
         AlwaysDown:=False; //True;
         Initialized:=True;
      End;
   End;

   Procedure LoadMenuParameters;
   Var
      I,Majr,Minr,Widest:Longint;
      Instr:String[Max_Pull_Width];
      Finished:Boolean;

   Begin
      FillChar(SubMenu, SizeOf(SubMenu), #0);
      Tot_Main:=0;
      If Definition.getStrings(0)[1]<>MainIndent then ShowErr(1);
      Majr:=0;
      Widest:=0;
      I:=0;
      Finished:=False;
      While (I<Max_Pull_Topics-1) and (not Finished) do begin
         If I<Definition.getCount then begin
            Instr:=Definition.getStrings(I);
            If Instr[1]=MainIndent then begin
               If Majr<>0 then begin // update for last submenu
                  SubMenu[Majr].Total:=Minr;
                  SubMenu[Majr].Width:=Widest;//+2; { add padding }
               end;
               If Length(Instr)<2 then ShowErr(2);
               If Instr=MainIndent+MainIndent then begin // end of menu
                  Tot_Main:=Majr;
                  Finished:=True;
               End
               else begin
                  Inc(Majr);
                  If Majr>Max_Main_Picks then ShowErr(3);
                  Delete(Instr,1,1);
                  SubMenu[Majr].Text[0]:=Instr;
               End;
               Minr:=0;
               Widest:=0;
            End
            else begin // not a main menu pick
               Minr:=Succ(Minr);
               If Minr>Max_SubPicks then ShowErr(4);
               SubMenu[Majr].Text[Minr]:=InStr;
               If Length(Instr)>Widest then Widest:=Length(Instr);
            end;
         end;
         Inc(I);
      end; // while
      If Tot_Main=0 then ShowErr(5)
      else if Tot_Main<2 then ShowErr(6);
   end;

   Procedure DisplayMainPicks(Num:byte;Selected:Boolean);
   var
     ChT:Char;
     Os,X,I:byte;
   begin
      If PTTT.Style>0 then Os:=1
      Else Os:=0;
      X:=1;
      If Num=1 then X:=X+PTTT.Left+PTTT.Gap
      else begin
         For I:=1 to Num-1 do
            X:=X+length(Submenu[I].Text[0])+PTTT.Gap;
         X:=X+PTTT.Left+PTTT.Gap;
      end;
      If Selected then
         FastWrite(X,PTTT.Top+Os,Attr(PTTT.HighlightFG,PTTT.MainPickBG),StringReplace(SubMenu[Num].Text[0],'&','',[]))
      else
         Fastwrite(X,PTTT.Top+Os,attr(PTTT.NormalFG,PTTT.NormalBG),StringReplace(SubMenu[Num].Text[0],'&','',[]));
      I:=Pos('&',Submenu[Num].Text[0]);
      If I>0 then ChT:=Submenu[Num].Text[0][I+1]
      else I:=FirstCapitalPos(Submenu[Num].Text[0]);
      If I>0 then
         If Selected then begin
            FastWrite(pred(X)+I,PTTT.Top+Os,attr(PTTT.FirstCharFG,PTTT.MainPickBG),ChT);
            GotoXY(X,PTTT.Top+Os);
         end
         else
            FastWrite(pred(X)+I,PTTT.Top+Os,attr(PTTT.FirstCharFG,PTTT.NormalBG),ChT);
   end;

   Procedure DisplayMainMenu; {draws boxes, main menu picks and draws border}
   var
      I:byte;

   begin
       {draw the box}
       Main_Wid:=succ(PTTT.Gap); {determine the width of the main menu}
       For I:=1 to Tot_Main do
          Main_Wid:=Main_Wid+PTTT.Gap+length(SubMenu[I].Text[0]);
       If Main_Wid+2+(PTTT.Left-1)+1>TMPTSO.MaxWidth then {5.02b} ShowErr(7);
       If PTTT.Style=0 then begin
          ClearText(PTTT.Left,PTTT.Top,PTTT.Left+Main_Wid,PTTT.Top,PTTT.NormalFG,PTTT.NormalBG);
          FastWrite(1,1,Attr(PTTT.NormalFG,PTTT.NormalBG),#240);
       end
       else
          Fbox(PTTT.Left,PTTT.Top,PTTT.Left+Main_Wid,PTTT.Top+2,PTTT.BorderFG,PTTT.NormalBG,PTTT.Style);
       For I:=1 to ToT_Main do DisplayMainPicks(I,I=MainPicked);
   end;

   Procedure DisplaySubPicks(No : byte; Selected:Boolean);
   var
      ChT:Char;
      B:Byte;
   begin
      If Selected then
         Fastwrite(X1+1,Succ(PTTT.Top)+ord(PTTT.Style>0)+No,
         attr(PTTT.HighlightFG,PTTT.HighlightBG),
         PTTT.LeftChar+PadRight(StringReplace(Submenu[MainPicked].Text[No],'&','',[]),Submenu[MainPicked].Width)+
         PTTT.Rightchar)
      else begin
         Fastwrite(X1+1,Succ(PTTT.Top)+Ord(PTTT.Style>0)+No,
         attr(PTTT.NormalFG,PTTT.NormalBG),
         #32+PadRight(StringReplace(Submenu[MainPicked].Text[No],'&','',[]),Submenu[MainPicked].Width)+#32);
         B:=Pos('&',Submenu[MainPicked].Text[No]);
         If B>0 then ChT:=Submenu[MainPicked].Text[No][B+1]
         else begin
            B:=FirstCapitalPos(Submenu[MainPicked].Text[No]);
            If B>0 then ChT:=SubMenu[MainPicked].Text[No][B];
         End;
         If B<>0 then
            FastWrite(X1+1+B,succ(PTTT.Top)+Ord(PTTT.Style>0)+No,
            attr(PTTT.FirstCharFG,PTTT.NormalBG),ChT);
      end;
      GotoXY(X1+1,succ(PTTT.Top)+ord(PTTT.Style>0)+No);
   end;

   Procedure DisplaySubMenu(No :byte);
   var
      BotLine:string;
      I:byte;

   begin
      If (Submenu[MainPicked].Total = 0) then exit
      else Down:=true;
      X1:=pred(PTTT.Left);                  {determine box coords of sub menu}
      If No<>1 then begin
         If Length(Submenu[MainPicked].Text[0])>Submenu[MainPicked].Width then Inc(X1,2) // OZZ
         else Inc(X1,1); // OZZ
         For I:=1 to pred(No) do
            X1:=X1+PTTT.Gap+length(Submenu[I].text[0]);
         X1:=pred(X1)+PTTT.Gap;
      end
      else X1:=X1+2;
      X2:=X1+Submenu[No].width+3;
      If X2>79 then begin
         X1:=79-(X2-X1);
         X2:=79;
      end;
      Y1:=succ(PTTT.Top)+ord(PTTT.Style>0);
      Y2:=Y1+1+Submenu[No].total;
      If PTTT._Internal.Width>0 then TMPTSO.RegionLoad(PTTT._Internal);
      TMPTSO.RegionSave(X1,Y1,X2,Y2,PTTT._Internal);
      Fbox(X1,Y1,X2,Y2,PTTT.BorderFG,PTTT.NormalBG,PTTT.Style);
      Fastwrite(X1,succ(PTTT.Top)+ord(PTTT.Style>0),attr(PTTT.BorderFG,PTTT.NormalBG),Joinchar);
      If X2<PTTT.Left+Main_wid then
         Fastwrite(X2,succ(PTTT.Top)+ord(PTTT.Style>0),attr(PTTT.BorderFG,PTTT.NormalBG),Joinchar)
      else
         If X2=PTTT.Top+Main_wid then
            Fastwrite(X2,succ(PTTT.Top)+ord(PTTT.Style>0),attr(PTTT.BorderFG,PTTT.NormalBG),Joinleftchar)
         else begin
            Fastwrite(X2,PTTT.Top+2,attr(PTTT.BorderFG,PTTT.NormalBG),TRchar);
            Fastwrite(PTTT.Left+Main_wid,succ(PTTT.Top)+ord(PTTT.Style>0),attr(PTTT.BorderFG,PTTT.NormalBG),Joindownchar);
         end;
      For I:=1 to Submenu[MainPicked].total do DisplaySubPicks(I,false);
         SubmenuPicked:=SubMenu[MainPicked].LastPick;
      If not (SubmenuPicked in [1..Submenu[MainPicked].Total]) then SubmenuPicked:=1;
      DisplaySubPicks(SubmenuPicked,True);
   end;

Begin
   If not PTTT.Initialized then Default_Settings;
   Case PTTT.Style of
      1:Begin
         TLChar:=#218;
         TRChar:=#191;
         BLChar:=#192;
         BRChar:=#217;
         JoinChar:=#194;
         JoinDownChar:=#193;
         JoinLeftChar:=#180;
         VertChar:=#179;
         HorizChar:=#196;
      end;
      2:begin
         TLChar:=#201;
         TRChar:=#187;
         BLChar:=#200;
         BRChar:=#188;
         JoinChar:=#203;
         JoinDownChar:=#202;
         JoinLeftChar:=#185;
         VertChar:=#186;
         HorizChar:=#205;
      end;
      else begin
         TLChar:=#32;
         TRChar:=#32;
         BLChar:=#32;
         BRChar:=#32;
         JoinChar:=#32;
         JoinDownChar:=#32;
         JoinLeftChar:=#32;
         VertChar:=#32;
         HorizChar:=#32;
      end;
   end;
   LoadMenuParameters;
   If MainPicked<1 then MainPicked:=1;
   DisplayMainMenu;
   For I:=1 to Tot_Main do Submenu[I].lastPick:=1;
   Submenu[MainPicked].LastPick:=SubmenuPicked;
   If SubmenuPicked<>0 then begin
      DisplaySubMenu(MainPicked);
      Down:=True;
   end
   else Down:=False;

   Repeat
      while not KeyPressed do begin
         FastWrite(72, PTTT.Top, attr(PTTT.BorderFG, PTTT.NormalBG),
            FormatTimestamp('hh:nn:ss',Timestamp));
         Yield(300);
      End;
      ChM:=ReadKey;
      Case Upcase(ChM) of
         'A'..'Z':If down then begin {see if it is highlight letter}
            Count:=0;
         End;
         #32,#13:If Down or (Submenu[MainPicked].Total=0) then begin
            Finished:=True;
            If Submenu[MainPicked].Total=0 then SubmenuPicked:=0;
         end
         else begin
            Down:=True;
            DisplayMainPicks(MainPicked,True); // was 2
            DisplaySubMenu(MainPicked);
         end;
         #27:If Down then begin
            If not PTTT.AlwaysDown then begin
               Down:=False;
               // Remove Submenu:
               If PTTT._Internal.Width>0 then
                  TMPTSO.RegionLoad(PTTT._Internal);
               DisplayMainMenu;
            end
            else If PTTT.AllowEsc then begin
               Finished:=True;
               MainPicked:=0;
            End;
         End;
         #0:Begin // Arrows or Alt-Key
            ChM:=ReadKey;
            Case ChM of
               #72:If (Submenu[MainPicked].Total<>0) then begin // Up
                  If down then begin
                     DisplaySubPicks(SubmenuPicked,False);
                     If SubmenuPicked<>1 then Dec(SubmenuPicked)
                     else SubmenuPicked:=Submenu[MainPicked].Total;
                     DisplaySubPicks(SubmenuPicked,True);
                  end;
               end;
               #80:If (Submenu[MainPicked].Total<>0) then begin // Down
                  If Not Down then begin
                     Down:=True;
                     DisplayMainPicks(MainPicked,True);
                     DisplaySubMenu(MainPicked);
                  end
                  else begin
                     DisplaySubPicks(SubmenuPicked,False);
                     If SubmenuPicked<Submenu[MainPicked].Total then Inc(SubmenuPicked)
                     else SubmenuPicked:=1;
                     DisplaySubPicks(SubmenuPicked,True);
                  end;
               end;
               #77:begin // Right
                  DisplayMainPicks(MainPicked,False); {clear highlight}
                  If Down then
                     If PTTT._Internal.Width>0 then
                     TMPTSO.RegionLoad(PTTT._Internal);
                  If MainPicked<ToT_Main then Inc(MainPicked)
                  else MainPicked:=1;
                  DisplayMainPicks(MainPicked,True);
                  If down then DisplaySubMenu(MainPicked);
               end;
               #75:begin // Left
                  DisplayMainPicks(MainPicked,False); {clear highlight}
                  If Down then
                     If PTTT._Internal.Width>0 then
                     TMPTSO.RegionLoad(PTTT._Internal);
                  If MainPicked>1 then Dec(MainPicked)
                  else MainPicked:=Tot_Main;
                  DisplayMainPicks(MainPicked,True);
                  If down then DisplaySubMenu(MainPicked);
               end;
               #71:If (Submenu[MainPicked].Total <> 0) then begin // Home
                  If Down then begin
                     DisplaySubPicks(SubmenuPicked,False);
                     SubmenuPicked:=1;
                     DisplaySubPicks(SubmenuPicked,True);
                  end
                  else begin
                     DisplayMainPicks(MainPicked,False);
                     MainPicked:=1;
                     DisplayMainPicks(MainPicked,True);
                  end;
               end
               else begin
                  DisplayMainPicks(MainPicked,False);
                  MainPicked:=1;
                  DisplayMainPicks(MainPicked,True);
                  If Down then begin
                     DisplayMainPicks(MainPicked,True);
                     DisplaySubMenu(MainPicked);
                  end;
               end;
               #79:If (Submenu[MainPicked].Total<>0) then begin // End
                  If Down then begin
                     DisplaySubPicks(SubmenuPicked,False);
                     SubmenuPicked:=Submenu[MainPicked].Total;
                     DisplaySubPicks(SubmenuPicked,True);
                  end
                  else begin
                     DisplayMainPicks(MainPicked,False);
                     MainPicked:=ToT_Main;
                     DisplayMainPicks(MainPicked,True);
                  end;
               end
               else begin
                  DisplayMainPicks(MainPicked,False);
                  MainPicked:=ToT_Main;
                  DisplayMainPicks(MainPicked,True);
                  If Down then begin
                     DisplayMainPicks(MainPicked,True);
                     DisplaySubMenu(MainPicked);
                  end;
               end;
           End;
            // Writeln(Ord(ReadKey)); Readkey;
         End;
         else begin
         end;
      end;
      if Submenu[MainPicked].Total=0 then SubmenuPicked:=0;
   until Finished;
//   If PTTT.RemoveMenu then Restore_Screen;
//   Dispose_Screen;
end;
