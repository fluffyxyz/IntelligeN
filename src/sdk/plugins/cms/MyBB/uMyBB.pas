unit uMyBB;

interface

uses
  // Delphi
  Windows, SysUtils, StrUtils, Classes, Controls, HTTPApp, XMLIntf, Variants,
  // RegEx
  RegExpr,
  // Utils,
  uHTMLUtils, uPathUtils, uStringUtils,
  // Common
  uConst, uWebsiteInterface,
  // HTTPManager
  uHTTPInterface, uHTTPClasses,
  // Plugin system
  uPlugInCMSClass, uPlugInCMSBoardClass, uPlugInHTTPClasses, uPlugInCMSSettingsHelper;

type
  TMyBBSettings = class(TCMSBoardIPPlugInSettings)
  strict private
    fprefix_field: string;
    fuse_coverlink, fsignature, fdisablesmilies: Boolean;
  protected
    xthreads: array of array of Variant;
  published
    [AttrDefaultValue('threadprefix')]
    property prefix_field: string read fprefix_field write fprefix_field;
    [AttrDefaultValue(False)]
    property use_coverlink: Boolean read fuse_coverlink write fuse_coverlink;
    [AttrDefaultValue(True)]
    property signature: Boolean read fsignature write fsignature;
    [AttrDefaultValue(False)]
    property disablesmilies: Boolean read fdisablesmilies write fdisablesmilies;
    [AttrDefaultValue(False)]
    property intelligent_posting;
    [AttrDefaultValue(False)]
    property intelligent_posting_helper;

    property forums;
    property threads;
    property prefix;
    property icon;
  end;

  TMyBB = class(TCMSBoardIPPlugIn)
  private
    MyBBSettings: TMyBBSettings;
  protected
    function SettingsClass: TCMSPlugInSettingsMeta; override;
    function GetSettings: TCMSPlugInSettings; override;
    procedure SetSettings(ACMSPlugInSettings: TCMSPlugInSettings); override;
    function LoadSettings(const AWebsiteData: ICMSWebsiteData = nil): Boolean; override;

    function DoBuildLoginRequest(out AHTTPRequest: IHTTPRequest; out AHTTPParams: IHTTPParams; out AHTTPOptions: IHTTPOptions; APrevResponse: string; ACAPTCHALogin: Boolean = False): Boolean; override;
    function DoAnalyzeLogin(AResponseStr: string; out ACAPTCHALogin: Boolean): Boolean; override;

    function IntelligentPosting(var ARequestID: Double): Boolean; override;

    function NeedPrePost(out ARequestURL: string): Boolean; override;
    function DoAnalyzePrePost(AResponseStr: string): Boolean; override;

    function DoBuildPostRequest(const AWebsiteData: ICMSWebsiteData; out AHTTPRequest: IHTTPRequest; out AHTTPParams: IHTTPParams; out AHTTPOptions: IHTTPOptions; APrevResponse: string; APrevRequest: Double): Boolean; override;
    function DoAnalyzePost(AResponseStr: string; AHTTPProcess: IHTTPProcess): Boolean; override;

    function DoAnalyzeIDsRequest(AResponseStr: string): Integer; override;
  public
    function GetName: WideString; override; safecall;
    function DefaultCharset: WideString; override; safecall;
    function BelongsTo(AWebsiteSourceCode: WideString): WordBool; override; safecall;
  end;

implementation

function TMyBB.SettingsClass;
begin
  Result := TMyBBSettings;
end;

function TMyBB.GetSettings;
begin
  Result := MyBBSettings;
end;

procedure TMyBB.SetSettings;
begin
  MyBBSettings := ACMSPlugInSettings as TMyBBSettings;
end;

