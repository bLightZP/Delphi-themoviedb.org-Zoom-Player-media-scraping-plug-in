{$DEFINE LOCALTRACE}

     {********************************************************************
      | This Source Code is subject to the terms of the                  |
      | Mozilla Public License, v. 2.0. If a copy of the MPL was not     |
      | distributed with this file, You can obtain one at                |
      | https://mozilla.org/MPL/2.0/.                                    |
      |                                                                  |
      | Software distributed under the License is distributed on an      |
      | "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   |
      | implied. See the License for the specific language governing     |
      | rights and limitations under the License.                        |
      ********************************************************************}


      { This sample code uses the SuperObject library for the JSON parsing:
        https://github.com/hgourvest/superobject

        And the TNT Delphi Unicode Controls (compatiable with the last free version)
        to handle a few unicode tasks.

        And optionally, the FastMM/FastCode/FastMove libraries:
        http://sourceforge.net/projects/fastmm/
        }


library themoviedb;

// To-Do:
// 1. Decide which poster sizes to grab

uses
  FastMM4,
  FastMove,
  FastCode,
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Windows,
  SysUtils,
  Classes,
  Forms,
  Controls,
  DateUtils,
  SyncObjs,
  Dialogs,
  TNTClasses,
  TNTSysUtils,
  SuperObject,
  WinInet,
  MediaNameParsingUnit,
  TheMovieDB_Search_Unit,
  Misc_Utils_Unit,
  global_consts,
  configformunit in 'configformunit.pas' {ConfigForm};

{$R *.res}

Const
  // Settings Registry Path and Key
  ScraperRegKey    : String = 'Software\VirtuaMedia\ZoomPlayer\Scrapers\TheMovieDB';
  RegKeySecuredStr : String = 'Secured';
  RegKeyMinMediaNameLengthForScrapingByNameStr : String = 'MinMediaNameLengthForScrapingByName';


  //Strings used to store the data in the Metadata File
  mdfPrefix : String = 'TheMovieDB_';

  mdfMediaNameEpisodeStr : String = 'media_name_episode';
  mdfMediaNameSeasonStr  : String = 'media_name_season';
  mdfMediaNameYearStr    : String = 'media_name_year';

  mdfDBIDStr        : String = 'id';
  mdfIMDBIDStr      : String = 'imdb_id';
  mdfTitleStr       : String = 'title';
  mdfTVShowNameStr  : String = 'tv_show_name';
  mdfReleaseDateStr : String = 'release_date';
//  mdfReleaseYearStr : String = 'year';
  mdfRuntimeStr     : String = 'runtime';
  mdfRatingStr      : String = 'rating';
  mdfGenreStr       : String = 'genre';
  mdfDirectorStr    : String = 'director';
  mdfCastStr        : String = 'cast';
  mdfOverViewStr    : String = 'overview';

Var
  SecureHTTP       : Boolean = False;
  MinMediaNameLengthForScrapingByName : Integer = 2;


// Called by Zoom Player to free any resources allocated in the DLL prior to unloading the DLL.
Procedure FreeScraper; stdcall;
var
  I : Integer;
begin
  If PosterSizeList   <> nil then FreeAndNil(PosterSizeList);
  If BackdropSizeList <> nil then FreeAndNil(BackdropSizeList);
  If StillSizeList    <> nil then FreeAndNil(StillSizeList);
  csQuery.Enter;
  Try
    If TVSeriesIDList   <> nil then
    Begin
      For I := 0 to TVSeriesIDList.Count-1 do Dispose(PTVSeriesIDRecord(TVSeriesIDList[I]));
      FreeAndNil(TVSeriesIDList);
    End;
    If QueryTSList <> nil then
    Begin
      For I := 0 to QueryTSList.Count-1 do Dispose(PInt64(QueryTSList[I]));
      FreeAndNil(QueryTSList);
    End;
  Finally
    csQuery.Leave;
  End;
  FreeAndNil(csQuery);
end;

// Called by Zoom Player to init any resources.
function InitScraper : Boolean; stdcall;
var
  sList       : TStringList;
  I           : Integer;
