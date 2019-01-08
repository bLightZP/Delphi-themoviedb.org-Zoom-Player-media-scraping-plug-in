{$I SCRAPER_DEFINES.INC}

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
        to handle a few unicode tasks. }


unit themoviedb_search_unit;

interface

uses
  Classes,
  SyncObjs,
  TNTClasses,
  {$IFDEF LOCALTRACE}msgdlgunit,{$ENDIF}
  Windows;


Const
  {$I TheMovieDB_APIKey.inc}
  {$I iso639.inc}
  maxReleaseYearDeviation = 2;
  maxCastCount = 10;

  tmdbQueryInternetTimeout = 0; // milliseconds

  SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE = -10; // Failed to scrape (Error from OnlineDB)
  SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED = -401; // Failed to scrape (OnlineDB returned status = 401 - Unauthorized)
  SCRAPE_RESULT_ERROR_DB_OTHER_ERROR = -999; // Failed to scrape (OnlineDB returned status <> 200 - OK or there was some unrecognized error)

  {$IFDEF LOCALTRACE}
  CRLF                    = #13+#10;
  {$ENDIF}

Type
  TtmdbMetaDataRecord =
  Record
    tmdbID               : Integer;
    tmdbIMDBID           : String;
    tmdbTitle            : WideString;
    tmdbTVShowName       : WideString;
    tmdbReleaseDate      : WideString;
    tmdbReleaseYear      : Integer;
    tmdbRuntime          : Integer;
    tmdbRating           : String;
    tmdbGenre            : WideString;
    tmdbDirector         : WideString;
    tmdbCast             : WideString;
    tmdbOverView         : WideString;
    tmdbPosterPath       : String;
    tmdbBackdropPath     : String;
    tmdbStillPath        : String;
  End;

  TTVSeriesIDRecord =
  Record
    tvName             : WideString;
    tvID               : Integer;
    tvShowName         : WideString;
    tvShowBackdropPath : String;
    tvShowGenre        : WideString;
  End;
  PTVSeriesIDRecord = ^TTVSeriesIDRecord;


var
  Poster_Size      : String = 'w500'; // Download 500px poster width size by default
//  Backdrop_Size    : String = 'w1280'; // Download 1280px backdrop width size by default
  Backdrop_Size    : String = 'original'; // Download "original" backdrop width size by default
//  Still_Size       : String = 'w300'; // Download 300px still image width size by default
  Still_Size       : String = 'original'; // Download "original" still image width size by default
  csQuery          : TCriticalSection;
  TVSeriesIDList   : TList       = nil;
  QueryTSList      : TList       = nil;
  BaseURL          : String;
  Secure_BaseURL   : String;
  InitSuccess      : Boolean = False;
  PosterSizeList   : TStringList = nil;
  BackdropSizeList : TStringList = nil;
  StillSizeList    : TStringList = nil;
  MaxDBPageResults : Integer = 1;
  ISO639Language   : Integer = 0; // default

procedure AddLanguageCode(var S : String);
function DownloadConfiguration(Secured : Boolean): Boolean;

