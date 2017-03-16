{$I SCRAPER_DEFINES.INC}

unit MediaNameParsingUnit;


interface


function FindIMDBIDInNFOFiles(sPath,sMediaFileName : WideString) : Integer;
function ParseMediaName(MediaName,MediaPath : String; IsFolder : Boolean; CategoryType : Integer; var MediaYear,MediaMonth,MediaDay,MediaSeason,MediaEpisode : Integer; var MediaRes : String) : WideString;
function GetIMDBIDFromTextFile(FileName : WideString) : Integer;
function ExtractFileNameNoExt(FileName : String) : String;


implementation

uses sysutils, tntsysutils, dateutils, tntclasses, TheMovieDB_misc_utils_unit, global_consts;


procedure Split(S : WideString; Ch : Char; sList : TTNTStrings);
var
  I : Integer;
begin
  While Pos(Ch,S) > 0 do
  Begin
    I := Pos(Ch,S);
    sList.Add(Copy(S,1,I-1));
    Delete(S,1,I);
  End;
  If Length(S) > 0 then sList.Add(S);
end;


procedure Combine(sList : TTNTStrings; Ch : Char; var S : WideString);
var
  I : Integer;
begin
  S := '';
  For I := 0 to sList.Count-1 do
  Begin
    If I < sList.Count-1 then S := S+sList[I]+Ch else S := S+sList[I];
  End;
end;


Function ExtractFileNameNoExt(FileName : String) : String;
var
  I : Integer;
begin
  If Length(FileName) > 0 then
  Begin
    Result := ExtractFileName(FileName);
    For I := Length(Result) downto 1 do If Result[I] = '.' then
    Begin
      If I > 1 then Result := Copy(Result,1,I-1);
      Break;
    End;
  End
  Else Result := '';
end;


function GetMediaData(sList : TTNTStringList; CategoryType : Integer; var iYear, iMonth, iDay, iSeason, iEpisode : Integer) : Integer;
var
  I,I1     : Integer;
  Found    : Boolean;
//  SkipDate : Boolean;
  sLen     : Integer;
  sLen1    : Integer;
  sLen2    : Integer;
  lS       : String;
  partFound: Boolean;