begin
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Init');{$ENDIF}
  if not Assigned(csQuery) then
    csQuery := TCriticalSection.Create;
  if not Assigned(TVSeriesIDList) then
    TVSeriesIDList := TList.Create;
  if not Assigned(QueryTSList) then
    QueryTSList := TList.Create;
  if not Assigned(StillSizeList) then
    StillSizeList := TStringList.Create;
  if not Assigned(BackdropSizeList) then
    BackdropSizeList := TStringList.Create;
  if not Assigned(PosterSizeList) then
    PosterSizeList := TStringList.Create;

  I := GetRegDWord(HKEY_CURRENT_USER,ScraperRegKey,RegKeySecuredStr);
  If I > -1 then SecureHTTP := Boolean(I);
  I := GetRegDWord(HKEY_CURRENT_USER,ScraperRegKey,RegKeyMinMediaNameLengthForScrapingByNameStr);
  If I > -1 then MinMediaNameLengthForScrapingByName := I;

  sList := TStringList.Create;

  Result := DownloadConfiguration(SecureHTTP,sList);

  sList.Free;
end;


// Called by Zoom Player to verify if a configuration dialog is available.
// Return True if a dialog exits and False if no configuration dialog exists.
function CanConfigure : Boolean; stdcall;
begin
  Result := True;
end;


// Called by Zoom Player to show the scraper's configuration dialog.
Procedure Configure(CenterOnWindow : HWND); stdcall;
var
  CenterOnRect : TRect;
  tmpInt: Integer;
begin
  If GetWindowRect(CenterOnWindow,CenterOnRect) = False then
    GetWindowRect(0,CenterOnRect); // Can't find window, center on screen

  ConfigForm := TConfigForm.Create(nil);
  ConfigForm.SetBounds(CenterOnRect.Left+(((CenterOnRect.Right -CenterOnRect.Left)-ConfigForm.Width)  div 2),
                       CenterOnRect.Top +(((CenterOnRect.Bottom-CenterOnRect.Top )-ConfigForm.Height) div 2),ConfigForm.Width,ConfigForm.Height);

  ConfigForm.SecureCommCB.Checked := SecureHTTP;
  ConfigForm.edtMinMediaNameLengthForScrapingByName.Text := IntToStr(MinMediaNameLengthForScrapingByName);

  If ConfigForm.ShowModal = mrOK then
  Begin
    // Save to registry
    If SecureHTTP <> ConfigForm.SecureCommCB.Checked then
    Begin
      SecureHTTP := ConfigForm.SecureCommCB.Checked;
      SetRegDWord(HKEY_CURRENT_USER,ScraperRegKey,RegKeySecuredStr,Integer(SecureHTTP));
    End;
    tmpInt := StrToInt(ConfigForm.edtMinMediaNameLengthForScrapingByName.Text);
    If MinMediaNameLengthForScrapingByName <> tmpInt then
    Begin
      MinMediaNameLengthForScrapingByName := tmpInt;
      SetRegDWord(HKEY_CURRENT_USER,ScraperRegKey,RegKeyMinMediaNameLengthForScrapingByNameStr,MinMediaNameLengthForScrapingByName);
    End;
  End;
  ConfigForm.Free;
end;


Const
// Current results may be:
  SCRAPE_RESULT_SUCCESS = NO_ERROR; // = 0 - Scraping successful

  SCRAPE_RESULT_NOT_FOUND = -1; // Failed to scrape (no results found)
  // other negative values defined in TheMovieDB_Search_Unit.pas like SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED

  SCRAPE_RESULT_ERROR_INTERNET = INTERNET_ERROR_BASE; // = 12000 - Online Database connection error

  SCRAPE_RESULT_ERROR_OTHER = MaxInt; // Other error

Function ScrapeDB(pcMediaName, pcDataPath, pcPosterFile, pcBackdropFile, pcStillFile, pcDataFile : PChar; IsFolder : Boolean; CategoryType : Integer; PreferredLanguage : PChar; grabThreadID : Integer) : Integer; stdcall;
var
  sSecure            : String;
  sParsed            : WideString;
  Media_Name         : String;
  Media_Path         : WideString;
//  Image_File_dep     : WideString;
  Poster_File        : WideString;
  Backdrop_File      : WideString;
  Still_File         : WideString;
  Data_Path          : WideString;
  Data_File          : WideString;
  IMDB_ID            : Integer;
  MetaData           : TtmdbMetaDataRecord;
  mdList             : TTNTStringList;
  mdMediaNameYear    : Integer;
  mdMediaNameMonth   : Integer;
  mdMediaNameDay     : Integer;
  mdMediaNameSeason  : Integer;
  mdMediaNameEpisode : Integer;
  mdMediaNameRes     : String;
  sList              : TStringList;
  I                  : Integer;
  SkipSearchForTVShowID : Boolean;
  tmpTVShowBackdropPath : String;
  tmpTVShowGenre     : WideString;
  sDownloadStatus    : String;
  LastErrorCode      : Integer;