function SearchTheMovieDB_TVShowByID(iID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_TVShowByName(sName: WideString; MediaNameYear : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_TVSeasonByID(iID, iSeason : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_TVEpisodeByID(iID, iSeason, iEpisode : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_TVShowByIMDBID(iIMDBID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;

function SearchTheMovieDB_MovieByID(iID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_MovieByName(sName: WideString; MediaNameYear : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
function SearchTheMovieDB_MovieByIMDBID(iIMDBID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;



implementation


uses
  SysUtils, TNTSysUtils, SuperObject, TheMovieDB_misc_utils_unit, global_consts;

const
  // Strings used to identify JSON results
  tmdbIDStr                      : String = 'id';
  tmdbIMDBIDStr                  : String = 'imdb_id';
  tmdbMovieTitleStr              : String = 'title';
  tmdbTVTitleStr                 : String = 'name';
  tmdbReleaseDateStr             : String = 'release_date';
  tmdbTVShowReleaseStr           : String = 'first_air_date';
  tmdbTVEpisodeReleaseStr        : String = 'air_date';
  tmdbRuntimeStr                 : String = 'runtime';
  tmdbRatingStr                  : String = 'vote_average';
  tmdbOverviewStr                : String = 'overview';
  tmdbPosterPathStr              : String = 'poster_path';
  tmdbStillPathStr               : String = 'still_path';
  tmdbBackdropPathStr            : String = 'backdrop_path';

  tmdbMovieResultsStr            : String = 'movie_results';
  tmdbTVResultsStr               : String = 'tv_results';
  tmdbGenresStr                  : String = 'genres';
  tmdbCreditsStr                 : String = 'credits';
  tmdbCrewResultStr              : String = 'crew';
  tmdbCrewJobStr                 : String = 'job';
  tmdbDirectorJobStr             : String = 'Director';
  tmdbCastResultStr              : String = 'cast';
  tmdbGenreOrCastOrCrewIDStr     : String = 'id';
  tmdbGenreOrCastOrCrewNameStr   : String = 'name';


procedure AddLanguageCode(var S : String);
const
  lStr : String = '&language=';
begin
  If (ISO639Language > 0) and (Pos(lStr,S) = 0) then S := S+lStr+ISO639_2Codes[ISO639Language];
end;


procedure CheckAndAddToSearchLimitList;
var
  qTS      : PInt64;
  I,qCount : Integer;
begin
  // Check that we're not overloading TheMovieDB's system (they request to limit to 40 requests in 10 seconds)
  New(qTS);
  Repeat
    qTS^   := TickCount64;
    qCount := 0;

    // Enter criticial section to prevent thread conflicts
    csQuery.Enter;
    Try
      For I := QueryTSList.Count-1 downto 0 do
      Begin
        If qTS^-PInt64(QueryTSList[I])^ > 10000 + 1000 then // we are adding one more second just to ensure a bit of headroom
        Begin
          // Delete entries older than 10 seconds
          Dispose(PInt64(QueryTSList[I]));
          QueryTSList.Delete(I);
        End
        Else Inc(qCount); // Count entries under 10 seconds
      End;
      If qCount >= 36 then Sleep(10);
    Finally
      csQuery.Leave;
    End;
  Until qCount < 36; // using 36 search entries instead of 40 to ensure a bit of headroom.

  // Add current search to the limit list
  csQuery.Enter;
  Try
    QueryTSList.Add(qTS);
  Finally
    csQuery.Leave;
  End;
end;


function DownloadConfiguration(Secured : Boolean): Boolean;
var
  jBase       : ISuperObject;
  jBaseImages : ISuperObject;
  jBaseRez    : ISuperObject;
  sSecure     : String;
  I           : Integer;
  tmpRes      : Boolean;
  sList       : TStringList;
  {$IFNDEF LOCALTRACE}
  sDownloadStatus: String;
  ErrorCode   : Integer;
  {$ENDIF}
begin
  Result := False;

  If Secured = True then sSecure := 's' else sSecure := '';
  sList :=  TStringList.Create;
  // Get Initial configuration (contains URL information for grabbing images):
  {$IFDEF LOCALTRACE}
  // When debugging, there's no need to query the database for configuration each time, this is the configuration value returned Dec. 2nd 2015:
  sList.Add('{"images":{"base_url":"http://image.tmdb.org/t/p/","secure_base_url":"https://image.tmdb.org/t/p/","backdrop_sizes":["w300","w780","w1280","original"],'+
            '"logo_sizes":["w45","w92","w154","w185","w300","w500","original"],"poster_sizes":["w92","w154","w185","w342","w500","w780","original"],'+
            '"profile_sizes":["w45","w185","h632","original"],"still_sizes":["w92","w185","w300","original"]},"change_keys":["adult","air_date","also_known_as",'+
            '"alternative_titles","biography","birthday","budget","cast","certifications","character_names","created_by","crew","deathday","episode","episode_number",'+
            '"episode_run_time","freebase_id","freebase_mid","general","genres","guest_stars","homepage","images","imdb_id","languages","name","network","origin_country"'+
            ',"original_name","original_title","overview","parts","place_of_birth","plot_keywords","production_code","production_companies","production_countries",'+
            '"releases","revenue","runtime","season","season_number","season_regular","spoken_languages","status","tagline","title","translations","tvdb_id","tvrage_id","type","video","videos"]}');
  tmpRes := True;
  {$ELSE}
  CheckAndAddToSearchLimitList;
  tmpRes := DownloadFileToStringList('http'+sSecure+'://api.themoviedb.org/3/configuration?api_key='+TheMovieDB_APIKey,sList,sDownloadStatus,ErrorCode,tmdbQueryInternetTimeout);
  {$ENDIF}
  If tmpRes = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Configuration downloaded');{$ENDIF}
    If sList.Count > 0 then
    Begin
      //jBase := SO('['+sList[0]+']');
      jBase := SO(sList[0]);
      If jBase <> nil then
      Begin
        jBaseImages := jBase.O['images'];
        If jBaseImages <> nil then
        Begin
          // Get Images base URL
          BaseURL        := jBaseImages.S['base_url'];
          Secure_BaseURL := jBaseImages.S['secure_base_url'];

          If BaseURL <> '' then
          Begin
            Result := True;
            InitSuccess := True;
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Init success');{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Base URL            : '+BaseURL);{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Secure Base URL     : '+Secure_BaseURL);{$ENDIF}

            // Get available Poster sizes
            jBaseRez := jBaseImages.O['poster_sizes'];
            If jBaseRez <> nil then
            Begin
              For I := 0 to jBaseRez.AsArray.Length-1 do PosterSizeList.Add(jBaseRez.AsArray.S[I]);
              jBaseRez.Clear(True);
              jBaseRez := nil;
              {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Poster Sizes      : '+CRLF+PosterSizeList.Text);{$ENDIF}
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not valid - missing "poster_sizes" section; Response: '+sList.Text){$ENDIF};

            // Get available Backdrop sizes
            jBaseRez := jBaseImages.O['backdrop_sizes'];
            If jBaseRez <> nil then
            Begin
              For I := 0 to jBaseRez.AsArray.Length-1 do BackdropSizeList.Add(jBaseRez.AsArray.S[I]);
              jBaseRez.Clear(True);
              jBaseRez := nil;
              {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Backdrop Sizes    : '+CRLF+BackdropSizeList.Text);{$ENDIF}
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not valid - missing "backdrop_sizes" section; Response: '+sList.Text){$ENDIF};

            // Get available Still image sizes
            jBaseRez := jBaseImages.O['still_sizes'];
            If jBaseRez <> nil then
            Begin
              For I := 0 to jBaseRez.AsArray.Length-1 do StillSizeList.Add(jBaseRez.AsArray.S[I]);
              jBaseRez.Clear(True);
              jBaseRez := nil;
              {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Still Image Sizes : '+CRLF+StillSizeList.Text);{$ENDIF}
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not valid - missing "still_sizes" section; Response: '+sList.Text){$ENDIF};
          End
          {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not valid - missing "base_url" value; Response: '+sList.Text){$ENDIF};
          jBaseImages.Clear(True);
          jBaseImages := nil;
        End
        {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not valid - missing "images" section; Response: '+sList.Text){$ENDIF};
        jBase.Clear(True);
        jBase := nil;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration is not JSON Object; Response: '+sList.Text){$ENDIF};
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Downloaded configuration contained no data'){$ENDIF};
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\.ScrapeTheMovieDBInit.txt','Configuration failed to download'){$ENDIF};
  sList.Free;
end;


function JsonToMetaDataRecord(jObject: ISuperObject; CategoryType : Integer; var searchMetaData: TtmdbMetaDataRecord): Boolean;
var
  jAllGenres  : ISuperObject;
  jGenre      : ISuperObject;
  jCredits    : ISuperObject;
  jAllCrew    : ISuperObject;
  jAllCast    : ISuperObject;
  jCastOrCrew : ISuperObject;
  I           : Integer;
begin
  Result := False;
  
  searchMetaData.tmdbID           := jObject.I[tmdbIDStr];                   // Get ID
  If searchMetaData.tmdbID > 0 then
  Begin
    Result := True;
    
    searchMetaData.tmdbIMDBID       := jObject.S[tmdbIMDBIDStr];               // Get IMDB ID ... if available

    searchMetaData.tmdbTitle        := UTF8Decode(jObject.S[tmdbMovieTitleStr]);
    if searchMetaData.tmdbTitle = '' then searchMetaData.tmdbTitle := UTF8Decode(jObject.S[tmdbTVTitleStr]);

    searchMetaData.tmdbReleaseDate  := jObject.S[tmdbReleaseDateStr];              // Get Release Date [YYYY-MM-DD] format
    if searchMetaData.tmdbReleaseDate = '' then searchMetaData.tmdbReleaseDate := jObject.S[tmdbTVShowReleaseStr];
    if searchMetaData.tmdbReleaseDate = '' then searchMetaData.tmdbReleaseDate := jObject.S[tmdbTVEpisodeReleaseStr];

    searchMetaData.tmdbRuntime      := jObject.I[tmdbRuntimeStr];

    searchMetaData.tmdbRating       := jObject.S[tmdbRatingStr];               // Get Rating

    // Get Genres
    searchMetaData.tmdbGenre := '';
    jAllGenres := jObject.O[tmdbGenresStr];
    If jAllGenres <> nil then
    Begin
      For I := 0 to jAllGenres.AsArray.Length-1 do
      Begin
        jGenre := jAllGenres.AsArray[I];
        If jGenre <> nil then
        Begin
          If searchMetaData.tmdbGenre <> '' then searchMetaData.tmdbGenre := searchMetaData.tmdbGenre+';';
          searchMetaData.tmdbGenre := searchMetaData.tmdbGenre+jGenre.S[tmdbGenreOrCastOrCrewIDStr]+'|'+UTF8Decode(jGenre.S[tmdbGenreOrCastOrCrewNameStr]);
          //mitko: do we really need these two rows?
          jGenre.Clear;
          jGenre := nil;
        End;
      End;
      jAllGenres.Clear(True);
      jAllGenres := nil;
    End;

    // Get Credits
    jCredits := jObject.O[tmdbCreditsStr];
    If jCredits <> nil then
    Begin
      jAllCrew := jCredits.O[tmdbCrewResultStr];
      If jAllCrew <> nil then
      Begin
        searchMetaData.tmdbDirector := '';
        For I := 0 to jAllCrew.AsArray.Length-1 do
        Begin
          jCastOrCrew := jAllCrew.AsArray[I];
          If jCastOrCrew <> nil then
          Begin
            if UTF8Decode(jCastOrCrew.S[tmdbCrewJobStr]) = tmdbDirectorJobStr then
            Begin
              if searchMetaData.tmdbDirector <> '' then searchMetaData.tmdbDirector := searchMetaData.tmdbDirector+';';
              searchMetaData.tmdbDirector := searchMetaData.tmdbDirector+jCastOrCrew.S[tmdbGenreOrCastOrCrewIDStr]+'|'+UTF8Decode(jCastOrCrew.S[tmdbGenreOrCastOrCrewNameStr]);
              Break;
            End;
            //mitko: do we really need these two rows?
            jCastOrCrew.Clear;
            jCastOrCrew := nil;
          End;
        End;
        jAllCrew.Clear;
        jAllCrew := nil;
      End;

      jAllCast := jCredits.O[tmdbCastResultStr];
      If jAllCast <> nil then
      Begin
        searchMetaData.tmdbCast := '';
        For I := 0 to jAllCast.AsArray.Length-1 do
        Begin
          jCastOrCrew := jAllCast.AsArray[I];
          If jCastOrCrew <> nil then
          Begin
            If searchMetaData.tmdbCast <> '' then searchMetaData.tmdbCast := searchMetaData.tmdbCast+';';
            searchMetaData.tmdbCast := searchMetaData.tmdbCast+jCastOrCrew.S[tmdbGenreOrCastOrCrewIDStr]+'|'+UTF8Decode(jCastOrCrew.S[tmdbGenreOrCastOrCrewNameStr]);
            If I = maxCastCount then Break;
            //mitko: do we really need these two rows?
            jCastOrCrew.Clear;
            jCastOrCrew := nil;
          End;
        End;
        jAllCast.Clear;
        jAllCast := nil;
      End;
      jCredits.Clear(True);
      jCredits := nil;
    End;


    searchMetaData.tmdbOverView     := TNT_WideStringReplace(UTF8Decode(jObject.S[tmdbOverViewStr]), #10, '\n', [rfReplaceAll]); // Get Overview

    searchMetaData.tmdbPosterPath   := jObject.S[tmdbPosterPathStr]; // Get Poster path
    If searchMetaData.tmdbPosterPath = 'null' then searchMetaData.tmdbPosterPath := '';
    searchMetaData.tmdbBackdropPath := jObject.S[tmdbBackdropPathStr]; // Get Backdrop path
    If searchMetaData.tmdbBackdropPath = 'null' then searchMetaData.tmdbBackdropPath := '';
    searchMetaData.tmdbStillPath    := jObject.S[tmdbStillPathStr]; // Get Still Image path
    If searchMetaData.tmdbStillPath = 'null' then searchMetaData.tmdbStillPath := '';
  End;
end;


function SearchTheMovieDB(sURL : String; sParsed : WideString; CategoryType : Integer; MediaNameYear : Integer; var sList : TStringList; var iID: Integer; var ErrorCode : Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
type
  TdbEntryRecord =
  Record
    dbrPosterPath  : String;
    dbrReleaseYear : Integer;
    dbrTitle       : String;
    dbrID          : Integer;
  End;
  PdbEntryRecord = ^ TdbEntryRecord;

const
  matchbyName              = 0;
  matchbyYear              = 1;
  matchbyMode              : Integer = matchbyYear;

var
  I                        : Integer;
  jObj                     : ISuperObject;
  jResult                  : ISuperObject;
  jResults                 : ISuperObject;
  MediaNameDiffBest        : Integer;
  MediaNameDiffBestIdx     : Integer;
  MediaNameDiff            : Integer;
  MediaYearMatch           : Integer;
  MediaYearMatchIdx        : Integer;
  MediaNameMatch           : Integer;
  MediaNameMatchIdx        : Integer;
  MediaNameAndYearMatchIdx : Integer;
  jStart                   : Integer;
  jEnd                     : Integer;
  sDownloadStatus          : String;
  //dbTitle                  : String;
  dbReleaseDate            : String;
  //dbReleaseYear            : Integer;
  //dbPosterPath             : String;
  dbTotalPages             : Integer;
  dbCurrentPage            : Integer;
  dbEntries                : TList;
  dbNewEntry               : PdbEntryRecord;
  sURLwithPages            : String;

begin
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB (before)');{$ENDIF}
  sDownloadStatus := '';
  Result := False;

  dbCurrentPage            := -1;
  dbTotalPages             := -1;

  jStart                   := -1;
  jEnd                     := -1;

  MediaYearMatch           := MAXINT;
  MediaNameMatch           := MAXINT;
  MediaNameDiffBest        := MAXINT;
  MediaNameDiffBestIdx     := -1;
  MediaYearMatchIdx        := -1;
  MediaNameMatchIdx        := -1;
  MediaNameAndYearMatchIdx := -1;

  dbEntries := TList.Create;


  // Download all result pages
  Repeat
    AddLanguageCode(sURL);

    If dbCurrentPage <> -1 then sURLwithPages := sURL+'&page='+IntToStr(dbCurrentPage+1) else sURLwithPages := sURL;

    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','CheckAndAddToSearchLimitList');{$ENDIF}
    CheckAndAddToSearchLimitList;
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Download URL "'+sURLwithPages+'"');{$ENDIF}
    If DownloadFileToStringList(sURLwithPages,sList,sDownloadStatus,ErrorCode,tmdbQueryInternetTimeout{$IFDEF LOCALTRACE},ThreadID{$ENDIF}) then
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Download successful');{$ENDIF}
      If sList.Count > 0 then
      Begin
        // Sample result:
        //
        //{"page":1,"results":[{"adult":false,"backdrop_path":"/9NmTVqQ9f2ltecPZgXIj4Bk2c6s.jpg","genre_ids":[28,35,80],"id":187017,"original_language":"en","original_title":"22 Jump Street",
        // "overview":"After making their way through high school (twice), big changes are in store for officers Schmidt and Jenko when they go deep undercover at a local college. But when Jenko meets a kindred spirit on the football team, and Schmidt infiltrates the bohemian art major scene, they begin to question their partnership. Now they don''t have to just crack the case - they have to figure out if they can have a mature elationship. If these two overgrown adolescents can grow from freshmen into real men, college might be the best thing that ever happened to them.",
        // "release_date":"2014-06-13","poster_path":"/gNlV5FhDZ1PjxSv2aqTPS30GEon.jpg","popularity":1.984608,"title":"22 Jump Street","video":false,"vote_average":7.1,
        // "vote_count":1570,"media_type":"movie"}],"total_pages":1,"total_results":1}

        jObj := SO(sList[0]);
        If jObj <> nil then
        Begin
          dbCurrentPage := jObj.I['page'];
          dbTotalPages  := jObj.I['total_pages'];
          jResults      := jObj.O['results'];

          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Page : '+IntToStr(dbCurrentPage)+'/'+IntToStr(dbTotalPages));{$ENDIF}

          If jResults <> nil then
          Begin
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Got results');{$ENDIF}

            // Try to find the best entry by matching the release date to the media file name's year if one exists
            For I := 0 to jResults.AsArray.Length-1 do
            Begin
              jResult := jResults.AsArray[I];
              If jResult <> nil then
              Begin
                New(dbNewEntry);

                // To help make the match, we need a title, a valid poster path and a release date

                If CategoryType = osmTV then
                  dbNewEntry^.dbrTitle := ConvertCharsToSpaces(UTF8Decode(jResult.S[tmdbTVTitleStr])) else // Get Name
                  dbNewEntry^.dbrTitle := ConvertCharsToSpaces(UTF8Decode(jResult.S[tmdbMovieTitleStr]));  // Get Title

                If CategoryType = osmTV then dbReleaseDate := jResult.S[tmdbTVShowReleaseStr] // Get Release Date [YYYY/MM/DD] format
                  else dbReleaseDate := jResult.S[tmdbReleaseDateStr]; // Get Release Date [YYYY/MM/DD] format
                If (dbReleaseDate <> '') and (Length(dbReleaseDate) > 4) then dbNewEntry^.dbrReleaseYear := StrToIntDef(Copy(dbReleaseDate,1,4),-1) else dbNewEntry^.dbrReleaseYear := -1;

                dbNewEntry^.dbrPosterPath := jResult.S[tmdbPosterPathStr]; // Get Poster path
                If dbNewEntry^.dbrPosterPath = 'null' then dbNewEntry^.dbrPosterPath := '';

                dbNewEntry^.dbrID := jResult.I[tmdbIDStr]; // Get movie ID

                dbEntries.Add(dbNewEntry);

                jResult.Clear;
                jResult := nil;
              End
                else
              Begin
                {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not valid - missing "result" section; Response: '+sList.Text);{$ENDIF}
                ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
              End;
            End;
            jResults.Clear;
            jResults := nil;
          End
            else
          Begin
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not valid - missing "results" section; Response: '+sList.Text);{$ENDIF}
            ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
          End;
          jObj.Clear;
          jObj := nil;
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not JSON Object; Response: '+sList.Text);{$ENDIF}
          ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
        End;
      End
        else
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Download returned no data; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
        ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
      End;
    End
      else
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error downloading "'+sURL+'"!; ErrorCode: '+IntToStr(ErrorCode)+'; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
      if ErrorCode = 0 then
        If sDownloadStatus = '401' then
          ErrorCode := SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED
        else
          ErrorCode := SCRAPE_RESULT_ERROR_DB_OTHER_ERROR;
    End;
  Until (ErrorCode <> S_OK) or (dbCurrentPage = dbTotalPages) or (dbCurrentPage = MaxDBPageResults);

  // Scan results for best match
  For I := 0 to dbEntries.Count-1 do with PdbEntryRecord(dbEntries[I])^ do
  Begin
    // Try to find a title that exactly matches the media name
    MediaNameDiff := WideCompareText(sParsed,dbrTitle);
    If (MediaNameDiff = 0) then
    Begin
      If (MediaNameMatchIdx = -1) and (dbrPosterPath <> '') then MediaNameMatchIdx := I;

      // Try to find closest release year to our name based year that still exactly matches the media name
      If (MediaNameYear > -1) and (dbrReleaseYear > -1) and (dbrPosterPath <> '') then
        If (Abs(MediaNameYear-dbrReleaseYear) < MediaYearMatch) and (Abs(MediaNameYear-dbrReleaseYear) <= maxReleaseYearDeviation) then
      Begin
        MediaYearMatch    := Abs(MediaNameYear-dbrReleaseYear);
        MediaNameAndYearMatchIdx := I;
        // If we find an exact match there is no need to continue searching
        If MediaYearMatch = 0 then Break;
      End;
    End
      else
    Begin
      If (dbrPosterPath <> '') then
      Begin
        MediaNameDiff := LevenshteinDistance(sParsed,dbrTitle);
        If MediaNameDiff < MediaNameDiffBest then
        Begin
          MediaNameDiffBest    := MediaNameDiff;
          MediaNameDiffBestIdx := I;
        End;

        // Try to find the best matching year with least diff on name
        If (MediaNameYear > -1) and (dbrReleaseYear = MediaNameYear) and (dbrPosterPath <> '') and (MediaNameDiff > -1) then
        Begin
          If MediaNameDiff < MediaNameMatch then
          Begin
            MediaNameMatch    := MediaNameDiff;
            MediaYearMatchIdx := I;
          End;
        End;
      End;
    End;
  End;

  If (MediaNameAndYearMatchIdx > -1) and ((MediaYearMatch = 0) or (matchbyMode = matchbyName)) then
  Begin
    // Found a "perfect" match, use a specific result
    jStart := MediaNameAndYearMatchIdx;
    jEnd   := MediaNameAndYearMatchIdx;
  End
    else
  If (MediaYearMatchIdx > -1) and (matchbyMode = matchbyYear) and (MediaNameMatch > -1) then
  Begin
    // Found a year match, use a specific result
    jStart := MediaYearMatchIdx;
    jEnd   := MediaYearMatchIdx;
  End
    else
  If (MediaNameAndYearMatchIdx > -1) and (matchbyMode = matchbyYear) then
  Begin
    jStart := MediaNameAndYearMatchIdx;
    jEnd   := MediaNameAndYearMatchIdx;
  End
    else
  If MediaNameMatchIdx > -1 then
  Begin
    // Found a good match, use a specific result
    jStart := MediaNameMatchIdx;
    jEnd   := MediaNameMatchIdx;
  End
    else
  If (MediaNameDiffBest < MAXINT) then
  Begin
    jStart := MediaNameDiffBestIdx;
    jEnd   := MediaNameDiffBestIdx;
  End
    else
  Begin
    // No match, scan all results
    jStart := 0;
    jEnd   := dbEntries.Count-1;
  End;

  If (jStart > -1) and (jEnd > -1) then
  Begin
    // Run through multiple results until we find the first one with a poster
    For I := jStart to jEnd do with PdbEntryRecord(dbEntries[I])^ do
    Begin
      If (dbrPosterPath <> '') then
      Begin
        Result := True;
        iID    := dbrID;
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TMDB ID: "'+IntToStr(iID)+'"');{$ENDIF}
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Poster path "'+dbrPosterPath+'"');{$ENDIF}

        Break;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Skipping result #'+IntToStr(I)+' - no poster'){$ENDIF};
    End;
  End;

  For I := 0 to dbEntries.Count-1 do Dispose(PdbEntryRecord(dbEntries[I]));
  dbEntries.Free;

  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB (after)');{$ENDIF}
end;


function SearchTheMovieDB_TVByURL(sURL : String; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  jObj            : ISuperObject;
  sDownloadStatus : String;
begin
  sDownloadStatus := '';
  Result := False;

  AddLanguageCode(sURL);

  //http://api.themoviedb.org/3/tv/[id:]1399/season/[season:]1/episode/[episode:]1?api_key=[apikey]
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TV Search URL : "'+sURL+'"');{$ENDIF}
  CheckAndAddToSearchLimitList;
  If DownloadFileToStringList(sURL,sList,sDownloadStatus,ErrorCode,tmdbQueryInternetTimeout{$IFDEF LOCALTRACE},ThreadID{$ENDIF}) = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Download successful');{$ENDIF}
    If sList.Count > 0 then
    Begin
      // Sample result:
      //
      // {"air_date":"2011-04-17","crew":[{"id":44797,"credit_id":"5256c8a219c2956ff6046e77","name":"Tim Van Patten","department":"Directing","job":"Director",
      // "profile_path":"/6b7l9YbkDHDOzOKUFNqBVaPjcgm.jpg"},{"id":1318704,"credit_id":"54eef2429251417974005cb6","name":"Alik Sakharov",
      // "department":"Camera","job":"Director of Photography","profile_path":"/50ZlHkh66aOPxQMjQ21LJDAkYlR.jpg"},
      // {"id":18077,"credit_id":"54eef2ab925141795f005d4f","name":"Oral Norrie Ottey","department":"Editing",
      // "job":"Editor","profile_path":null},{"id":9813,"credit_id":"5256c8a019c2956ff6046e2b","name":"David Benioff",
      // "department":"Writing","job":"Writer","profile_path":"/8CuuNIKMzMUL1NKOPv9AqEwM7og.jpg"},
      // {"id":228068,"credit_id":"5256c8a219c2956ff6046e4b","name":"D. B. Weiss","department":"Writing","job":"Writer","profile_path":null}],
      // "episode_number":1,"guest_stars":[],"name":"Winter Is Coming",
      // "overview":"Jon Arryn, the Hand of the King, is dead. King Robert Baratheon plans to ask his oldest friend, Eddard Stark, to take Jon's place. Across the sea, Viserys Targaryen plans to wed his sister to a nomadic warlord in exchange for an army.",
      // "id":63056,"production_code":"101","season_number":1,"still_path":"/wrGWeW4WKxnaeA8sxJb2T9O6ryo.jpg","vote_average":8.53571428571429,"vote_count":14}

      jObj := SO(sList[0]);
      If jObj <> nil then
      Begin
        with searchMetaData do
        Begin
          If JsonToMetaDataRecord(jObj, osmTV, searchMetaData) then
          Begin
            Result := True;

            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TV Poster path   "'+tmdbPosterPath+'"');{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TV Backdrop path "'+tmdbBackdropPath+'"');{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TV Still path    "'+tmdbStillPath+'"');{$ENDIF}
          End
            else
          Begin
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not a valid response - missing "'+tmdbIDStr+'" value; Response: '+sList.Text);{$ENDIF}
            ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
          End;

          jObj.Clear;
          jObj := nil;
        End;
      End
        else
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','jObj = nil!!!; Response: '+sList.Text);{$ENDIF}
      End;
    End
      else
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Download returned no data; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
      ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
    End;
  End
    else
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error downloading "'+sURL+'"!; ErrorCode: '+IntToStr(ErrorCode)+'; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
    if ErrorCode = 0 then
      If sDownloadStatus = '401' then
        ErrorCode := SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED
      else
        ErrorCode := SCRAPE_RESULT_ERROR_DB_OTHER_ERROR;
  End;
end;


function SearchTheMovieDB_TVShowByName(sName: WideString; MediaNameYear : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure, sQueryURL : String;
  TVShowID           : Integer;
  I1                 : Integer;
  IDEntry            : PTVSeriesIDRecord;
begin
  If Secured = True then sSecure := 's' else sSecure := '';
  sQueryURL := 'http'+sSecure+'://api.themoviedb.org/3/search/tv?api_key='+TheMovieDB_APIKey+'&query='+URLEncodeUTF8(sName);

  AddLanguageCode(sQueryURL);

  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','TV Show ID Search URL : "'+sQueryURL+'"');{$ENDIF}
  Result := SearchTheMovieDB(sQueryURL,sName,osmTV,MediaNameYear,sList,searchMetaData.tmdbID,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});

  If Result = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_TVShowByID #'+IntToStr(searchMetaData.tmdbID)+' (before)');{$ENDIF}
    Result := SearchTheMovieDB_TVShowByID(searchMetaData.tmdbID,Secured,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_TVShowByID (after)');{$ENDIF}
  End;

  If Result = True then
  Begin
    // When searching for a TV Show (usually a folder), add the result to TV show ID list if the show isn't previously listed
    searchMetaData.tmdbTVShowName := searchMetaData.tmdbTitle;
    TVShowID := -1;
    csQuery.Enter;
    Try
      For I1 := 0 to TVSeriesIDList.Count-1 do If searchMetaData.tmdbID = PTVSeriesIDRecord(TVSeriesIDList[I1])^.tvID then
      Begin
        // We already have this Show's TV id on record
        TVShowID := searchMetaData.tmdbID;
        Break;
      End;
      If TVShowID = -1 then
      Begin
        New(IDEntry);
        IDEntry^.tvID   := searchMetaData.tmdbID;
        IDEntry^.tvName := sName;
        IDEntry^.tvShowName := searchMetaData.tmdbTitle;
        IDEntry^.tvShowBackdropPath := searchMetaData.tmdbBackdropPath;
        IDEntry^.tvShowGenre := searchMetaData.tmdbGenre;

        TVSeriesIDList.Add(IDEntry);
      End;
    Finally
      csQuery.Leave;
    End;
  End;
End;


function SearchTheMovieDB_TVShowByID(iID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure : String;
  sURL    : String;
begin
  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/tv/'+IntToStr(iID)+'?append_to_response=credits&api_key='+TheMovieDB_APIKey;
  AddLanguageCode(sURL);
  Result := SearchTheMovieDB_TVByURL(sURL,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
  If Result = True then searchMetaData.tmdbTVShowName := searchMetaData.tmdbTitle;
End;


function SearchTheMovieDB_TVSeasonByID(iID, iSeason : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure : String;
  sURL    : String;
begin
  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/tv/'+IntToStr(iID)+'/season/'+IntToStr(iSeason)+'?append_to_response=credits&api_key='+TheMovieDB_APIKey;
  AddLanguageCode(sURL);
  Result := SearchTheMovieDB_TVByURL(sURL,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
End;


function SearchTheMovieDB_TVEpisodeByID(iID, iSeason, iEpisode : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean; overload;
var
  sSecure : String;
  sURL    : String;
begin
  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/tv/'+IntToStr(iID)+'/season/'+IntToStr(iSeason)+'/episode/'+IntToStr(iEpisode)+'?append_to_response=credits&api_key='+TheMovieDB_APIKey;
  AddLanguageCode(sURL);
  Result := SearchTheMovieDB_TVByURL(sURL,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
End;


function SearchTheMovieDB_MovieByID(iID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure         : String;
  jObj            : ISuperObject;
  sDownloadStatus : String;
  sURL            : String;
begin
  sDownloadStatus := '';
  Result := False;

  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/movie/'+IntToStr(iID)+'?append_to_response=credits&api_key='+TheMovieDB_APIKey;

  AddLanguageCode(sURL);

  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Search URL :'+CRLF+sURL+CRLF);{$ENDIF}
  CheckAndAddToSearchLimitList;
  If DownloadFileToStringList(sURL,sList,sDownloadStatus,ErrorCode,tmdbQueryInternetTimeout{$IFDEF LOCALTRACE},ThreadID{$ENDIF}) then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Download successful');{$ENDIF}
    If sList.Count > 0 then
    Begin
      // Sample result:
      //
      //{"adult":false,"backdrop_path":"/9NmTVqQ9f2ltecPZgXIj4Bk2c6s.jpg","belongs_to_collection":{"id":212562,"name":"Jump Street Collection","poster_path":"/vufY0iuDNXGEdYOgZNcJFAEZeak.jpg","backdrop_path":"/iiAbTNYXpMadPDH4MkjUoJzcGn4.jpg"},"budget":50000000,
      //"genres":[{"id":80,"name":"Crime"},{"id":35,"name":"Comedy"},{"id":28,"name":"Action"}],
      //"homepage":"http://www.22jumpstreetmovie.com","id":187017,"imdb_id":"tt2294449","original_language":"en","original_title":"22 Jump Street","overview":"After making their way through high school (twice), big changes are in store for officers Schmidt and Jenko when they go deep undercover at a local college. But when Jenko meets a kindred spirit on the football team, and Schmidt infiltrates the bohemian art major scene, they begin to question their partnership. Now they don't have to just crack the case - they have to figure out if they can have a mature relationship. If these two overgrown adolescents can grow from freshmen into real men, college might be the best thing that ever happened to them.",
      //"popularity":3.452685,"poster_path":"/gNlV5FhDZ1PjxSv2aqTPS30GEon.jpg","production_companies":[{"name":"Columbia Pictures","id":5},{"name":"Original Film","id":333},{"name":"Media Rights Capital","id":2531},{"name":"Metro-Goldwyn-Mayer (MGM)","id":8411},{"name":"Cannell Studios","id":9194},{"name":"LStar Capital","id":34034},{"name":"33andOut Productions","id":34035},{"name":"JHF Productions","id":34036}],"production_countries":[{"iso_3166_1":"US","name":"United States of America"}],"release_date":"2014-06-05","revenue":188441614,"runtime":112,"spoken_languages":[{"iso_639_1":"en","name":"English"}],"status":"Released","tagline":"They're not 21 anymore","title":"22 Jump Street","video":false,"vote_average":7.1,"vote_count":1827,
      //"credits":{"cast":[{"cast_id":6,"character":"Schmidt","credit_id":"52fe4d0e9251416c7512e751","id":21007,"name":"Jonah Hill","order":0,"profile_path":"/paKfXGK2gnYHWkqe1NiQR1pGac7.jpg"},{"cast_id":7,"character":"Jenko","credit_id":"52fe4d0e9251416c7512e755","id":38673,"name":"Channing Tatum","order":1,"profile_path":"/5L7BSYbzM8iizvIrS8EaaZoDrI3.jpg"}],
      //"crew":[{"credit_id":"5635fb05c3a3681b5401a992","department":"Editing","id":1530137,"job":"Assistant Editor","name":"Zachary Dehm","profile_path":null},{"credit_id":"5439f4020e0a26499e001a28","department":"Writing","id":58744,"job":"Screenplay","name":"Michael Bacall","profile_path":"/vAqUOjmjY1ALiTRlYu7BI3yWmuK.jpg"},{"credit_id":"52fe4d0e9251416c7512e73b","department":"Directing","id":107446,"job":"Director","name":"Phil Lord","profile_path":"/3xY4veMGydyYHnOG8CjqIg0odi.jpg"},{"credit_id":"52fe4d0e9251416c7512e741","department":"Directing","id":155267,"job":"Director","name":"Chris Miller","profile_path":"/tBJhILp15Gvog1qkeTkYhtb7NBW.jpg"},{"credit_id":"52fe4d0e9251416c7512e747","department":"Production","id":21007,"job":"Producer","name":"Jonah Hill","profile_path":"/paKfXGK2gnYHWkqe1NiQR1pGac7.jpg"}]}}

      jObj := SO(sList[0]);
      If jObj <> nil then
      Begin
        with searchMetaData do
        Begin
          If JsonToMetaDataRecord(jObj, osmMovies, searchMetaData) then
          Begin
            Result := True;

            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Poster path "'+tmdbPosterPath+'"');{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Backdrop path "'+tmdbBackdropPath+'"');{$ENDIF}
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Still path "'+tmdbStillPath+'"');{$ENDIF}
          End
            else
          Begin
            {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not a valid response - missing "'+tmdbIDStr+'" value; Response: '+sList.Text);{$ENDIF}
            ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
          End;

          jObj.Clear;
          jObj := nil;
        End;
      End
        else
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','jObj = nil!!!');{$ENDIF}
      End;
    End
      else
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Download returned no data; Status: "'+sDownloadStatus+'"; Response: '+sList.Text){$ENDIF};
      ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
    End;
  End
    else
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error downloading "'+sURL+'"!; ErrorCode: '+IntToStr(ErrorCode)+'; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
    if ErrorCode = 0 then
      If sDownloadStatus = '401' then
        ErrorCode := SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED
      else
        ErrorCode := SCRAPE_RESULT_ERROR_DB_OTHER_ERROR;
  End;
end;


function SearchTheMovieDB_MovieByName(sName: WideString; MediaNameYear : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure, sQueryURL : String;
begin
  If Secured = True then sSecure := 's' else sSecure := '';
  sQueryURL := 'http'+sSecure+'://api.themoviedb.org/3/search/movie?api_key='+TheMovieDB_APIKey+'&query='+URLEncodeUTF8(sName);
  AddLanguageCode(sQueryURL);
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Search URL : '+CRLF+sQueryURL+CRLF);{$ENDIF}
  Result := SearchTheMovieDB(sQueryURL,sName,osmMovies,MediaNameYear,sList,searchMetaData.tmdbID,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
  If Result = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_MovieByID #'+IntToStr(searchMetaData.tmdbID)+' (before)');{$ENDIF}
    Result := SearchTheMovieDB_MovieByID(searchMetaData.tmdbID,Secured,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_MovieByID (after)');{$ENDIF}
  End;
End;


function SearchTheMovieDB_ByIMDBURL(sURL : String; CategoryType : Integer; var sList : TStringList; var iID: Integer; var ErrorCode: Integer{$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  jObj            : ISuperObject;
  jObjAllResults  : ISuperObject;
  jObjResult      : ISuperObject;
  I               : Integer;
  sDownloadStatus : String;
  ResultsStr      : String;
begin
  sDownloadStatus := '';
  Result := False;

  AddLanguageCode(sURL);

  // http://api.themoviedb.org/3/find/tt0266543?external_source=imdb_id&api_key={API_KEY}
  {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Movie Search URL :'+CRLF+sURL+CRLF);{$ENDIF}
  CheckAndAddToSearchLimitList;
  If DownloadFileToStringList(sURL,sList,sDownloadStatus,ErrorCode,tmdbQueryInternetTimeout{$IFDEF LOCALTRACE},ThreadID{$ENDIF}) = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Download succesful');{$ENDIF}
    If sList.Count > 0 then
    Begin
      // Sample result:
      //
      // {"movie_results":[{"adult":false,"backdrop_path":"/n2vIGWw4ezslXjlP0VNxkp9wqwU.jpg","genre_ids":[16],"id":12,"original_language":"en","original_title":"Finding Nemo",
      // "overview":"A tale which follows the comedic and eventful journeys of two fish, the fretful Marlin and his young son Nemo, who are separated from each other in the Great Barrier Reef when Nemo is unexpectedly taken from his home and thrust into a fish tank in a dentist's office overlooking Sydney Harbor. Buoyed by the companionship of a friendly but forgetful fish named Dory, the overly cautious Marlin embarks on a dangerous trek and finds himself the unlikely hero of an epic journey to rescue his son.",
      // "release_date":"2003-05-30","poster_path":"/zjqInUwldOBa0q07fOyohYCWxWX.jpg","popularity":5.378621,"title":"Finding Nemo","video":false,"vote_average":7.3,"vote_count":2793}],
      // "person_results":[],"tv_results":[],"tv_episode_results":[],"tv_season_results":[]}


      jObj := SO(sList[0]);
      If jObj <> nil then
      Begin
        If CategoryType = osmTV then ResultsStr := tmdbTVResultsStr
          else ResultsStr := tmdbMovieResultsStr;
        jObjAllResults := jObj.O[ResultsStr];
        If jObjAllResults <> nil then
        Begin
          For I := 0 to jObjAllResults.AsArray.Length-1 do
          Begin
            jObjResult := jObjAllResults.AsArray[I];
            If jObjResult <> nil then
            Begin
              iID := jObjResult.I[tmdbIDStr];
              Result := True;

              jObjResult.Clear;
              jObjResult := nil;
              Break;
            End
              else
            Begin
              {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not valid - missing "'+tmdbIDStr+'" value; Response: '+sList.Text);{$ENDIF}
              ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
            End;
          End;

          jObjAllResults.Clear;
          jObjAllResults := nil;
        End
          else
        Begin
          {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not valid - missing "'+ResultsStr+'" section; Response: '+sList.Text);{$ENDIF}
          ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
        End;
        jObj.Clear;
        jObj := nil;
      End
        else
      Begin
        {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Returned data is not JSON Object; Response: '+sList.Text);{$ENDIF}
        ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
      End;
    End
      else
    Begin
      {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error: Download returned no data; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
      ErrorCode := SCRAPE_RESULT_ERROR_DB_UNSUPPORTED_RESPONSE;
    End;
  End
    else
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','Error downloading "'+sURL+'"!; ErrorCode: '+IntToStr(ErrorCode)+'; Status: "'+sDownloadStatus+'"; Response: '+sList.Text);{$ENDIF}
    if ErrorCode = 0 then
      If sDownloadStatus = '401' then
        ErrorCode := SCRAPE_RESULT_ERROR_DB_UNAUTHORIZED
      else
        ErrorCode := SCRAPE_RESULT_ERROR_DB_OTHER_ERROR;
  End;
end;


function SearchTheMovieDB_MovieByIMDBID(iIMDBID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure : String;
  sIMDBID : String;
  sURL    : String;
begin
  sIMDBID := IntToStr(iIMDBID);
  While Length(sIMDBID) < 7 do sIMDBID := '0'+sIMDBID;
  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/find/tt'+sIMDBID+'?external_source=imdb_id&api_key='+TheMovieDB_APIKey;
  AddLanguageCode(sURL);

  Result := SearchTheMovieDB_ByIMDBURL(sURL,osmMovies,sList,searchMetaData.tmdbID,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
  If Result = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_MovieByID #'+IntToStr(searchMetaData.tmdbID)+' (before)');{$ENDIF}
    Result := SearchTheMovieDB_MovieByID(searchMetaData.tmdbID,Secured,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_MovieByID (after)');{$ENDIF}
  End;
end;


function SearchTheMovieDB_TVShowByIMDBID(iIMDBID : Integer; Secured : Boolean; var sList : TStringList; var searchMetaData : TtmdbMetaDataRecord; var ErrorCode: Integer {$IFDEF LOCALTRACE}; ThreadID : Integer{$ENDIF}) : Boolean;
var
  sSecure : String;
  sIMDBID : String;
  sURL    : String;
begin
  sIMDBID := IntToStr(iIMDBID);
  While Length(sIMDBID) < 7 do sIMDBID := '0'+sIMDBID;
  If Secured = True then sSecure := 's' else sSecure := '';
  sURL := 'http'+sSecure+'://api.themoviedb.org/3/find/tt'+sIMDBID+'?external_source=imdb_id&api_key='+TheMovieDB_APIKey;
  AddLanguageCode(sURL);

  Result := SearchTheMovieDB_ByIMDBURL(sURL,osmTV,sList,searchMetaData.tmdbID,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
  If Result = True then
  Begin
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_TVShowByID #'+IntToStr(searchMetaData.tmdbID)+' (before)');{$ENDIF}
    Result := SearchTheMovieDB_TVShowByID(searchMetaData.tmdbID,Secured,sList,searchMetaData,ErrorCode{$IFDEF LOCALTRACE},ThreadID{$ENDIF});
    {$IFDEF LOCALTRACE}DebugMsgFT('c:\log\ScrapeTheMovieDB_'+IntToStr(ThreadID)+'.txt','SearchTheMovieDB_TVShowByID (after)');{$ENDIF}
  End;
end;




end.