begin
  Result   := -1;
  iYear    := -1;
  iMonth   := -1;
  iDay     := -1;
  iSeason  := -1;
  iEpisode := -1;
  partFound:= False;

  //we should start the iteration from 0 because the MediaName can contain only the season number ("Season 01")
  For I := 0 to sList.Count-1 do
  Begin
    lS   := Lowercase(sList[I]);
    sLen := Length(lS);
    // the production year/date should not be the first word in the title so we can safely skip the first item in the list
    // "2001: A Space Odyssey"
    If (I > 0) and ((sLen = 4) or (sLen = 6)) then
    Begin
      // Find a string containing only numbers, possibly encapsulated in "()" or "[]"
      Found := True;
      For I1 := 1 to sLen do
        If Char(sList[I][I1]) in ['0'..'9','[',']','(',')']  = False then
      Begin
        Found := False;
        Break;
      End;

      If Found = True then
      Begin
        If Char(sList[I][1]) in ['[','('] = True then
        Begin
          iYear := StrToIntDef(Copy(sList[I],2,4),-1);
        End
          else
        Begin
          iYear := StrToIntDef(sList[I],-1);

          // Check for possible full date
          If sList.Count > I+2 then
          Begin
            //Found := False;
            sLen1 := Length(sList[I+1]);
            sLen2 := Length(sList[I+2]);
            If (sLen1 = 2) and (sLen2 = 2) then
            Begin
              If (Char(sList[I+1][1]) in ['0'..'9']) and (Char(sList[I+1][2]) in ['0'..'9']) and
                 (Char(sList[I+2][1]) in ['0'..'9']) and (Char(sList[I+2][2]) in ['0'..'9']) then
              Begin
                // Found Date
                iMonth := StrToIntDef(sList[I+1],-1);
                iDay   := StrToIntDef(sList[I+2],-1);
              End;
            End;
          End;
        End;

        // Check that the year is in valid range (from 1895 till next year from now)
        If (iYear >= 1895) and (iYear <= YearOf(Now)+1) then
        Begin
          If Result = -1 then Result := I; // Return list index where we found the year for later cropping
          //Break;
        End;
      End;
    End;

    If CategoryType = osmTV then
    Begin
      If ((iSeason = -1) or (iEpisode = -1) or partFound) then
      Begin
        If (sLen = 3) then // Snn or Enn
        Begin
          If ((lS[1] = 's') or (ls[1] = 'e')) and (lS[2] in ['0'..'9'] = True) and (lS[3] in ['0'..'9'] = True) then
          Begin
            if lS[1] = 's' then
              iSeason := StrToIntDef(Copy(lS,2,2),-1);
            if lS[1] = 'e' then
              iEpisode := StrToIntDef(Copy(lS,2,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;
        End
          else
        If (sLen = 4) then // EPnn or nXnn
        Begin
          If (lS[1] = 'e') and (ls[2] = 'p') and (lS[3] in ['0'..'9'] = True) and (lS[4] in ['0'..'9'] = True) then
          Begin
            iEpisode := StrToIntDef(Copy(lS,3,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;

          If (lS[2] = 'x') and (lS[1] in ['0'..'9'] = True) and (lS[3] in ['0'..'9'] = True) and (lS[4] in ['0'..'9'] = True) then
          Begin
            iSeason  := StrToIntDef(Copy(lS,1,1),-1);
            iEpisode := StrToIntDef(Copy(lS,3,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;
        End
          else
        If (sLen = 5) then // nnXnn
        Begin
          If (lS[3] = 'x') and (lS[1] in ['0'..'9'] = True) and (lS[2] in ['0'..'9'] = True) and (lS[4] in ['0'..'9'] = True) and (lS[5] in ['0'..'9'] = True) then
          Begin
            iSeason  := StrToIntDef(Copy(lS,1,2),-1);
            iEpisode := StrToIntDef(Copy(lS,4,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;
        End
          else
        If (sLen = 6) then // SnnEnn
        Begin
          If (lS[1] = 's') and (lS[4] = 'e') and (lS[2] in ['0'..'9'] = True) and (lS[3] in ['0'..'9'] = True) and (lS[5] in ['0'..'9'] = True) and (lS[6] in ['0'..'9'] = True) then
          Begin
            iSeason  := StrToIntDef(Copy(lS,2,2),-1);
            iEpisode := StrToIntDef(Copy(lS,5,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;
        End
          else
        If (sLen = 8) then // [SnnEnn] or (SnnEnn)
        Begin
          If (lS[2] = 's') and (lS[5] = 'e') and (lS[3] in ['0'..'9'] = True) and (lS[4] in ['0'..'9'] = True) and (lS[6] in ['0'..'9'] = True) and (lS[7] in ['0'..'9'] = True) then
          Begin
            iSeason  := StrToIntDef(Copy(lS,2,2),-1);
            iEpisode := StrToIntDef(Copy(lS,5,2),-1);
            If Result = -1 then Result := I;
            //Break;
          End;
        End;
      End;

      //the following checks are in a separate If statement because their length may vary and can accidentally match one of the above
      //we could add checks like this
      //      part          part1       part01/season   season1       season01
      //  If (sLen = 4) or (sLen = 5) or (sLen = 6) or (sLen = 7) or (sLen = 8) then
      //but it might cause issues in the future if someone adds a new "special" word and fogets to check it's possible lenghts
      If (Pos('part',lS) = 1) and (iEpisode = -1) then
      Begin
        If (sLen = 4) and (I < sList.Count-1) then
        Begin
          // Match "Part XX"
          iEpisode := StrToIntDef(sList[I+1],-1);
        End
          else
        If sLen > 4 then
        Begin
          // Match "PartXX"
          iEpisode := StrToIntDef(Copy(sList[I],5,sLen-4),-1);
        End;
        If iEpisode > -1 then
        Begin
          partFound := True;
          if iSeason = -1 then iSeason := 1;
          If Result = -1 then Result := I;
          //Break;
        End;
      End
        else
      If Pos('season',lS) = 1 then
      Begin
        If (sLen = 6) and (I < sList.Count-1) then
        Begin
          // Match "Season XX"
          iSeason := StrToIntDef(sList[I+1],-1);
        End
          else
        If sLen > 6 then
        Begin
          // Match "SeasonXX"
          iSeason := StrToIntDef(Copy(sList[I],7,sLen-6),-1);
        End;
        If iSeason > -1 then
        Begin
          If Result = -1 then Result := I;
          //Break;
        End;
      End;
    End;
  End;
end;



function ParseMediaName(MediaName,MediaPath : String; IsFolder : Boolean; CategoryType : Integer; var MediaYear,MediaMonth,MediaDay,MediaSeason,MediaEpisode : Integer; var MediaRes : String) : WideString;
const
  // Resolution list
  ResCount   = 12;
  ResList    : Array[0..ResCount-1] of String =
   ('720p','1080p','480p','540p','2160p','240p','360p','480i','576i','576p','1080i','4320p');

  // Safe crop words
  CropCount  = 58;
  CropList   : Array[0..CropCount-1] of String =
    ('unrated','rerip','repack','final repack','real proper','readnfo','stv','dircut','remastered',
     'theatrical cut', 'theatrical edition', 'directors cut', 'director''s cut', 'directors edition', 'director''s edition',
     'hdtv','web dl','dvdrip','bdrip','brrip','bluray','blu ray','hdrip','webrip',
     'x264','x265','h264','h 264','h 265','xvid','divx','mpeg2','avc',
     'pdtv','sdtv','ws pdtv','dvdscr','dvd','hddvd','dsr','ws dsr',
     'dts','dd5','dd2','ac3','aac','aac2','truehd','mp3','flac',
     'hdcam','cam','hd ts','ts','tc','vcd','svcd','xxx');

  // Unsafe crop words, must be followed by a safe crop word to be detected
  FlagCount = 4;
  FlagList  : Array[0..FlagCount-1] of String =
    ('proper','internal','limited','docu');

var
  I,I1           : Integer;
  lS             : WideString;
  iPos           : Integer;
  iCropPos       : Integer;
  iResPos        : Integer;
  nList          : TTNTStringList;
  iFlag          : Integer;
  iFlagPos       : Integer;
  iDay           : Integer;
  iMonth         : Integer;
  iYear          : Integer;
  iMediaDataIdx  : Integer;

  parentFolderMediaNameYear    : Integer;
  parentFolderMediaNameMonth   : Integer;
  parentFolderMediaNameDay     : Integer;
  parentFolderMediaNameSeason  : Integer;
  parentFolderMediaNameEpisode : Integer;
  parentFolderMediaNameRes     : String;
begin
  // Strip file extension if we're dealing with media files, with folders, pass StripFileExt=False
  If IsFolder = True then
  Begin
    // Special folder name processing?

  End
  Else MediaName := ExtractFileNameNoExt(MediaName); // Remove file extension

  MediaYear    := -1;
  MediaMonth   := -1;
  MediaDay     := -1;
  MediaSeason  := -1;
  MediaEpisode := -1;
  MediaRes     := '';
  iFlag        := -1;

  // Replace ".", "_" and "-" characters with spaces and UTF8 decode to unicode
  Result := ConvertCharsToSpaces(UTF8Decode(MediaName));

  lS := TNT_WideLowercase(Result)+' ';

  // Find Resolution
  iResPos := MAXINT;
  For I := 0 to ResCount-1 do
  Begin
    iPos := Pos(ResList[I],lS);
    If iPos > 1 then
    Begin
      MediaRes := ResList[I];
      iResPos  := iPos;
      Break;
    End;
  End;

  // Mark first unsafe word
  iFlagPos := MAXINT;
  For I := 0 to FlagCount-1 do
  Begin
    iPos := Pos(' '+FlagList[I]+' ',lS);
    If iPos = 0 then iPos := Pos('['+FlagList[I]+']',lS); // allow unsafe word encapsulated in '[]'
    If iPos = 0 then iPos := Pos('('+FlagList[I]+')',lS); // allow unsafe word encapsulated in '()'
    If (iPos > 1) and (iPos < iFlagPos) then
    Begin
      iFlag    := I;
      iFlagPos := iPos;
    End;
  End;

  // Find a safe crop word
  iCropPos := iResPos;
  For I := 0 to CropCount-1 do
  Begin
    iPos := Pos(' '+CropList[I]+' ',lS);
    If iPos = 0 then iPos := Pos('['+CropList[I]+']',lS); // allow safe word encapsulated in '[]'
    If iPos = 0 then iPos := Pos('('+CropList[I]+')',lS); // allow safe word encapsulated in '()'
    If (iPos > 1) and (iPos < iCropPos) then
    Begin
      iCropPos := iPos;
    End;
  End;
  If iCropPos < MAXINT then
  Begin
    If iFlagPos < MAXINT then
    Begin
      // If an unsafe crop word was detected, ensure it is next to a safe word before using its position to crop.
      If iFlagPos+Length(FlagList[iFlag])+1 = iCropPos then
        Result := Copy(Result,1,iFlagPos-1) else
        Result := Copy(Result,1,iCropPos-1);
    End
    Else Result := Copy(Result,1,iCropPos-1);
  End;

  // Parse media for date year from 1895 to Next year from today.
  // The year can be encompassed in "()" or "[]".
  // The year detection is done after the safe word cropping to avoid errors for
  // Media Titles as "Bolt.1080p.BluRay.x264-1920" where 1920 is definitely not the prduction year
  nList := TTNTStringList.Create;
  Split(Result,' ',nList); // Split words into an array
  iMediaDataIdx := GetMediaData(nList,CategoryType,iYear,iMonth,iDay,MediaSeason,MediaEpisode);
//  If (iYear > -1) or (MediaSeason > -1) then
  If (iMediaDataIdx > -1) then
  Begin
    MediaYear := iYear;
    If iMonth > -1 then
    Begin
      MediaDay   := iDay;
      MediaMonth := iMonth;
    End;
    //crop everything after the Media Data including itself
    If iMediaDataIdx = 0 then
    Begin
      Result := '';
      // we should try to extract the Title from the parent folder in the following cases
      If    (IsFolder and (MediaSeason > -1)) //we are trying to process a folder whose name only contains the season/part number
         or (not IsFolder and (MediaEpisode > -1)) //we are trying to process a file whose name only contains episode and probably season (but not required) number (example: \Breaking Bad\Season 02\E01 - Seven Thirty-Seven.mkv)
      then
      Begin
        // Strip backslash from folder names as needed
        If (MediaPath[Length(MediaPath)] = '\') then MediaPath := Copy(MediaPath,1,Length(MediaPath)-1);

        Result := ParseMediaName(ExtractFileName(MediaPath),WideExtractFilePath(MediaPath),True,CategoryType,parentFolderMediaNameYear,parentFolderMediaNameMonth,parentFolderMediaNameDay,parentFolderMediaNameSeason,parentFolderMediaNameEpisode,parentFolderMediaNameRes);

        If MediaYear    = -1 then MediaYear    := parentFolderMediaNameYear;
        If MediaMonth   = -1 then MediaMonth   := parentFolderMediaNameMonth;
        If MediaDay     = -1 then MediaDay     := parentFolderMediaNameDay;
        If MediaSeason  = -1 then MediaSeason  := parentFolderMediaNameSeason;
        If MediaEpisode = -1 then MediaEpisode := parentFolderMediaNameEpisode;
        If MediaRes     = '' then MediaRes     := parentFolderMediaNameRes;
      End;
    End
      else
    Begin
      If iMediaDataIdx <= nList.Count-1 then
        For I1 := nList.Count-1 downto iMediaDataIdx do nList.Delete(I1);
      Combine(nList,' ',Result); // Combine the updated array back into a string
    End;
  End;

  // Strip any data after the "^" special character (to allow naming tags to be ignored)
  I := Pos('^',Result);
  If I > 0 then Result := Copy(Result,1,I-1);

  Result := Trim(Result);
  nList.Free;
end;


function FindIMDBIDInNFOFiles(sPath,sMediaFileName : WideString) : Integer;
var
  I                : Integer;
  fList            : TTNTStringList;
  iCurrIMDBID      : Integer;
  bMultipleResults : Boolean;
begin
  Result := -1;
  bMultipleResults := False;
  fList  := TTNTStringList.Create;
  sPath  := AddBackSlash(sPath);
  sMediaFileName := ExtractFileNameNoExt(sMediaFileName);

  FileExtIntoStringList(sPath,'.nfo',fList,False);
  If fList.Count > 0 then For I := 0 to fList.Count-1 do
  Begin
    iCurrIMDBID := GetIMDBIDFromTextFile(fList[I]);
    if iCurrIMDBID > -1 then
    Begin
      If WideCompareText(ExtractFileNameNoExt(fList[I]),sMediaFileName) = 0 then
      Begin
        Result := iCurrIMDBID;
        bMultipleResults := False;
        Break;
      End;
      If Result > -1 then
      Begin
        If Result <> iCurrIMDBID then
        Begin
          bMultipleResults := True;
          If sMediaFileName = '' then Break;
        End;
      End
      Else Result := iCurrIMDBID;
    End
  End;

  If bMultipleResults then Result := -1;

  fList.Free;
end;


function GetIMDBIDFromTextFile(FileName : WideString) : Integer;
var
  I     : Integer;
  iPos  : Integer;
  sList : TTNTStringList;
begin
  Result := -1;
  sList  := TTNTStringList.Create;

  Try
    sList.LoadFromFile(FileName);
  Except
    FreeAndNil(sList);
  End;

  If sList <> nil then
  Begin
    For I := 0 to sList.Count-1 do
    Begin
      iPos := Pos('imdb.com/title/',TNT_WideLowercase(sList[I]));
      If iPos > 0 then
      Begin
        Result := StrToIntDef(Copy(sList[I],iPos+17,7),-1);
        If Result > -1 then Break;
      End;
    End;
    sList.Free;
  End;
end;


end.