begin
  // [pcMediaName]
  // Contains the UTF8 encoded media file name being scrapped.
  //
  //
  // [pcDataPath]
  // Contains the UTF8 encoded folder name used to save the meta-data
  // file and any scraped media (images for example).
  //
  //
  // [pcPosterFile, pcBackdropFile, pcStillFile]
  // Contains the UTF8 encoded file name to use when saving a scraped images.
  //
  //
  // [pcDataFile]
  // The file name to create and write the scrapped meta-data.
  // Make sure to use the full path [DataPath]+[DataFile]
  // If the value is empty, do not save a data file!
  //
  //
  // [IsFolder]
  // Indicates if "pcMediaName" is a folder or a media file.
  //
  //
  // [CategoryType]
  // Indicates the type of content being passed, possible values are:
  // 0 = Unknown (can be anything)
  // 1 = Movies
  // 2 = TV Shows
  // 3 = Sporting Events
  // 4 = Music
  // The CategoryType parameter can be used to help determine how to
  // better parse the MediaName parameter and how to query the online database.
  //
  //
  // [grabThreadID]
  // Indicates which thread number is currently scraping (useful for debugging).
  //
  //
  // Note:
  // All Meta-Data entries should use a simple VALUE=DATA format,
  // Only one line per entry, for example:
  // TITLE=An interesting movie
  //
  // When multiple lines are required, use the "\n" tag to signify a
  // line break, for example:
  // Overview=Line 1\nLine2\nLine3
  //
  // The exported meta-data text file should be unicode (NOT UTF8) encoded.
  //
  // You can add meta-data entries that Zoom Player does not currently
  // support, Zoom Player will ignore unknown entries. Support for unknown
  // meta-data entries may be integrated into Zoom Player in a new
  // version later on.
  //
  // Try validating your code to ensure there are no stalling points,
  // returning a value as soon as possible is required for smooth
  // operation.
  //
  // Return either true or false to indicate scraping success/failure.
  // Do not create a data file on failure.



  // Here is sample code to grab meta-data from TheMovieDB.org,
  // to prevent conflicts, The API key is not included, you can
  // sign up for your own key through TheMovieDB.org web site.

  Result := SCRAPE_RESULT_NOT_FOUND;
  If (InitSuccess = True) and (pcMediaName <> '') and (pcDataPath <> '') and (pcDataFile <> '') then
  Begin
    SkipSearchForTVShowID := False;

    Media_Name     := pcMediaName;
    Data_Path      := UTF8Decode(pcDataPath);
    //Image_File     := UTF8Decode(pcImageFile);
    Poster_File    := UTF8Decode(pcPosterFile);
    Backdrop_File  := UTF8Decode(pcBackdropFile);
    Still_File     := UTF8Decode(pcStillFile);
    Data_File      := UTF8Decode(pcDataFile);

    // Strip backslash from folder names as needed
    If (IsFolder = True) and (Media_Name[Length(Media_Name)] = '\') then Media_Name := Copy(Media_Name,1,Length(Media_Name)-1);

    // Split path and name
    Media_Path := WideExtractFilePath(UTF8Decode(Media_Name));
    Media_Name := ExtractFileName(Media_Name);


    // Reset metadata record
    With MetaData do
    Begin
      tmdbID           := -1;
      tmdbIMDBID       := '';
      tmdbTitle        := '';
      tmdbTVShowName   := '';
      tmdbReleaseDate  := '';
      tmdbReleaseYear  := -1;
      tmdbRuntime      := -1;
      tmdbRating       := '';
      tmdbGenre        := '';
      tmdbDirector     := '';
      tmdbCast         := '';
      tmdbOverView     := '';
      tmdbPosterPath   := '';
      tmdbBackdropPath := '';
      tmdbStillPath    := '';
    End;

    // Parse the media name
    sParsed := ParseMediaName(Media_Name,Media_Path,IsFolder,CategoryType,mdMediaNameYear,mdMediaNameMonth,mdMediaNameDay,mdMediaNameSeason,mdMediaNameEpisode,mdMediaNameRes);
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Input name "'+UTF8Decode(Media_Name)+'"');{$ENDIF}
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Parsed name "'+sParsed+'"'+', Resolution: '+mdMediaNameRes+', Year: '+IntToStr(mdMediaNameYear)+', Month: '+IntToStr(mdMediaNameMonth)+', Day: '+IntToStr(mdMediaNameDay)+', Season: '+IntToStr(mdMediaNameSeason)+', Episode: '+IntToStr(mdMediaNameEpisode));{$ENDIF}

    // Try finding an IMDB ID in any ".NFO" files within the folder or next to the media file
    If IsFolder = True then
      IMDB_ID := FindIMDBIDInNFOFiles(AddBackSlash(Media_Path)+Media_Name, '') else
      IMDB_ID := FindIMDBIDInNFOFiles(Media_Path, Media_Name);
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','IMDB ID: '+IntToStr(IMDB_ID));{$ENDIF}

    If (IMDB_ID = -1) and ((sParsed = '') or
                           (    IsFolder and (Length(Media_Name)                       < MinMediaNameLengthForScrapingByName)) or
                           (not IsFolder and (Length(ExtractFileNameNoExt(Media_Name)) < MinMediaNameLengthForScrapingByName))) then
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Scrape aborted - no IMDB_ID and name too short/empty');{$ENDIF}
      Exit;
    End;

    sList  := TStringList.Create;
    mdList := TTNTStringList.Create;

    // Set HTTP secured if enabled
    If SecureHTTP = True then sSecure := 's' else sSecure := '';

    // Set which search type we're performing
    Case CategoryType of
      osmMovies  :
      Begin
        If IMDB_ID > -1 then
        Begin
          If SearchTheMovieDB_MovieByIMDBID(IMDB_ID,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF}) = True then
          Begin
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Search by IMDB ID success');{$ENDIF}
          End
          {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Search by IMDB ID failed'){$ENDIF};
        End
          else
        Begin
          SearchTheMovieDB_MovieByName(sParsed,mdMediaNameYear,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF});
        End;
      End;
      osmTV      ,
      osmSports  :
      Begin
        tmpTVShowBackdropPath := '';
        tmpTVShowGenre := '';
        // Find TV Show ID in the cache
        csQuery.Enter;
        Try
          For I := 0 to TVSeriesIDList.Count-1 do If WideCompareText(sParsed,PTVSeriesIDRecord(TVSeriesIDList[I])^.tvName) = 0 then
          Begin
            // TV Show ID was found in the cache
            MetaData.tmdbID := PTVSeriesIDRecord(TVSeriesIDList[I])^.tvID;
            MetaData.tmdbTVShowName := PTVSeriesIDRecord(TVSeriesIDList[I])^.tvShowName;
            tmpTVShowBackdropPath := PTVSeriesIDRecord(TVSeriesIDList[I])^.tvShowBackdropPath;
            tmpTVShowGenre := PTVSeriesIDRecord(TVSeriesIDList[I])^.tvShowGenre;
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','TV Show ID (from cache): '+IntToStr(MetaData.tmdbID)+' TV Show Name (from cache): '+MetaData.tmdbTVShowName+' TV Show Backdrop Path (from cache): '+MetaData.tmdbBackdropPath);{$ENDIF}
            Break;
          End;
        Finally
          csQuery.Leave;
        End;

        // TV Show ID was not found in the cache, Search for TV Show ID
        If MetaData.tmdbID = -1 then
        Begin
          SearchTheMovieDB_TVShowByName(sParsed,mdMediaNameYear,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF});
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','TV Show ID: '+IntToStr(MetaData.tmdbID));{$ENDIF}
          SkipSearchForTVShowID := True;
          tmpTVShowBackdropPath := MetaData.tmdbBackdropPath;
          tmpTVShowGenre := MetaData.tmdbGenre;
        End;

        // TV Show ID was found either in cache or through the online database
        If MetaData.tmdbID > -1 then
        Begin
          // Check if we parsed a specific season and episode numbers from the file name
          If (mdMediaNameSeason > -1) then
          Begin
            If (mdMediaNameEpisode = -1) then
            Begin
              // Search for TV Season information and still or poster image
              If SearchTheMovieDB_TVSeasonByID(MetaData.tmdbID,mdMediaNameSeason,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF}) = True then
              Begin
                if MetaData.tmdbBackdropPath = '' then MetaData.tmdbBackdropPath := tmpTVShowBackdropPath;
                if MetaData.tmdbGenre = '' then MetaData.tmdbGenre := tmpTVShowGenre;
              End
                else
              Begin
                MetaData.tmdbID := -1; // clear the tmdbID to designate the failed scraping
              End;
            End
              else
            Begin
              // Search for a specific TV season & episode
              If SearchTheMovieDB_TVEpisodeByID(MetaData.tmdbID,mdMediaNameSeason,mdMediaNameEpisode,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF}) = True then
              Begin
                if MetaData.tmdbGenre = '' then MetaData.tmdbGenre := tmpTVShowGenre;
              End
                else
              Begin
                MetaData.tmdbID := -1; // clear the tmdbID to designate the failed scraping
              End;
            End;
          End
            else
          Begin
            if SkipSearchForTVShowID = False then
            Begin
              SearchTheMovieDB_TVShowByID(MetaData.tmdbID,SecureHTTP,sList,MetaData,LastErrorCode{$IFDEF LOCALTRACE},grabThreadID{$ENDIF});
            End;
          End;
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','No TV show ID found');{$ENDIF}
        End;
      End;
      // Case ELSE, search for everything:
    else
      Begin
        //for the moment we better not search for everything - we don't know what kind of results we'll get and how to process them
        //sQueryURL := 'http'+sSecure+'://api.themoviedb.org/3/search/multi?api_key='+TheMovieDB_APIKey+'&query='+sQuery;
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Usupported CategoryType: '+IntToStr(CategoryType));{$ENDIF}
      End;
    End;


    // Create folder image by grabbing the poster image from the database.
    // http://[base_url]/[poster_size]/[poster_path]
    //
    // backdrop example : http://image.tmdb.org/t/p/w780/aKz3lXU71wqdslC1IYRC3yHD6yw.jpg

    if MetaData.tmdbID > 0 then
    Begin
      // Only save MetaData file if a file name is specified
      If Data_File <> '' then
      Begin
        If mdMediaNameEpisode > -1 then mdList.Add(mdfPrefix+mdfMediaNameEpisodeStr+'='+IntToStr(mdMediaNameEpisode));
        If mdMediaNameSeason  > -1 then mdList.Add(mdfPrefix+mdfMediaNameSeasonStr +'='+IntToStr(mdMediaNameSeason));
        If mdMediaNameYear    > -1 then mdList.Add(mdfPrefix+mdfMediaNameYearStr   +'='+IntToStr(mdMediaNameYear));

        {If MetaData.tmdbID                > -1 then} mdList.Add(mdfPrefix+mdfDBIDStr        +'='+ IntToStr(MetaData.tmdbID)          );
        {If MetaData.tmdbID                > -1 then} mdList.Add(mdfPrefix+mdfIMDBIDStr      +'='+          MetaData.tmdbIMDBID       );
        {If MetaData.tmdbTitle            <> '' then} mdList.Add(mdfPrefix+mdfTitleStr       +'='+          MetaData.tmdbTitle        );
        {If MetaData.tmdbTVShowName       <> '' then} mdList.Add(mdfPrefix+mdfTVShowNameStr  +'='+          MetaData.tmdbTVShowName   );
        {If MetaData.tmdbReleaseDate      <> '' then} mdList.Add(mdfPrefix+mdfReleaseDateStr +'='+          MetaData.tmdbReleaseDate  );