function TrueXMLNodeName(ANodeName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to length(ANodeName) do
    if (ANodeName[I] in ['a' .. 'z', 'A' .. 'Z', '_']) then
      Result := Result + ANodeName[I];
end;

function TMyBB.LoadSettings;
begin
  Result := True;
  with MyBBSettings do
  begin
    TPlugInCMSSettingsHelper.LoadSettingsToClass(SettingsFileName, MyBBSettings, AWebsiteData,
      { } procedure(AXMLNode: IXMLNode)
      { } var
      { . } Y, K: Integer;
      { } begin
      { . } if Assigned(AWebsiteData) and Assigned(AXMLNode.ChildNodes.FindNode('xthreads')) then
      { . } begin
      { ... } with AXMLNode.ChildNodes.Nodes['xthreads'] do
      { ..... } for Y := 0 to ChildNodes.Count - 1 do
      { ..... } begin
      { ....... } SetLength(xthreads, Y + 1, 2);
      { ....... } xthreads[Y][0] := ChildNodes.Nodes[Y].NodeValue
      { ..... } end;
      { ... } for K := 0 to length(xthreads) - 1 do
      { ..... } with AXMLNode.ChildNodes.Nodes[TrueXMLNodeName(xthreads[K][0])] do
      { ..... } begin
      { ....... } for Y := 0 to ChildNodes.Count - 1 do
      { ......... } if SameText(VarToStr(ChildNodes.Nodes[Y].Attributes['name']), TTemplateTypeIDToString(AWebsiteData.TemplateTypeID)) then
      { ......... } begin
      { ........... } xthreads[K][1] := TPlugInCMSSettingsHelper.GetID(ChildNodes.Nodes[Y]);

      { ........... } TPlugInCMSSettingsHelper.SubSearch(ChildNodes.Nodes[Y], AWebsiteData, xthreads[K][1]);
      { ........... } break;
      { ......... } end;
      { ..... } end;
      { . } end;
      { } end);
    if SameStr('', CharSet) then
      CharSet := DefaultCharset;

    if Assigned(AWebsiteData) and (forums = null) then
    begin
      ErrorMsg := StrForumIdIsUndefine;
      Result := False;
    end;

    PostReply := not((threads = null) or (threads = '') or (threads = 0));
  end;
end;

function TMyBB.DoBuildLoginRequest;
var
  _captcha, _cookies: WideString;
  _imagehash: string;
begin
  Result := True;

  if ACAPTCHALogin then
  begin
    with TRegExpr.Create do
      try
        InputString := APrevResponse;
        Expression := 'name="imagehash" value="(.*?)"';

        if Exec(InputString) then
          _imagehash := Match[1];
      finally
        Free;
      end;

    if not CAPTCHAInput(Website + 'captcha.php?imagehash=' + _imagehash, GetName, _captcha, _cookies) then
    begin
      ErrorMsg := StrAbortedThrougthCAP;
      Result := False;
    end;
  end;

  AHTTPRequest := THTTPRequest.Create(Website + 'member.php');
  with AHTTPRequest do
  begin
    Referer := Website;
    CharSet := MyBBSettings.CharSet;
  end;

  AHTTPParams := THTTPParams.Create;
  with AHTTPParams do
  begin
    AddFormField('username', AccountName);
    AddFormField('password', AccountPassword);

    if ACAPTCHALogin then
    begin
      AddFormField('imagehash', _imagehash);
      AddFormField('imagestring', _captcha);
    end;

    AddFormField('url', '');
    AddFormField('action', 'do_login');
    AddFormField('submit', '');
  end;

  AHTTPOptions := TPlugInHTTPOptions.Create(Self);
end;

function TMyBB.DoAnalyzeLogin;
begin
  ACAPTCHALogin := not(Pos('name="imagehash"', AResponseStr) = 0);
  Result := not(Pos('member.php?action=logout', AResponseStr) = 0);
  if not Result then
    with TRegExpr.Create do
      try
        InputString := AResponseStr;
        if (Pos('<div class="error">', AResponseStr) = 0) then
          Expression := '<td class="trow1">(.*?)<\/td>'
        else
          Expression := '<div class="error">(.*?)<\/div>';

        if Exec(InputString) then
          Self.ErrorMsg := Trim(HTML2Text(Match[1]));
      finally
        Free;
      end;
end;

function TMyBB.IntelligentPosting;

  function GetSearchTitle(ATitle: string): string;
  var
    X: Integer;
  begin
    Result := ATitle;
    for X := length(Result) downto 1 do
      if (Result[X] in ['+', '_', '.', ':', '(', ')', '[', ']', '/', '\']) then
        Result[X] := ' ';
    Result := Trim(ReduceWhitespace(Result));
  end;

var
  HTTPParams: IHTTPParams;
  HTTPOptions: IHTTPOptions;
  ResponseStr: string;

  SearchValue: WideString;
  SearchResults: TStringList;
  SearchIndex: Integer;
  RedoSearch: Boolean;

  _found_thread_id, _found_thread_name: string;
begin
  Result := True;
  if MyBBSettings.intelligent_posting then
  begin
    SearchValue := GetSearchTitle(Subject);

    RedoSearch := False;
    repeat
      SearchIndex := 0;

      HTTPParams := THTTPParams.Create;
      with HTTPParams do
      begin
        AddFormField('action', 'do_search');
        AddFormField('keywords', SearchValue);
        AddFormField('postthread', '1');
        AddFormField('forums[]', '');
        AddFormField('sortordr', 'desc');
        AddFormField('showresults', 'threads');
        AddFormField('submit', '');
      end;

      HTTPOptions := TPlugInHTTPOptions.Create(Self);
      with HTTPOptions do
      begin
        RedirectMaximum := 1;
      end;

      ARequestID := HTTPManager.Post(GetSearchRequestURL, ARequestID, HTTPParams, HTTPOptions);

      repeat
        sleep(50);
      until HTTPManager.HasResult(ARequestID);

      ResponseStr := HTTPManager.GetResult(ARequestID).HTTPResult.SourceCode;

      HTTPOptions := TPlugInHTTPOptions.Create(Self);
      with HTTPOptions do
      begin
        RedirectMaximum := 0;
      end;

      with TRegExpr.Create do
        try
          InputString := ResponseStr;
          Expression := '"2;URL=(.*?)"';

          if Exec(InputString) then
          begin
            ARequestID := HTTPManager.Get(Website + HTMLDecode(Match[1]), ARequestID, HTTPOptions);

            repeat
              sleep(50);
            until HTTPManager.HasResult(ARequestID);

            ResponseStr := HTTPManager.GetResult(ARequestID).HTTPResult.SourceCode;
          end;
        finally
          Free;
        end;

      SearchResults := TStringList.Create;
      try
        SearchResults.Add('0=Create new Thread');
        with TRegExpr.Create do
          try
            ModifierS := False;
            InputString := ResponseStr;
            Expression := 'showthread\.php\?tid=(\d+).*?id="tid_\d+".*?>([^>]*?)<\/a>';

            if Exec(InputString) then
            begin
              repeat
                _found_thread_id := Match[1];
                _found_thread_name := Match[2];

                SearchResults.Add(_found_thread_id + SearchResults.NameValueSeparator + _found_thread_name);

                if not PostReply then
                  with TRegExpr.Create do
                    try
                      ModifierI := True;
                      InputString := _found_thread_name;
                      Expression := StringReplace(' ' + GetSearchTitle(Subject) + ' ', ' ', '.*?', [rfReplaceAll, rfIgnoreCase]);

                      if Exec(InputString) then
                      begin
                        PostReply := True;
                        MyBBSettings.threads := _found_thread_id;
                        SearchIndex := SearchResults.Count - 1;
                      end;
                    finally
                      Free;
                    end;

              until not ExecNext;
            end;
          finally
            Free;
          end;

        if MyBBSettings.intelligent_posting_helper then
        begin
          if not IntelligentPostingHelper(SearchValue, SearchResults.Text, SearchIndex, RedoSearch) then
          begin
            ErrorMsg := StrAbortedThrougthInt;
            Result := False;
          end;
          PostReply := (SearchIndex > 0);
          if PostReply then
            MyBBSettings.threads := SearchResults.Names[SearchIndex];
        end;
      finally
        SearchResults.Free;
      end;
    until not RedoSearch;
  end;
end;

function TMyBB.NeedPrePost;
begin
  Result := True;
  if PostReply then
    ARequestURL := Website + 'newreply.php?tid=' + VarToStr(MyBBSettings.threads)
  else
    ARequestURL := Website + 'newthread.php?fid=' + VarToStr(MyBBSettings.forums);
end;

function TMyBB.DoAnalyzePrePost;
begin
  Result := True;
  // TODO: �berpr�fung ob der User �berhaupt Rechte hat, korrekt eingeloggt wurde
end;

function TMyBB.DoBuildPostRequest;
const
  security_inputs: array [0 .. 1] of string = ('my_post_key', 'posthash');
var
  FormatSettings: TFormatSettings;

  RequestURL: string;

  I: Integer;
begin
  Result := True;

  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, FormatSettings);
  FormatSettings.DecimalSeparator := ',';

  if PostReply then
    RequestURL := Website + 'newreply.php?tid=' + VarToStr(MyBBSettings.threads) + '&processed=1'
  else
    RequestURL := Website + 'newthread.php?fid=' + VarToStr(MyBBSettings.forums) + '&processed=1';

  AHTTPRequest := THTTPRequest.Create(RequestURL);
  with AHTTPRequest do
  begin
    Referer := Website;
    CharSet := MyBBSettings.CharSet;
  end;

  AHTTPParams := THTTPParams.Create;
  with AHTTPParams do
  begin
    with TRegExpr.Create do
      try
        for I := 0 to length(security_inputs) - 1 do
        begin
          InputString := APrevResponse;
          Expression := 'name="' + security_inputs[I] + '" value="(.*?)"';

          if Exec(InputString) then
          begin
            repeat
              AddFormField(security_inputs[I], Match[1]);
            until not ExecNext;
          end;
        end;
      finally
        Free;
      end;

    for I := 0 to length(MyBBSettings.xthreads) - 1 do
      if not(MyBBSettings.xthreads[I][1] = null) then
        AddFormField(VarToStr(MyBBSettings.xthreads[I][0]), VarToStr(MyBBSettings.xthreads[I][1]));

    AddFormField(MyBBSettings.prefix_field, VarToStr(MyBBSettings.prefix));

    if MyBBSettings.use_coverlink and Assigned(AWebsiteData.FindControl(cPicture)) then
    begin
      AddFormField('xtasel_pref_pic', 'url');
      AddFormField('xtaurl_pref_pic', AWebsiteData.FindControl(cPicture).Value);
      AddFormField('xthreads_pref_pic2', AWebsiteData.FindControl(cPicture).Value);
    end;

    for I := 0 to AWebsiteData.MirrorCount - 1 do
      if AWebsiteData.Mirror[I].Size > 0 then
      begin
        AddFormField('xthreads_pref_mb', FloatToStr(AWebsiteData.Mirror[I].Size, FormatSettings));
        break;
      end;

    (*
      xthreads_pref_lang

      values:
      DE
      ENG
      DE-ENG
      *)

    AddFormField('icon', VarToStr(MyBBSettings.icon));
    AddFormField('subject', Subject);
    AddFormField('message', Message);

    with MyBBSettings do
    begin
      if signature then
        AddFormField('postoptions[signature]', '1');
      if disablesmilies then
        AddFormField('postoptions[disablesmilies]', '1');
    end;

    AddFormField('submit', '');

    if PostReply then
    begin
      AddFormField('tid', VarToStr(MyBBSettings.threads));
      AddFormField('action', 'do_newreply');
    end
    else if (ArticleID = 0) then
      AddFormField('action', 'do_newthread');
  end;

  AHTTPOptions := TPlugInHTTPOptions.Create(Self);
end;

function TMyBB.DoAnalyzePost;
begin
  Result := True;

  with TRegExpr.Create do
    try
      InputString := AResponseStr;
      Expression := '<div class="error">(.*?)<\/div>';

      if Exec(InputString) then
      begin
        Self.ErrorMsg := HTML2Text(Match[1]);
        Result := False;
      end;
    finally
      Free;
    end;
end;

function TMyBB.DoAnalyzeIDsRequest;
var
  BoardLevel: TStringList;
  BoardLevelIndex: Integer;

  function IDPath(AStringList: TStringList): string;
  var
    I: Integer;
  begin
    Result := '';
    for I := 0 to AStringList.Count - 1 do
    begin
      if not SameStr('', Result) then
        Result := Result + ' -> ';
      Result := Result + AStringList.Strings[I];
    end;
  end;

  function CleanPathName(AName: string): string;
  begin
    Result := Trim(HTML2Text(AName));
  end;

begin
  BoardLevel := TStringList.Create;
  try
    with TRegExpr.Create do
      try
        InputString := ExtractTextBetween(AResponseStr, 'name="forums[]"', '</select>');
        Expression := 'option.*? value="(\d+)">([&nbsp;]*)(.*?)<\/';

        if Exec(InputString) then
        begin
          repeat
            BoardLevelIndex := CharCount('&nbsp;', Match[2]);

            if BoardLevelIndex > 0 then
              BoardLevelIndex := BoardLevelIndex div 4;

            if (BoardLevelIndex = BoardLevel.Count) then
              BoardLevel.Add(CleanPathName(Match[3]))
            else
            begin
              repeat
                BoardLevel.Delete(BoardLevel.Count - 1);
              until (BoardLevelIndex = BoardLevel.Count);
              BoardLevel.Add(CleanPathName(Match[3]));
            end;

            AddID(Match[1], IDPath(BoardLevel));
          until not ExecNext;
        end;
      finally
        Free;
      end;
  finally
    BoardLevel.Free;
  end;
  Result := FCheckedIDsList.Count;
end;

function TMyBB.GetName;
begin
  Result := 'MyBB';
end;

function TMyBB.DefaultCharset;
begin
  Result := 'UTF-8';
end;

function TMyBB.BelongsTo;
begin
  Result := (Pos('member.php?action=register', string(AWebsiteSourceCode)) > 0) or (Pos('MyBB.quickLogin()', string(AWebsiteSourceCode)) > 0);
end;

end.