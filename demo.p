Program Assist.v1.0;
{$H-}

uses
   datetime,
   strings,
   display;

{$I FASTTMPT7.i}
{$I PULLTMPT7.i}

procedure Splash;
begin
   CLS(7,0);
   GotoXy(1,25);
   Box(8,2,72,17,11,0,1);
   WriteCenter(3,15,0,'Halcyon version 7.0 Cross-Platform');
   WriteCenter(4,7,0,'Copyright (c) 1985 to 2015 by Griffin Solutions, LLC.');
   WriteCenter(5,7,0,'and Copyright (c) 2016, 2017 by MP Solutions, LLC.');
   WriteCenter(8,3,0,'You may use the Halcyon 7 software and printed materials in');
   WriteCenter(9,3,0,'the Halcyon 7 software package under the terms of the Halcyon');
   WriteCenter(10,3,0,'Software License Agreement. In summary, MP Solutions grants');
   WriteCenter(11,3,0,'you a paid-up, non-transferable, personal license to use the');
   WriteCenter(12,3,0,'Halcyon 7 tool on one personal computer. You do not become the');
   WriteCenter(13,3,0,'owner of the package, nor do you have the right to copy or');
   WriteCenter(14,3,0,'alter the software or printed materials. You are legally');
   WriteCenter(15,3,0,'accountable for any violation of the License Agreement or of');
   WriteCenter(16,3,0,'copyright, trademark or trade secret laws.');
   Yield(1500);
   WriteCenter(23,2,0,'Press the F1 key for HELP.');
   WriteCenter(24,14,0,'Type a command (or ASSIST) and press the ENTER key.');
end;

Procedure PopulateMenu;
Var
   TheMenu:TStringList;
   Major,Minor:Byte;

Begin
   CLS(7,0);
   ClearLine(1,15,1);
   TheMenu.Init;
   With TheMenu do begin
      Add(MainIndent+'&Set Up');
      Add('&Database File');
      Add('&Format for Screen');
      Add('&Query Database');
      Add('&Catalog');
      Add('&View Database');
      Add('E&xit Assistant');
      Add(MainIndent+'&Create');
      Add('&Database File');
      Add('&Format');
      Add('&View');
      Add('&Query');
      Add('&Report');
      Add('&Label');
      Add(MainIndent+'&Update');
      Add('&Append');
      Add('&Edit');
      Add('D&isplay');
      Add('&Browse');
      Add('&Replace');
      Add('&Delete');
      Add('Re&call');
      Add('&Pack');
      Add(MainIndent+'&Position');
      Add('&Seek');
      Add('&Locate');
      Add('&Continue');
      Add('S&kip');
      Add('&Goto Record');
      Add(MainIndent+'&Retrieve');
      Add('&List');
      Add('&Display');
      Add('&Report');
      Add('&Label');
      Add('&Sum');
      Add('&Average');
      Add('&Count');
      Add(MainIndent+'&Organize');
      Add('&Index');
      Add('&Sort');
      Add('&Copy');
      Add(MainIndent+'&Modify');
      Add('&Database File');
      Add('&Format');
      Add('&View');
      Add('&Query');
      Add('&Report');
      Add('&Label');
      Add(MainIndent+'&Tools');
      Add('&Set Path');
      Add('&Copy File');
      Add('&Directory');
      Add('&Rename');
      Add('&Erase');
      Add('&List Structure');
      Add('&Import');
      Add('&Export');
      Add(MainIndent+MainIndent);
   End;
   ClearLine(23,0,7);
   FastWrite(1,23,1,7,'ASSIST');
   FastWrite(17,23,0,7,#186);
   FastWrite(21,23,0,7,#186);
   FastWrite(45,23,0,7,#186);
   FastWrite(46,23,1,7,'Opt: 1/7');
   While true do begin
      PullMenu(TheMenu,Major,Minor);
      if (Major=1) and (Minor=6) then break;
   End;
   TheMenu.Free;
End;

Begin
   InitFastTTT;
   Splash;
   FastWrite('. ');
   ReadKey;
   PopulateMenu;
   DisposeFastTTT;
end;