//        {If MetaData.tmdbReleaseYear       > -1 then} mdList.Add(mdfPrefix+mdfReleaseYearStr +'='+ IntToStr(MetaData.tmdbReleaseYear) );
        {If MetaData.tmdbRuntime           > -1 then} mdList.Add(mdfPrefix+mdfRuntimeStr     +'='+ IntToStr(MetaData.tmdbRuntime)     );
        {If MetaData.tmdbRating           <> '' then} mdList.Add(mdfPrefix+mdfRatingStr      +'='+          MetaData.tmdbRating       );
        {If MetaData.tmdbGenre            <> '' then} mdList.Add(mdfPrefix+mdfGenreStr       +'='+          MetaData.tmdbGenre        );
        {If MetaData.tmdbDirector         <> '' then} mdList.Add(mdfPrefix+mdfDirectorStr    +'='+          MetaData.tmdbDirector     );
        {If MetaData.tmdbCast             <> '' then} mdList.Add(mdfPrefix+mdfCastStr        +'='+          MetaData.tmdbCast         );
        {If MetaData.tmdbOverView         <> '' then} mdList.Add(mdfPrefix+mdfOverViewStr    +'='+          MetaData.tmdbOverView     );

        Try
          // Create the destination folder if it doesn't exist
          If WideDirectoryExists(Data_Path) = False then WideForceDirectories(Data_Path);

          mdList.SaveToFile(Data_Path+Data_File);
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Created meta-data file "'+Data_Path+Data_File+'" '+IntToStr(mdList.Count)+' lines');{$ENDIF}
        Except
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Exception trying to save meta-data file "'+Data_Path+Data_File+'"');{$ENDIF}
        End;
      End;

      If SecureHTTP = True then sSecure := Secure_BaseURL else sSecure := BaseURL;
      If (MetaData.tmdbPosterPath <> '') and (Poster_File <> '') then
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download URL : "'+sSecure+Poster_Size+MetaData.tmdbPosterPath+'"');{$ENDIF}
        If DownloadImageToFile(sSecure+Poster_Size+MetaData.tmdbPosterPath, Data_Path, Poster_File,sDownloadStatus,LastErrorCode,tmdbQueryInternetTimeout) = True then
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download Successful "'+Data_Path+Poster_File+'"');{$ENDIF}
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Failed to download image.'){$ENDIF};
        End;
      End;
      If (MetaData.tmdbBackdropPath <> '') and (Backdrop_File <> '') then
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download URL : "'+sSecure+Backdrop_Size+MetaData.tmdbBackdropPath+'"');{$ENDIF}
        If DownloadImageToFile(sSecure+Backdrop_Size+MetaData.tmdbBackdropPath, Data_Path, Backdrop_File,sDownloadStatus,LastErrorCode,tmdbQueryInternetTimeout) = True then
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download Successful "'+Data_Path+Backdrop_File+'"');{$ENDIF}
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Failed to download image.'){$ENDIF};
        End;
      End;
      If (MetaData.tmdbStillPath <> '') and (Still_File <> '') then
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download URL : "'+sSecure+Still_Size+MetaData.tmdbStillPath+'"');{$ENDIF}
        If DownloadImageToFile(sSecure+Still_Size+MetaData.tmdbStillPath, Data_Path, Still_File,sDownloadStatus,LastErrorCode,tmdbQueryInternetTimeout) = True then
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Download Successful "'+Data_Path+Still_File+'"');{$ENDIF}
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Failed to download image.'){$ENDIF};
        End;
      End;

      {$IFDEF LOCALTRACE}
      If (MetaData.tmdbPosterPath = '') and (MetaData.tmdbBackdropPath = '') and (MetaData.tmdbStillPath = '') then
        DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','No images found for search: Parsed name "'+sParsed+'"'+', Resolution: '+mdMediaNameRes+', Year: '+IntToStr(mdMediaNameYear)+', Month: '+IntToStr(mdMediaNameMonth)+', Day: '+IntToStr(mdMediaNameDay)+', Season: '+IntToStr(mdMediaNameSeason)+', Episode: '+IntToStr(mdMediaNameEpisode)+' !')
      else
        DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','Scrape successful for input name: "'+UTF8Decode(Media_Name)+'"');
      {$ENDIF};

      Result := SCRAPE_RESULT_SUCCESS;
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','MetaData.tmdbTitle is Empty after Scraping for input name: "'+UTF8Decode(Media_Name)+'"'){$ENDIF};

    sList.Free;
    mdList.Free;
  End;
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\'+IntToStr(grabThreadID)+'_ScrapeTheMovieDB.txt','ScrapeDB End (Result: '+IntToStr(Result)+'; LastErrorCode: '+IntToStr(LastErrorCode)+')'+CRLF+CRLF);{$ENDIF}

  If LastErrorCode <> 0 then
    // System Error Codes - https://msdn.microsoft.com/en-us/library/windows/desktop/ms681381%28v=vs.85%29.aspx
    If (LastErrorCode >= INTERNET_ERROR_BASE) and (LastErrorCode <= 12175) then  // ERROR_INTERNET_* from WinInet
      Result := SCRAPE_RESULT_ERROR_INTERNET
    Else
      If LastErrorCode > 0 then
        Result := SCRAPE_RESULT_ERROR_OTHER
      else
        Result := LastErrorCode;
  ;
  
end;


exports
   InitScraper,
   FreeScraper,
   CanConfigure,
   ScrapeDB,
   Configure;


begin
end.
