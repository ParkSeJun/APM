﻿#SingleInstance Force
if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}

global g_isDebug := false
global p, keys
global g_lastLikeTime := 0, g_lastFollowTime := 0
global g_RestartTime := 60 * 1000 * 50
global g_GuiVars := [], g_GuiLoaded := false
global g_isLogin := false

fn_Web_Init(true)

if(g_isDebug)
{
	fn_Web_Insta_Login("blackbeltsejun@daum.net", getpw())
	;fn_Web_Insta_Login("01088229906", "aa1879420")
	
	msgbox
	return
}

SplashTextOn, 60, 0, 초기화 중
fn_Gui_Make_Main()
SplashTextOff
fn_debug_log("Program Start")
return

f1::pause
f2::reload
f3::exitapp

fn_Debug_Fast_Get_TagName(css) {
	return p.ExecuteScript("function f() { return document.querySelector(""" css """).tagName; } return f();")
}

fn_Debug_Fast_ClickAndWaitFor(CssForClick, CssForWait) {
	lastClickTime := 0
	while(!fn_Debug_Fast_Get_TagName(CssForWait))
	{
		;msgbox,% A_ThisFunc "`n" cssforwait "`n" fn_Debug_Fast_Get_TagName(CssForWait)
		if(A_TickCount - lastClickTime >= 5000)
		{
			p.ExecuteScript("document.querySelector(""" CssForClick """).click();")
			lastClickTime := A_TickCount
		}
		sleep, 250
	}
}

fn_Debug_Fast_ClickAndWaitForNot(CssForClick, CssForWait := 0) {
	lastClickTime := 0
	if(!CssForWait)
		CssForWait := CssForClick
	while(fn_Debug_Fast_Get_TagName(CssForWait))
	{
		if(A_TickCount - lastClickTime >= 5000)
		{
			p.ExecuteScript("document.querySelector(""" CssForClick """).click();")
			lastClickTime := A_TickCount
		}
		sleep, 250
	}
}

;=====================================================================================;
;=====================================================================================;

fn_Gui_Make_Main() {
	global

	g_GuiVars := []	
	;

	Gui, Font, bold
	Gui, Add, GroupBox, x10 y10 w225 h100 cBlack Section, 계정 설정
	Gui, Add, Text, xs+10 ys+35 w30 right, ID
	Gui, Add, Edit, x+5 yp-4 w150 vGui_Edit_ID gfn_Gui_Event_Gui_Save
	Gui, Add, Text, xs+10 ys+65 w30 right, PW
	Gui, Add, Edit, x+5 yp-4 w150 vGui_Edit_PW gfn_Gui_Event_Gui_Save
	;Gui, Add, CheckBox, xs+20 ys+75 vGui_CheckBox_IDPW gfn_Gui_Event_Gui_Save, IDPW.txt 파일 사용
	Gui, Font, Norm
	g_GuiVars.Push("Gui_Edit_ID")
	g_GuiVars.Push("Gui_Edit_PW")
	;g_GuiVars.Push("Gui_CheckBox_IDPW")

	Gui, Add, GroupBox, x245 y10 w555 h100 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+25 cBlue, - 언팔로우
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+50, 언팔로우 대상 리스트 파일
	Gui, Add, Edit, x+5 yp-4 w205 vGui_Edit_UnFollow_Path gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_UnFollow_Path  gfn_Gui_Event_Select_Path, ...
	Gui, Add, Text, xs+20 ys+75, 언팔로우 인터벌
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_UnFollow_Interval right number gfn_Gui_Event_Gui_Save, 10
	Gui, Add, Text, x+5 yp+4, 초
	Gui, Add, Button, xs+420 ys+20 w125 h70 gfn_Gui_Event_Button_Process vGui_Button_UnFollow, 언팔로우 시작
	g_GuiVars.Push("Gui_Edit_UnFollow_Path")
	g_GuiVars.Push("Gui_Edit_UnFollow_Interval")

	;

	Gui, Add, GroupBox, x10 y110 w390 h120 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+25 cBlue, - 피드 좋아요
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+55, 작업할 개수
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Feed_Like_Count right number gfn_Gui_Event_Gui_Save, 5
	Gui, Add, Text, x+5 yp+4, 개
	Gui, Add, Text, xs+20 ys+85, 좋아요 인터벌
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Feed_Like_Interval right number gfn_Gui_Event_Gui_Save, 15
	Gui, Add, Text, x+5 yp+4, 초
	Gui, Add, Button, xs+230 ys+20 w150 h90 gfn_Gui_Event_Button_Process vGui_Button_Feed_Like, 피드 좋아요 시작
	g_GuiVars.Push("Gui_Edit_Feed_Like_Count")
	g_GuiVars.Push("Gui_Edit_Feed_Like_Interval")
	
	Gui, Add, GroupBox, x10 y230 w390 h196 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+25 cBlue, - 팔로우 + 좋아요
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+55, 검색할 태그 개수
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Follow_Like_Search_Count right number gfn_Gui_Event_Gui_Save, 3
	Gui, Add, Text, x+5 yp+4, 개
	Gui, Add, Text, xs+20 ys+82, 한 검색어 당 작업할 개수
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Follow_Like_Count right number gfn_Gui_Event_Gui_Save, 5
	Gui, Add, Text, x+5 yp+4, 개
	Gui, Add, Text, xs+20 ys+109, 팔로우 확률
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Follow_Like_Rate right number gfn_Gui_Event_Gui_Save, 60
	Gui, Add, Text, x+5 yp+4,  `% (0 ~ 100)`%
	Gui, Add, Text, xs+20 ys+136, 팔로우 인터벌
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Follow_Like_Interval right number gfn_Gui_Event_Gui_Save, 30
	Gui, Add, Text, x+5 yp+4, 초
	Gui, Add, Button, xs+230 ys+20 w150 h140 gfn_Gui_Event_Button_Process vGui_Button_Follow_Like, 팔로우 + 좋아요 시작
	Gui, Add, Text, xs+20 ys+170, 태그 리스트 파일
	Gui, Add, Edit, x+5 yp-4 w228 vGui_Edit_Follow_Like_Path gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Follow_Like_Path gfn_Gui_Event_Select_Path, ...
	g_GuiVars.Push("Gui_Edit_Follow_Like_Search_Count")
	g_GuiVars.Push("Gui_Edit_Follow_Like_Count")
	g_GuiVars.Push("Gui_Edit_Follow_Like_Rate")
	g_GuiVars.Push("Gui_Edit_Follow_Like_Interval")
	g_GuiVars.Push("Gui_Edit_Follow_Like_Path")
	
	;

	Gui, Add, GroupBox, x410 y110 w390 h158 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+30 cBlue, - 팔로잉 리스트 추출
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+60, 추출 결과 저장 폴더
	Gui, Add, Edit, x+5 yp-4 w205 vGui_Edit_Get_List_Path_Following gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Get_List_Path_Following gfn_Gui_Event_Select_Path, ...
	Gui, Add, Button, xs+15 ys+85 w365 h63 gfn_Gui_Event_Button_Process vGui_Button_Get_List_Following, 팔로잉 리스트 추출 시작
	g_GuiVars.Push("Gui_Edit_Get_List_Path_Following")

	Gui, Add, GroupBox, x410 y268 w390 h158 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+30 cBlue, - 언팔로우 리스트 추출
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+60, 추출 결과 저장 폴더
	Gui, Add, Edit, x+5 yp-4 w205 vGui_Edit_Get_List_Path_UnFollow gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Get_List_Path_UnFollow gfn_Gui_Event_Select_Path, ...
	Gui, Add, Button, xs+15 ys+85 w365 h63 gfn_Gui_Event_Button_Process vGui_Button_Get_List_UnFollow, 언팔로우 리스트 추출 시작
	g_GuiVars.Push("Gui_Edit_Get_List_Path_UnFollow")
	
	;

	Gui, Add, GroupBox, x10 y426 w790 h220 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+30 cBlue, - 피드 올리기
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+60, 사진 폴더
	Gui, Add, Edit, x+5 yp-4 w405 vGui_Edit_Upload_Image_Path gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Upload_Image_Path gfn_Gui_Event_Select_Path, ...
	Gui, Add, Text, xs+20 ys+90, 글감 폴더
	Gui, Add, Edit, x+5 yp-4 w405 vGui_Edit_Upload_Article_Path2 gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Upload_Article_Path2 gfn_Gui_Event_Select_Path, ...
	Gui, Add, Text, xs+20 ys+120, 해쉬태그 파일
	Gui, Add, Edit, x+5 yp-4 w405 vGui_Edit_Upload_Tag_Path gfn_Gui_Event_Gui_Save
	Gui, Add, Button, x+5 yp-1 w30 vGui_Button_Upload_Tag_Path gfn_Gui_Event_Select_Path, ...
	Gui, Add, Text, xs+20 ys+150, 해쉬태그 작성 개수
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Upload_Tag_Count_Min right number gfn_Gui_Event_Gui_Save, 5
	Gui, Add, Text, x+5 yp+4, ~
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Upload_Tag_Count_Max right number gfn_Gui_Event_Gui_Save, 15
	Gui, Add, Text, x+5 yp+4, 개
	Gui, Add, Text, xs+20 ys+180, 피드 올리기 인터벌
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Upload_Interval right number gfn_Gui_Event_Gui_Save, 60
	Gui, Add, Text, x+5 yp+4, 초
	Gui, Add, Button, xs+570 ys+25 w205 h180 gfn_Gui_Event_Button_Process vGui_Button_Upload, 피드 올리기 시작
	g_GuiVars.Push("Gui_Edit_Upload_Image_Path")
	g_GuiVars.Push("Gui_Edit_Upload_Article_Path2")
	g_GuiVars.Push("Gui_Edit_Upload_Tag_Path")
	g_GuiVars.Push("Gui_Edit_Upload_Tag_Count_Min")
	g_GuiVars.Push("Gui_Edit_Upload_Tag_Count_Max")
	g_GuiVars.Push("Gui_Edit_Upload_Interval")

	;

	Gui, Add, GroupBox, x10 y646 w420 h120 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+30 cBlue, - 게시물 삭제
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+60, 삭제할 게시물 수
	Gui, Add, Edit, x+5 yp-4 w30 vGui_Edit_Delete_Article_Count right number gfn_Gui_Event_Gui_Save, 1
	Gui, Add, Text, x+5 yp+4, 개 (최대 45개)
	Gui, Add, Button, xs+260 ys+20 w150 h90 gfn_Gui_Event_Button_Process vGui_Button_Delete_Article, 게시물 삭제 시작
	g_GuiVars.Push("Gui_Edit_Delete_Article_Count")

	Gui, Add, GroupBox, x440 y646 w360 h120 cBlack Section
	Gui, Font, bold
	Gui, Add, Text, xs+15 ys+30 cBlue, - 게시물 찾아가서 팔로우 + 좋아요
	Gui, Font, Norm
	Gui, Add, Text, xs+20 ys+60, 검색할 # 태그
	Gui, Add, Edit, x+5 yp-4 w130 vGui_Edit_Find_Keyword gfn_Gui_Event_Gui_Save
	Gui, Add, Text, xs+20 ys+90, 게시글 URL
	Gui, Add, Edit, x+5 yp-4 w141 vGui_Edit_Find_URL gfn_Gui_Event_Gui_Save
	Gui, Add, Button, xs+250 ys+20 w100 h90 gfn_Gui_Event_Button_Process vGui_Button_Find, 검색 시작
	g_GuiVars.Push("Gui_Edit_Find_Keyword")
	g_GuiVars.Push("Gui_Edit_Find_URL")
	

	Gui, Add, StatusBar
	SB_SetText("`tF1 : 일시정지                    F2 : 프로그램 재실행                    F3 : 종료")

	;msgbox,% DisplayObject(g_GuiVars)

	fn_Gui_Load()

	Gui, Show, w817 h790
}

fn_Gui_Event_Button_Process(hwnd, event, info, err := "") {
	global
	local name, imagePath, o, str, r, t, usedTags, i, e, _t
	Gui, Submit, Nohide

	GuiControlGet, name, Name, % hwnd

	GuiControl, +Disabled, Gui_Button_Upload
	GuiControl, +Disabled, Gui_Button_Feed_Like
	GuiControl, +Disabled, Gui_Button_Follow_Like
	GuiControl, +Disabled, Gui_Button_Get_List_Following
	GuiControl, +Disabled, Gui_Button_Get_List_UnFollow
	GuiControl, +Disabled, Gui_Button_UnFollow
	GuiControl, +Disabled, Gui_Button_Delete_Article
	GuiControl, +Disabled, Gui_Button_Find

	if(name = "Gui_Button_Find")
	{
		IDPWObject := []
		FileRead, IDList, IDPW.txt
		loop, parse, IDList, `n
		{
			if(!A_LoopField)
				continue
			RegExMatch(A_LoopField, "O)(\S*)\s*(\S*)", out)
			IDPWObject.Push({ID:out[1], PW:out[2]})
			;msgbox,% "[" out[1] "]`n[" out[2] "]"
		}

		usedID := []
		if(IDPWObject.Length() = 0)
			msgbox, IDPW.txt 파일에 입력된 아이디 정보가 없습니다.`n설정된 계정으로 로그인합니다.
	}
	
	loop
	{
		if(!g_isLogin)
		{
			loop
			{
				try
				{
					if(name = "Gui_Button_Find" && IDPWObject.Length() > 0)
					{
						if(usedID.MaxIndex() >= IDPWObject.MaxIndex())
						{
							;if(name = "Gui_Button_Find")
							break, 2
							;usedID := []
						}
						loop
						{
							r := getRandom(1, IDPWObject.MaxIndex())
							catchID := IDPWObject[r]["ID"]
							isDup := false
							for i, e in usedID
							{
								if(e = catchID)
								{
									isDup := true
									break
								}
							}
							if(!isDup)
								break
						}
						usedID.Push(IDPWObject[r]["ID"])
						fn_Web_Insta_Login(IDPWObject[r]["ID"], IDPWObject[r]["PW"])
					}
					else
						fn_Web_Insta_Login(Gui_Edit_ID, Gui_Edit_PW)
					break
				}
				catch e
					fn_debug_log(e)
			}
		}
		else
			p.get("https://www.instagram.com/")

		try
		{
			if(name = "Gui_Button_Upload")
			{
				o := []
				loop, % Gui_Edit_Upload_Image_Path "\*"
					o.Push(A_LoopFileLongPath)
				imagePath := o[getRandom(o.MinIndex(), o.MaxIndex())]

				;o := fn_File_Read_To_Object(Gui_Edit_Upload_Article_Path2)
				;str := o[getRandom(o.MinIndex(), o.MaxIndex())]
				l := []
				loop, files, % A_ScriptDir "\" Gui_Edit_Upload_Article_Path2 "\*.txt"
					l.Push(A_LoopFileFullPath)
				FileRead, str, % l[getRandom(1, l.MaxIndex())]
				l := 0

				str .= "`n"
				r := getRandom(Gui_Edit_Upload_Tag_Count_Min, Gui_Edit_Upload_Tag_Count_Max)
				o := fn_File_Read_To_Object(Gui_Edit_Upload_Tag_Path, ",")
				usedTags := []
				loop, % r
				{
					loop
					{
						_t := getRandom(o.MinIndex(), o.MaxIndex())
						
						isDup := false
						for i, e in usedTags
						{
							if(e = _t)
							{
								isDup := true
								break
							}
						}

						if(!isDup)
							break
					}
					usedTags.Push(_t)
					
					t := o[_t]
					if(!RegExMatch(t, "^#"))
						t := "#" t
					str .= t " "
				}

				fn_debug_log(name " " imagePath "`n" str)
				fn_Web_Insta_Upload(imagePath, str)
				sleep, % Gui_Edit_Upload_Interval * 1000
				continue
			}
			else if(name = "Gui_Button_Feed_Like")
			{
				fn_debug_log(name " " Gui_Edit_Feed_Like_Count " " Gui_Edit_Feed_Like_Interval)
				fn_Web_Insta_Feed_Like(Gui_Edit_Feed_Like_Count, Gui_Edit_Feed_Like_Interval)
			}
			else if(name = "Gui_Button_Follow_Like")
			{
				fn_debug_log(name " " Gui_Edit_Follow_Like_Path " " Gui_Edit_Follow_Like_Search_Count " " Gui_Edit_Follow_Like_Count " " Gui_Edit_Follow_Like_Rate " " Gui_Edit_Follow_Like_Interval)
				fn_Web_Insta_Find_Follow_Like(Gui_Edit_Follow_Like_Path, Gui_Edit_Follow_Like_Search_Count, Gui_Edit_Follow_Like_Count, Gui_Edit_Follow_Like_Rate, Gui_Edit_Follow_Like_Interval)
			}
			else if(name = "Gui_Button_Get_List_Following")
			{
				fn_debug_log(name " " Gui_Edit_Get_List_Path_Following)
				p.Get("https://www.instagram.com")
				fn_Web_Insta_Get_List_Following(Gui_Edit_Get_List_Path_Following)
			}
			else if(name = "Gui_Button_Get_List_UnFollow")
			{
				fn_debug_log(name " " Gui_Edit_Get_List_Path_Following)
				fn_Web_Insta_Get_List_UnFollow(Gui_Edit_Get_List_Path_UnFollow)
			}
			else if(name = "Gui_Button_UnFollow")
			{
				fn_debug_log(name " " Gui_Edit_UnFollow_Path " " Gui_Edit_UnFollow_Interval)
				fn_Web_Insta_UnFollow(Gui_Edit_UnFollow_Path, Gui_Edit_UnFollow_Interval)
			}
			else if(name = "Gui_Button_Delete_Article")
			{
				fn_debug_log(name " " Gui_Edit_Delete_Article_Count)
				fn_Web_Insta_Delete_Article(Gui_Edit_Delete_Article_Count)
			}
			else if(name = "Gui_Button_Find")
			{
				fn_debug_log(name " " Gui_Edit_Find_Keyword " " Gui_Edit_Find_URL)
				fn_Web_Insta_Find(Gui_Edit_Find_Keyword, Gui_Edit_Find_URL)
				if(IDPWObject.Length() > 0)
					continue
			}
			break
		}
		catch e
		{
			fn_debug_log("FAIL WITH " name)
			fn_debug_log(e)
		}
	}
	
	msgbox, 작업 완료했습니다.
	GuiControl, -Disabled, Gui_Button_Upload
	GuiControl, -Disabled, Gui_Button_Feed_Like
	GuiControl, -Disabled, Gui_Button_Follow_Like
	GuiControl, -Disabled, Gui_Button_Get_List_Following
	GuiControl, -Disabled, Gui_Button_Get_List_UnFollow
	GuiControl, -Disabled, Gui_Button_UnFollow
	GuiControl, -Disabled, Gui_Button_Delete_Article
	GuiControl, -Disabled, Gui_Button_Find
}

GuiClose:
exitapp

fn_Gui_Event_Select_Path(hwnd, event, info, err := "") {
	global
	local name, i, e, filepath
	if(!g_GuiLoaded)
		return
	GuiControlGet, name, Name, % hwnd

	;	FileSelectFile
	for i, e in ["UnFollow_Path", "Follow_Like_Path", "Upload_Tag_Path"]
	{
		if(InStr(name, e))
		{
			FileSelectFile, filepath
			if(ErrorLevel || !filepath)
				return
			needle := A_WorkingDir
			StringReplace, needle, needle, \, \\, all
			if(RegExMatch(filepath, "^" needle))
				StringTrimLeft, filepath, filepath, % strlen(A_WorkingDir) + 1
			GuiControl, , % "Gui_Edit_" e, % filepath
			return
		}
	}

	;	FileSelectFolder
	for i, e in ["Get_List_Path_Following", "Get_List_Path_UnFollow", "Upload_Article_Path2", "Upload_Image_Path"]
	{
		if(InStr(name, e))
		{
			FileSelectFolder, filepath, % A_ScriptDir, , 폴더를 지정해주세요.
			if(ErrorLevel || !filepath)
				return
			needle := A_WorkingDir
			StringReplace, needle, needle, \, \\, all
			if(RegExMatch(filepath, "^" needle))
				StringTrimLeft, filepath, filepath, % strlen(A_WorkingDir) + 1
			GuiControl, , % "Gui_Edit_" e, % filepath
			return
		}
	}
}

fn_Gui_Load() {
	global
	local i, e, t
	for i, e in g_GuiVars
	{
		IniRead, t, Settings.ini, Gui, % e, [None]
		if(t <> "[None]")
			GuiControl, , % e, % t
	}
	g_GuiLoaded := true
}

fn_Gui_Event_Gui_Save(hwnd, event, info, err := "") {
	global
	local str, name
	if(!g_GuiLoaded)
		return
	Gui, Submit, Nohide
	GuiControlGet, str, , % hwnd
	GuiControlGet, name, Name, % hwnd

	IniWrite, % str, Settings.ini, Gui, % name
}

;=====================================================================================;


fn_Web_Insta_Login(id, pw) {

	p.Get("chrome-extension://nlhjgcligpbnjphflfdbmabbmjidnmek/main/index.html")
	p.get("https://www.instagram.com/")

	; if(!p.url)
	; {
	; 	p.Start()

	; 	msgbox
	; 	while(!InStr(p.url, "instagram"))
	; 	{
	; 		p.SwitchToNextWindow()
	; 		sleep, 2000
	; 	}
	; }
	

	; WinClose, % "data:, - Chrome"
	; WinClose, % "Websta for Instagram"

	;sleep, 3000



	; sleep, 2500
	; while(p.FindElementByCss(".introjs-tooltipbuttons").tagName)
	; {
	; 	p.get("https://www.instagram.com/")
	; 	sleep, 2500
	; }
	fn_debug_log(A_Thisfunc " " ID " " PW)

	if(g_isDebug)
	{
		while(!fn_Debug_Fast_Get_TagName("#react-root > section > main > article > div > div > div > div > button") && !fn_Debug_Fast_Get_TagName("[name='username']"))
			sleep, 150
		if(fn_Debug_Fast_Get_TagName("[name='emailOrPhone']"))
			fn_Debug_Fast_ClickAndWaitFor("#react-root > section > main > article > div > div:nth-child(2) > p > a", "#react-root > section > main > article > div > div:nth-child(1) > div > form > a")
		else
			fn_Debug_Fast_ClickAndWaitFor("#react-root > section > main > article > div > div > div > div > button", "[name='username']")

		p.FindElementByCss("[name='username']").sendkeys(id)
		p.FindElementByCss("[name='password']").sendkeys(pw)

		fn_Debug_Fast_ClickAndWaitForNot("#react-root > section > main > article > div > div > div > form button")

		fn_Debug_Fast_ClickAndWaitForNot("#react-root > div > div > a:nth-child(2)")
		g_isLogin := true
		return
	}



	while(!p.FindElementByCss("#react-root > section > main > article > div > div > div > div > button").tagName && !p.FindElementByCss("[name='username']").tagName)
		sleep, 150
	;	가끔 로그인 페이지가 아닌 가입 페이지가 열린다. 거기서 로그인 페이지로 이동해주는 예외 스크립트.
	if(p.FindElementByCss("[name='emailOrPhone']").tagName)
		ClickAndWaitFor("#react-root > section > main > article > div > div:nth-child(2) > p > a", "#react-root > section > main article > div > div:nth-child(1) > div > form > a")
	else
		ClickAndWaitFor("#react-root > section > main > article > div > div > div > div > button", "[name='username']")
	
	sleep, 2500

	fn_Web_HTML_GetPos_Move("[name='username']")
	p.FindElementByCss("[name='username']").click()
	SlowSendKeys("[name='username']", id)
	while(p.FindElementByCss("[name='username']").value != id)
	{
		p.FindElementByCss("[name='username']").clear()
		SlowSendKeys("[name='username']", id)		
	}

	fn_Web_HTML_GetPos_Move("[name='password']")
	p.FindElementByCss("[name='password']").click()
	SlowSendKeys("[name='password']", pw)

	ClickAndWaitForNot("#react-root > section > main article > div > div > div > form button[type=submit]")

	ClickAndWaitForNot("#react-root > div > div > a:nth-child(2)")

	if(!g_isLogin && (InStr(p.url, "#") || InStr(p.url, "onetap")))
		p.get("https://www.instagram.com/")
	
	g_isLogin := true
}

;=====================================================================================;


fn_Web_Insta_Find(Keyword, URL) {
	p.Get("https://www.instagram.com/explore/")
	p.Get("https://www.instagram.com/explore/tags/" Keyword "/")
	fn_debug_log(A_ThisFunc " 페이지 이동 완료." Keyword )

	isSuccess := false
	_startTime := A_TickCount
	loop
	{
		if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > div > div").tagName)
		{
			isSuccess := true
			break
		}
		if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > p > a").tagName)
			break
		if(A_TickCount - _startTime >= g_RestartTime)
		{
			fn_debug_log("[REFRESH] " A_ThisFunc " LineNum " A_LineNumber)
			p.refresh() ;throw Exception(A_ThisFunc " " CssForWait)
			_startTime := A_TickCount
		}
		sleep, 100
	}
	
	if(!isSuccess)
	{
		fn_debug_log(A_Thisfunc " 차단된 키워드...")
		msgbox, 차단된 키워드입니다.`n%Keyword%`n`n프로그램을 재시작합니다.
		reload
		return
	}

	fn_debug_log(A_ThisFunc " 페이지 이동 대기 완료.")

	;	스크롤
	fn_Web_HTML_ScrollToElement("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(1) > div:nth-of-type(1) > a > div")
	sleep, 2500


	;	게시물 순회
	foundIDList := []
	foundIdx := -1
	foundURL := ""
	findURL := fn_Util_Get_Link_By_URL(URL)
	loop
	{
		cnt := p.ExecuteScript("function a() { return document.querySelectorAll(""#react-root > section > main > article > div:nth-of-type(2) > div > div > div"").length; } return a();")
		loop, % cnt
		{
			thisArticleID := fn_Web_Insta_Find_Get_nth_ArticleID(A_Index)

			if(findURL = fn_Util_Get_Link_By_URL(thisArticleID))
			{
				foundIdx := A_Index
				foundURL := thisArticleID
				break, 2
			}

			isDup := false
			for i, e in foundIDList
				if(e = thisArticleID)
				{
					isDup := true
					break
				}

			if(!isDup)
				foundIDList.Push(thisArticleID)

			if(foundIDList.Length() >= 50)
				break, 2
		}

		cntFloor := p.ExecuteScript("function a() { return document.querySelectorAll(""#react-root > section > main > article > div:nth-of-type(2) > div > div"").length; } return a();")
		fn_Web_HTML_ScrollToElement("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(" cntFloor ") > div:nth-of-type(1) > a > div")
		sleep, 2500
	}

	;	못 찾았으면
	if(foundIdx = -1)
	{
		msgbox, 해당 게시글을 찾지 못했습니다.`n프로그램을 재시작합니다.
		reload
	}

	;	찾았으면 이동
	fn_debug_log("Get : " foundURL)
	p.Get(foundURL)

	;	좋아요
	fn_debug_log("Try to Like.")
	fn_Web_HTML_ScrollToElement("article button.coreSpriteHeartOpen", "article button.coreSpriteHeartOpen [class*='filled']")
	ClickAndWaitFor("article button.coreSpriteHeartOpen", "article button.coreSpriteHeartOpen [class*='filled']")
	fn_debug_log("Success.")

	;	로그아웃
	fn_debug_log(A_ThisFunc " Quit and Logout.")
	p.Close()
	p.Quit()
	g_isLogin := false
}

fn_Util_Get_Link_By_URL(URL) {
	URL := RegExReplace(URL, "(.*)/$", "$1")
	RegExMatch(URL, "O)p/(\w*?)(/|$)", out)
	if(!out.count())
		return URL
	return out[1]
}

;=====================================================================================;

fn_Web_Insta_Delete_Article(cnt) {
	global
	; 1. 로그인
	; 2. 내정보
	; 3. 첫게시글 클릭
	; 4. 더보기 클릭
	; 5. 삭제 클릭
	; 6. 삭제 확인 클릭
	; 7. 창 꺼질때까지 대기
	; 8. 5초 대기
	; 9. 홈으로

	; 2. 내정보
	fn_Web_HTML_GetPos_Move("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a")
	ClickAndWaitFor("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a", "a[href*='/accounts/edit']", true) ; 내정보 버튼, 프로필 편집 버튼
	
	if(!g_isDebug)
		sleep, 3000

	; 맨 아래로 스크롤
	loop
	{
		allPageHeight := p.ExecuteScript("function a(){ return document.body.scrollHeight; } return a();")
		p.ExecuteScript("window.scrollBy(0, 999999999);")
		_measureStartTime := A_TickCount
		loop
		{
			_allPageHeight := p.ExecuteScript("function a(){ return document.body.scrollHeight; } return a();")
			if(allPageHeight <> _allPageHeight)
				break
			if(!g_isDebug)
				if(A_TickCount - _measureStartTime >= 7000)
					break, 2
			if(g_isDebug)
				if(A_TickCount - _measureStartTime >= 2000)
					break, 2
		}
		if(!g_isDebug)
			sleep, 1000
	}
	
	allCnt := p.ExecuteScript("function a() { return document.querySelectorAll('#react-root > section > main article > div > div > div > div a').length; } return a();")
	;msgbox,% allCnt

	urls := []
	loop, % cnt
	{
		url := p.ExecuteScript("function a() { return document.querySelectorAll('#react-root > section > main article > div > div > div > div a')[" allCnt - cnt + A_Index - 1 "].href; } return a();")
		url := RegExReplace(url, "\?.*")
		RegExMatch(url, "/p/(.*?)(/|$)", url)
		url := url1
		urls.Push(url)
	}
	maxIdx := urls.MaxIndex()



	loop, % cnt
	{
		fn_Web_HTML_ScrollToElement("#react-root > section > main article > div > div > div > div > a[href*=" urls[maxIdx - A_Index + 1] "] > div")
		sleep, 1500
		fn_Web_HTML_GetPos_Move("#react-root > section > main article > div > div > div > div > a[href*=" urls[maxIdx - A_Index + 1] "] > div")
		
		; 3. 게시글 클릭
		ClickAndWaitFor("#react-root > section > main article > div > div > div > div > a[href*=" urls[maxIdx - A_Index + 1] "]", "body > div:not([id=oinkandstuff]) > div > button", true)
		
		; 4. 더보기 클릭
		ClickAndWaitFor("body > div > div > div > div > article > div > button", "body > div > div > div > div > div > button:nth-of-type(2)")
		
		; 5. 삭제 클릭	
		ClickAndWaitForNot("body > div > div > div > div > div > button:nth-of-type(2)", "body > div > div > div > div > div > button:nth-of-type(3)")
		; 6. 삭제 확인 클릭
		; 7. 창 꺼질때까지 대기
		ClickAndWaitForNot("body > div > div > div > div > div > button:nth-of-type(1)", "body > div:not([id=oinkandstuff]) > div > button")
		
		sleep, 5000
	}
}


;=====================================================================================;


fn_Web_Insta_Get_List_Following(folderPath, idx := 3) {
	fn_debug_log(A_Thisfunc " folderPath : " folderPath " Idx : " idx)

	; p.get("https://www.instagram.com/")
	if(idx = 2)
		ClickAndWaitForNot("body > div > div > div > div > div > button") ; 닫기버튼
	else
	{
		fn_Web_HTML_GetPos_Move("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a")
		ClickAndWaitFor("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a", "a[href*='/accounts/edit']", true)
	}
	; fn_Web_HTML_GetPos_Move("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a")
	; 	ClickAndWaitFor("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a", "a[href*='/accounts/edit']", true)

	sleep, 1000
	fn_debug_log(A_Thisfunc " arrive my page.")

	ClickAndWaitFor("#react-root > section > main ul > li:nth-of-type(" idx ") > a", "body > div > div > div > div > ul:nth-of-type(1) > div > li")
	fn_debug_log(A_Thisfunc " opened list popup.")

	loop
	{
		allPageHeight := p.ExecuteScript("function a(){ return document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollHeight; } return a();")
		ScrollY := p.ExecuteScript("function a(){ return document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollTop; } return a();")
		p.ExecuteScript("document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollBy(0, 150);")
		_measureStartTime := A_TickCount
		loop
		{
			_allPageHeight := p.ExecuteScript("function a(){ return document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollHeight; } return a();")
			_ScrollY := p.ExecuteScript("function a(){ return document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollTop; } return a();")
			fn_debug_log(A_Thisfunc " Scrolling : " allPageHeight " " _allPageHeight)
			if(allPageHeight <> _allPageHeight || ScrollY <> _ScrollY)
				break
			if(A_TickCount - _measureStartTime >= 15000)
			{
				fn_debug_log(A_Thisfunc " Scrolling : 15s over. break double.")
				break, 2
			}
		}
		sleep, 10
	}
	fn_debug_log(A_Thisfunc " Scroll complete.")
	;msgbox, 페이지의 끝에 도달
	lists := []
	cnt := p.FindElementsByCss("body > div > div > div > div > ul:nth-of-type(1) > div > li").Count
	fn_debug_log(A_Thisfunc " list cnt : " cnt)
	loop,% cnt
	{
		name := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li:nth-of-type(" A_Index ") a[title]').title; } return f();")
		fn_debug_log(A_Thisfunc " pushed name : " name)
		if(!name)
			continue
		lists.Push(name)
	}
	
	if(folderPath)
	{
		today := A_Now
		for i, e in lists
			FileAppend, % e "`n", % folderPath "\" today " 팔로잉 목록.txt"
	}

	;msgbox,% DisplayObject(lists)

	;msgbox, 리스트 반환
	return lists
}

;=====================================================================================;

fn_Web_Insta_Get_List_UnFollow(folderPath) {
	followingList := fn_Web_Insta_Get_List_Following(0)
	followerList := fn_Web_Insta_Get_List_Following(0, 2)
	idx := 1
	loop
	{
		if(followingList.MaxIndex() < idx)
			break

		isFound := 0
		for i, e in followerList
		{
			if(e = followingList[idx])
			{
				isFound := i
				break
			}
		}

		if(isFound)
		{
			followingList.RemoveAt(idx)
			followerList.RemoveAt(i)
		}
		else
			idx++
	}

	today := A_Now
	for i, e in followingList
		FileAppend, % e "`n", % folderPath "\" today " 언팔로우 목록.txt"

	return followingList
}

;=====================================================================================;

fn_Web_Insta_UnFollow(filePath, interval) {
	;o := fn_Web_Insta_Get_List_Following(0)
	unfollowList := fn_File_Read_To_Object(filePath)
	today := A_Now

	FileAppend, % "언팔로우 대상 목록`n", % today "_결과.txt"
	for i, e in unfollowList
		FileAppend, % i "`t" e "`n", % today "_결과.txt"
	
	;	팔로잉 목록으로 가기
	fn_Web_HTML_GetPos_Move("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a")
	ClickAndWaitFor("#react-root > section > nav > div > div > div > div > div > div:nth-child(5) > a", "a[href*='/accounts/edit']", true)
	sleep, 1000
	fn_debug_log(A_Thisfunc " arrive my page.")

	ClickAndWaitFor("#react-root > section > main ul > li:nth-of-type(3) > a", "body > div > div > div > div > ul:nth-of-type(1) > div > li")
	fn_debug_log(A_Thisfunc " opened list popup.")

	;	현재 목록 읽어오기.
	lists := []
	cnt := p.FindElementsByCss("body > div > div > div > div > ul:nth-of-type(1) > div > li").Count
	fn_debug_log(A_Thisfunc " list cnt : " cnt)
	loop,% cnt
	{
		name := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li:nth-of-type(" A_Index ") a[title]').title; } return f();")
		fn_debug_log(A_Thisfunc " pushed name : " name)
		if(!name)
			continue
		lists.Push(name)
	}

	lastID := ""
	loop
	{
		;	find last ID's Index
		if(!lastID)
			idx := 0
		else
			idx := fn_Web_Insta_Find_Get_ArticleID_Index(lastID)

		;	다음 인덱스의 아이디 찾기.
		nextID := fn_Web_Insta_Find_Get_nth_ArticleID(idx+1)
		if(!nextID)	; 다음이 없으면 리스트의 끝. (미리 스크롤 하기 때문에 스크롤 문제는 없음)
			break

		;	그쪽으로 스크롤.
		msgbox
		;fn_Web_HTML_ScrollToElement
	}

	;fn_Web_Insta_Find_Get_nth_ArticleID
	;fn_Web_Insta_Find_Get_ArticleID_Index

	; 여기 이 함수를 쓸 게 아닌데 잘못 썼음. 수정..




	;	스크롤하기
	p.ExecuteScript("document.querySelector('body > div > div > div > div:nth-of-type(2)').scrollBy(0, 150);")

	for i, e in o
	{
		isFound := 0
		for i2, e2 in unfollowList
		{
			if(e = e2)
			{
				isFound := i
				break
			}
		}

		if(isFound)
		{
			_lastClickTime := 0
			loop
			{
				str := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li [title=""" e """]').parentNode.parentNode.parentNode.parentNode.parentNode.querySelector('button:not([disabled])').innerText; } return f();")
				if(str = "팔로우")
					break
				if(!str)
				{
					dbg1 := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li [title=""" e """]').parentNode.parentNode.parentNode.parentNode.parentNode.querySelector('button:not([disabled])').tagName; } return f();")
					dbg2 := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li [title=""" e """]').parentNode.parentNode.parentNode.parentNode.parentNode.querySelector('button').tagName; } return f();")
					dbg3 := p.ExecuteScript("function f() { return document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li [title=""" e """]').tagName; } return f();")
					FileAppend, % "★★" dbg1 "☆" dbg2 "☆" dbg3 "☆" str "☆`n", % today "_결과.txt"
					break
				}

				
				if(A_TickCount - _lastClickTime >= 15000)
				{
					FileAppend, % str "-" e "클릭`n", % today "_결과.txt"
					while(!p.FindElementByCss("body > div > div > div > div > div:nth-of-type(3) > button:nth-of-type(1)").tagName)
					{
						p.ExecuteScript("document.querySelector('body > div > div > div > div > ul:nth-of-type(1) > div > li [title=""" e """]').parentNode.parentNode.parentNode.parentNode.parentNode.querySelector('button:not([disabled])').click();")
						sleep, 1000
					}
					p.FindElementByCss("body > div > div > div > div > div:nth-of-type(3) > button:nth-of-type(1)").Click()
					_lastClickTime := A_TickCount
				}
				sleep, 250
			}
			FileAppend, % i "`t" e "`n", % today "_결과.txt"

			sleep, % interval * 1000
		}
		else
			FileAppend, % "--------" i "`t" e "`n", % today "_결과.txt"
	}


}

;=====================================================================================;

fn_Web_Insta_Upload(path, str) {
	
	st := A_TickCount
	lc := 0
	while(!WinExist("열기"))
	{
		if(A_TickCount - lc >= 1000 * 5)
		{
			p.FindElementByCss("#react-root > section > nav > div > div > div > div > div > div:nth-child(3)").click()
			lc := A_TickCount
		}
		if(A_TickCount - st >= g_RestartTime)
		{
			p.refresh() ;throw Exception(A_ThisFunc " " A_LineNumber " " path)
			st := A_TickCount
		}
		sleep, 150
	}

	loop
	{
		ControlGetText, t, Edit1, 열기
		if(t = path)
			break
		ControlSetText, Edit1, % path, 열기
	}
	sleep, 2000

	while(WinExist("열기"))
	{
		ControlClick, Button1, 열기
		ControlSend, Button1, {Enter Down}{Enter Up}, 열기
		sleep, 500
	}

	sleep, 5000
	
	ClickAndWaitFor("#react-root > section > div:nth-of-type(1) > header > div > div:nth-of-type(2) > button", "#react-root > section > div > section > div > textarea")
	
	SlowSendKeys("#react-root > section > div > section > div > textarea", str)
	
	ClickAndWaitForJS("#react-root > section > div:nth-of-type(1) > header > div > div:nth-of-type(2) > button", "#react-root > section > nav > div > div > div > div > div > div:nth-child(3)")

	sleep, 5000
}

;=====================================================================================;

fn_Web_Insta_Feed_Like(cnt, interval) {

	nowArticleID := fn_Web_Insta_Get_nth_ArticleID(1)
	stack := 0
	_cnt := 0
	loop
	{
		idx := fn_Web_Insta_Get_ArticleID_Index(nowArticleID)

		fn_Web_HTML_ScrollToElement("#react-root > section > main > section > div > div:nth-child(1) > div > article:nth-of-type(" idx ") > div > div > div > div > img , #react-root > section > main > section > div > div:nth-child(1) > div > article:nth-of-type(" idx ") > div > div > div > div > div")
		sleep, 2500	;	For Loading New Articles
		idx := fn_Web_Insta_Get_ArticleID_Index(nowArticleID)	;	recheck idx for loading

		;	check it can Like.
		if(p.FindElementByCss("#react-root > section > main > section > div > div > div > article:nth-of-type(" idx ") > div > section button:nth-child(1) > [class*='outline']").tagName)
		{
			;;	if it can, Likes and set Stack empty.
			
			fn_Web_HTML_ScrollToElement("#react-root > section > main > section > div > div > div > article:nth-of-type(" idx ") > div > section button:nth-child(1)")
			sleep, 2500	;	For Loading New Articles
			idx := fn_Web_Insta_Get_ArticleID_Index(nowArticleID)	;	recheck idx for loading
			
			ClickAndWaitFor("#react-root > section > main > section > div > div > div > article:nth-of-type(" idx ") > div > section button:nth-child(1)", "#react-root > section > main > section > div > div > div > article:nth-of-type(" idx ") > div > section button:nth-child(1) > [class*='filled']")
			
			stack := 0
			_cnt++
			if(_cnt >= cnt)
				break
			
			sleep, % interval * 1000
		}
		else
		{
			;;	stack and stack check
			stack++
			if(stack >= 4)
				break
		}

		;	Get Next Article ID
		;idx := fn_Web_Insta_Get_ArticleID_Index(nowArticleID)
		nowArticleID := fn_Web_Insta_Get_nth_ArticleID(idx + 1)
	}
}

fn_Web_Insta_Get_ArticlesCount() {
	return p.FindElementsByCss("#react-root > section > main > section > div > div > div > article").count
}

fn_Web_Insta_Get_nth_ArticleID(nth) {
	return p.FindElementByCss("#react-root > section > main > section > div > div > div > article:nth-of-type(" nth ") > div > div > a[href]").Attribute("href")
}

fn_Web_Insta_Get_Last_ArticleID() {
	return p.FindElementByCss("#react-root > section > main > section > div > div > div > article:nth-last-of-type(1) > div > div > a[href]").Attribute("href")
}

fn_Web_Insta_Get_ArticleID_Index(articleID) {
	cnt := fn_Web_Insta_Get_ArticlesCount()
	loop, % cnt
		if(articleID = fn_Web_Insta_Get_nth_ArticleID(A_Index))
			return A_Index
	return 0
}

fn_Web_Insta_Scroll_And_Loading() {
	lastID := fn_Web_Insta_Get_Last_ArticleID()
	p.ExecuteScript("window.scrollBy(0, 99999);")
	loop
	{
		newLastID := fn_Web_Insta_Get_Last_ArticleID()
		if(lastID <> newLastID)
			break
	}
}

;=====================================================================================;


fn_Web_Insta_Find_Follow_Like(path, searchCnt, cnt, followRate, FollowInterval) {
	lists := fn_File_Read_To_Object(path)
	usedTags := []

	loop, % searchCnt	; for search keyword
	{
		;p.get("https://www.instagram.com/")

		;fn_Web_HTML_GetPos_Move("#react-root > section > nav > div > div > div > div > div > div:nth-child(2) > a")
		;ClickAndWaitFor("#react-root > section > nav > div > div > div > div > div > div:nth-child(2) > a", "#react-root > section > main > div > article > div:nth-child(1) > div > div", true)
		p.Get("https://www.instagram.com/explore/")

		sleep, 1000

		;	search
		if(lists.MaxIndex() <= usedTags.MaxIndex())
		{
			;	태그 다 쓰면 유즈드를 초기화 하는 걸로 변경.
			;msgbox, % "팔로우 좋아요 작업의 태그 " lists.MaxIndex() "개를 모두 사용했습니다.`n작업을 완료합니다."
			;return
			fn_debug_log(A_ThisFunc " " searchCnt "개의 태그 모두 사용. 사용한 태그 목록 초기화.")
			usedTags := []
		}

		loop
		{
			r := getRandom(lists.MinIndex(), lists.MaxIndex())
			
			isDup := false
			for i, e in usedTags
			{
				if(e = r)
				{
					isDup := true
					break
				}
			}

			if(!isDup)
				break
		}
		usedTags.Push(r)

		fn_debug_log(A_ThisFunc "Random : " lists.MinIndex() " ~ " lists.MaxIndex() " -> " r "(" lists[r] ")")
		fn_debug_log2(A_Now " 태그 검색 - " lists[r])
		
		/*
		;ClickAndWaitFor("#react-root > section > nav > div > header h1 > div > input", ".coreSpriteSearchClear")
		p.FindElementByCss("#react-root > section > nav > div > header h1 > div > input").click()
		

		sleep, 1000
		
		SlowSendKeys("#react-root > section > nav > div > header h1 > div > input", lists[r])
		p.FindElementByCss("#react-root > section > nav > div > header h1 > div > input").sendkeys(Keys.Return)
		
		;WaitFor("#react-root > section > main > div > div > div > div > a[href='/explore/tags/" lists[r] "/']")
		WaitFor("#react-root > section > main > div > div > div > div > a[href*='/explore/tags/" lists[r] "/']")
		
		ClickAndWaitFor("#react-root > section > main > div > div > div > div > a[href*='/explore/tags/" lists[r] "/']", "#react-root > section > main > article > div:nth-of-type(2) > div > div")
		*/

		p.Get("https://www.instagram.com/explore/tags/" lists[r] "/")

		fn_debug_log(A_ThisFunc " 페이지 이동 완료." lists[r] )

		isSuccess := false
		_startTime := A_TickCount
		loop
		{
			if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > div > div").tagName)
			{
				isSuccess := true
				break
			}
			if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > p > a").tagName)
				break
			if(A_TickCount - _startTime >= g_RestartTime)
			{
				fn_debug_log("[REFRESH] " A_ThisFunc " LineNum " A_LineNumber)
				p.refresh() ;throw Exception(A_ThisFunc " " CssForWait)
				_startTime := A_TickCount
			}
			sleep, 100
		}
		
		if(!isSuccess)
		{
			fn_debug_log(A_Thisfunc " 차단된 키워드 [" lists[r] "] 넘어감.") 
			continue
		}

		fn_debug_log(A_ThisFunc " 페이지 이동 대기 완료.")

		;	스크롤
		fn_Web_HTML_ScrollToElement("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(1) > div:nth-of-type(1) > a > div")
		sleep, 2500
		;WaitFor("#react-root > section > main > article > div:nth-of-type(2) > div > div")

		;	click and follow and like.
		fn_debug_log("fn_Web_Insta_Find_Get_nth_ArticleID Try Now ArticleId := ... 1")
		nowArticleID := fn_Web_Insta_Find_Get_nth_ArticleID(1)
		fn_debug_log("Received ArticleId : " nowArticleID)
		loop, % cnt	; for articles
		{
			fn_debug_log("fn_Web_Insta_Find_Get_ArticleID_Index Try Now  : " nowArticleID)
			idx := fn_Web_Insta_Find_Get_ArticleID_Index(nowArticleID)
			fn_debug_log("Received index : " idx)

			if(!idx)
				break

			; fn_Web_HTML_GetPos_Move("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(" (idx - 1) // 3 + 1 ") > div:nth-of-type(" mod(idx - 1, 3) + 1 ") > a > div")
			; ClickAndWaitFor("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(" (idx - 1) // 3 + 1 ") > div:nth-of-type(" mod(idx - 1, 3) + 1 ") > a", "body > div > div > div > div > article > header > div > div > div > a", true)

			;	해당 게시글로 들어감
			fn_debug_log("Get : " nowArticleID)
			p.Get(nowArticleID)

			sleep, 1500

			;	에러 페이지 체크
			if(p.FindElementByCss(".error-container").tagName)
			{
				fn_debug_log("Error Page! Back to list.")
				continue
			}
			
			
			; Follow
			; Get Rate.
			if(getRandom(1, 100) <= followRate)
			{
				fn_debug_log("Try to Follow. follow text : [" fn_web_HTML_GetText("article header button") "]" )				
				if(fn_web_HTML_GetText("article header button") = "팔로우")
				{
					_lastClickTime := 0
					_startTime := A_TickCount
					while(fn_web_HTML_GetText("article header button") <> "팔로잉")
					{
						if(A_TickCount - _lastClickTime >= 10000)
						{
							fn_debug_log("Trying to Follow yet. follow text : [" fn_web_HTML_GetText("article header button") "]" )	
							;fn_Web_HTML_GetPos_Move("body > div > div > div > div > article > header > div > div > div button")
							;p.FindElementByCss("body > div > div > div > div > article > header > div > div > div button:not([disabled])").click()
							fn_Web_HTML_ScrollToElement("article header button")
							p.FindElementByCss("article header button").click()
							
							_lastClickTime := A_TickCount
						}
						sleep, 250
						if(A_TickCount - _startTime >= g_RestartTime)
						{
							p.refresh() ;throw Exception(A_ThisFunc " " A_LineNumber " Error While Find Following.")
							_startTime := A_TickCount
						}
					}	
				}
				else
					fn_debug_log("팔로우 못 찾음. [" fn_web_HTML_GetText("article header button") "]")
			}
			else
				fn_debug_log("Skip Follow.")

			; Like
			;fn_Web_HTML_GetPos_Move("body > div > div > div > div > article > div > section button:nth-of-type(1)")
			;ClickAndWaitFor("body > div > div > div > div > article > div > section button:nth-of-type(1)", "body > div > div > div > div > article > div > section button:nth-of-type(1) [class*='filled']", true)
			fn_debug_log("Try to Like.")
			fn_Web_HTML_ScrollToElement("article button.coreSpriteHeartOpen", "article button.coreSpriteHeartOpen [class*='filled']")
			ClickAndWaitFor("article button.coreSpriteHeartOpen", "article button.coreSpriteHeartOpen [class*='filled']")
			fn_debug_log("Success.")
				

			;if(p.FindElementByCss("body > div:not([id=oinkandstuff]) > div > button").tagName)
			;	ClickAndWaitForNot("body > div:not([id=oinkandstuff]) > div > button", 0, true)
			;else
			;	p.Back()
			p.Get("https://www.instagram.com/explore/tags/" lists[r] "/")

			fn_debug_log(A_ThisFunc " 페이지 복귀 완료." lists[r] )

			isSuccess := false
			_startTime := A_TickCount
			loop
			{
				if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > div > div").tagName)
				{
					isSuccess := true
					break
				}
				if(p.FindElementByCss("#react-root > section > main > article > div:nth-of-type(2) > p > a").tagName)
					break
				if(A_TickCount - _startTime >= g_RestartTime)
				{
					fn_debug_log("[REFRESH] " A_ThisFunc " LineNum " A_LineNumber)
					p.refresh() ;throw Exception(A_ThisFunc " " CssForWait)
					_startTime := A_TickCount
				}
				sleep, 100
			}
			
			if(!isSuccess)
			{
				fn_debug_log(A_Thisfunc " 차단된 키워드 [" lists[r] "] 넘어감.") 
				continue
			}

			fn_debug_log(A_ThisFunc " 페이지 복귀 대기 완료.")


			g_lastFollowTime := A_TickCount
			while(A_TickCount - g_lastFollowTime < FollowInterval * 1000)
				sleep, 250

			fn_debug_log("스크롤 시작")
			loop, % (idx - 1) // 3 + 1
			{
				fn_Web_HTML_ScrollToElement("#react-root > section > main > article > div:nth-of-type(2) > div > div:nth-of-type(" A_Index ") > div:nth-of-type(1) > a > div")
				sleep, 2500
				fn_debug_log("fn_Web_Insta_Find_Get_ArticleID_Index Try Now For Scroll  : " nowArticleID)
			}

			nowArticleID := fn_Web_Insta_Find_Get_nth_ArticleID(idx + 1)
		}

	}
}

_fn_Util_Get_Index_Of_Object(objs, idx) {
	for i in objs
	{
		if(A_Index = idx)
			return i
	}
	return false
}

fn_Web_Insta_Find_Get_nth_ArticleID(nth) {
	loop
	{
		ret := p.ExecuteScript("function f() { return document.querySelectorAll('#react-root > section > main > article > div:nth-of-type(2) > div > div > div > a')[" nth-1 "].href; } return f();")
		if(ret)
			break
		fn_debug_log(A_Thisfunc " Get " nth "th ArticleID Failed. : " ret)
		sleep, 5000
	}
	fn_debug_log(A_ThisFunc " " nth "th : " ret)
	return ret
}

fn_Web_Insta_Find_Get_ArticleID_Index(articleID) {
	loop
	{
		ret := p.ExecuteScript("function f() { var a = document.querySelectorAll('#react-root > section > main > article > div:nth-of-type(2) > div > div > div > a'); for(i=0; i<a.length; ++i) { if(a[i].href == '" articleID "') return i + 1; } return -1; } return f();")
		if(ret)
			break
		fn_debug_log(A_Thisfunc " Get ArticleID Index Failed. : " ret)
		sleep, 5000
	}
	return ret
}

;=====================================================================================;
;=====================================================================================;


fn_File_Read_To_Object(path, delimiter := "`n") {
	try
		FileRead, str, % path
	catch e2
	{
		Msgbox, % path "`n파일이 없습니다."
		throw Exception(path)
	}
	StringReplace, str, str, `r , , All

	obj := []
	loop, parse, str, % delimiter
	{
		if(!A_LoopField)
			continue
		obj.Push(A_LoopField)
	}
	return obj
}

fn_Web_Init(isMobile := false)
{
	p := ComObjCreate("Selenium.ChromeDriver")
	Keys := ComObjCreate("Selenium.Keys")
	ComObjError(false)
	;p.SetBinary(A_ScriptDir "\Chrome\Chrome.exe")
	;if(isMobile)
	;	p.AddArgument("--user-agent=Mozilla/5.0 (Linux; Android 4.4.2; ko-kr; AppleWebKit/537.36 (KHTML, like Gecko) Version/1.5 Chrome/28.0.1500.94 Mobile Safari/537.36")
	;else
	;	p.AddArgument("--user-agent=Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36")
	
	p.AddArgument("--window-size=1280,960")
	p.AddArgument("--window-position=100,10")
	;p.AddExtension("Websta-for-Instagram_v11.5.crx")
	p.AddExtension("Desktop-for-Instagram_v2.4.0.crx")
	;p.AddArgument("--incognito")
	;p.AddArgument("--disable-extensions")
	;p.AddArgument("--disable-popup-blocking")
}

getRandom(min, max) {
	Random, r, % (min ? min : 0), % (max ? max : 0)
	return r
}

ClickAndWaitForJS(CssForClick, CssForWait, isNotAnimate := false, TimeForWait := 0) {
	_startTime := A_TickCount
	lastClickTime := 0
	if(!TimeForWait)
		TimeForWait := 10000
	while(!p.FindElementByCss(CssForWait).tagName)
	{
		if(A_TickCount - lastClickTime >= TimeForWait)
		{
			if(!isNotAnimate)
			{
				fn_Web_HTML_ScrollToElement(CssForClick)
				fn_Web_HTML_GetPos_Move(CssForClick)
			}

			if(isObject(CssForClick))
				CssForClick.click()
			else
				p.ExecuteScript("document.querySelector(""" CssForClick """).click();")

			lastClickTime := A_TickCount
		}
		sleep, 250
		if(A_TickCount - _startTime >= g_RestartTime)
		{
			fn_debug_log("[REFRESH] " A_ThisFunc " " CssForClick " " CssForWait)
			p.refresh() ;throw Exception(A_ThisFunc " " A_LineNumber " " CssForClick " " CssForWait)
			_startTime := A_TickCount
		}
	}
}

ClickAndWaitFor(CssForClick, CssForWait, isNotAnimate := false, TimeForWait := 0) {
	_startTime := A_TickCount
	lastClickTime := 0
	if(!TimeForWait)
		TimeForWait := 10000
	while(!p.FindElementByCss(CssForWait).tagName)
	{
		if(A_TickCount - lastClickTime >= TimeForWait)
		{
			if(!isNotAnimate)
			{
				fn_Web_HTML_ScrollToElement(CssForClick)
				fn_Web_HTML_GetPos_Move(CssForClick)
			}

			if(isObject(CssForClick))
				CssForClick.click()
			else
				p.FindElementByCss(CssForClick).click()

			lastClickTime := A_TickCount
		}
		sleep, 250
		if(A_TickCount - _startTime >= g_RestartTime)
		{
			fn_debug_log("[REFRESH] " A_ThisFunc " " CssForClick " " CssForWait)
			p.refresh() ;throw Exception(A_ThisFunc " " A_LineNumber " " CssForClick " " CssForWait)
			_startTime := A_TickCount
		}
		p.FindElementByCss("[role=dialog]:not(.inb-photo-ctn) button:nth-of-type(2)").click()
	}
}

ClickAndWaitForNot(CssForClick, CssForWait := 0, isNotAnimate := false, TimeForWait := 0) {
	_startTime := A_TickCount
	lastClickTime := 0
	if(!TimeForWait)
		TimeForWait := 10000
	if(!CssForWait)
		CssForWait := CssForClick
	while(p.FindElementByCss(CssForWait).tagName)
	{
		if(A_TickCount - lastClickTime >= TimeForWait)
		{
			if(!isNotAnimate)
			{
				fn_Web_HTML_ScrollToElement(CssForClick)
				fn_Web_HTML_GetPos_Move(CssForClick)
			}
			if(isObject(CssForClick))
				CssForClick.click()
			else
				p.FindElementByCss(CssForClick).click()
			lastClickTime := A_TickCount
		}
		sleep, 250
		if(A_TickCount - _startTime >= g_RestartTime)
		{
			fn_debug_log("[REFRESH] " A_ThisFunc " " CssForClick " " CssForWait)
			p.refresh() ;throw Exception(A_ThisFunc " " A_LineNumber " " CssForClick " " CssForWait)			
			_startTime := A_TickCount
		}
		if(!g_isLogin && (InStr(p.url, "#") || InStr(p.url, "onetap")))
		{
			; https://www.instagram.com/accounts/login/ 제외.

			;msgbox,% p.url
			p.get("https://www.instagram.com/")
			return
		}
		
		p.FindElementByCss("[role=dialog]:not(.inb-photo-ctn) button:nth-of-type(2)").click()
	}
}

WaitFor(CssForWait)
{
	_startTime := A_TickCount
	while(!p.FindElementByCss(CssForWait).tagName)
	{
		if(A_TickCount - _startTime >= g_RestartTime)
		{
			fn_debug_log("[REFRESH] " A_ThisFunc " " CssForWait)
			p.refresh() ;throw Exception(A_ThisFunc " " CssForWait)
			_startTime := A_TickCount
		}
		sleep, 100
	}
}

SlowSendKeys(css, words, sleepTime := 100)
{
	loop, parse, words
	{
		p.FindElementByCss(css).sendkeys(A_LoopField)
		sleep, % sleepTime
	}
}

fn_Web_HTML_GetTop(css)
{
	topPos := 0
	depth := 0
	loop
	{
		js := "document.querySelector(""" css """)"
		loop, % depth
			js .= ".offsetParent"
		tagName := p.ExecuteScript("function a(){ return " js ".tagName; } return a();")
		if(!tagName)
			break
		topPos += p.ExecuteScript("function a(){ return " js ".offsetTop; } return a();")
		depth++
	}

	return topPos
}

fn_Web_HTML_ScrollToElement(css, isMiddle := true)
{
	allPageHeight := p.ExecuteScript("function a(){ return document.body.scrollHeight; } return a();")
	innerHeight := p.ExecuteScript("function a(){ return window.innerHeight; } return a();")
	elementTop := fn_Web_HTML_GetTop(css)
	if(isMiddle)
		elementTop += p.ExecuteScript("function f(css) { a = document.querySelector(css); return a.offsetHeight / 2; } return f(""" css """);")

	if(elementTop <= innerHeight / 2)
		return
	
	if(allPageHeight - innerHeight - elementTop >= 0)
		reviseOffset := innerHeight / 2
	else
		reviseOffset := 0

	scrollValue := elementTop - reviseOffset

	script =
	(
		function scrollTo(element, to, duration) {
			if (duration <= 0) return;
			var difference = to - element.scrollTop;
			var perTick = difference / duration * 10;

			setTimeout(function() {
				element.scrollTop = element.scrollTop + perTick;
				if (element.scrollTop === to) return;
				scrollTo(element, to, duration - 10);
			}, 10);
		}
	)

	;msgbox,% script " scrollTop(document.querySelector('html,body'), " scrollValue ", 600);"

	p.ExecuteScript(script " scrollTo(document.querySelector('html,body'), " scrollValue ", 600);")

	;p.ExecuteScript("function b() { var headTag = document.querySelector('head'); var newScript = document.createElement('script'); newScript.type = 'text/javascript'; newScript.onload = function() { console.log('자바스크립트 로드 완료'); function a() { $('html,body').animate({scrollTop: " elementTop - reviseOffset "}, 500); } a(); }; newScript.src = 'https://t1.daumcdn.net/tistory_admin/lib/jquery/jquery-3.2.1.min.js'; headTag.appendChild(newScript); } b();")
	sleep, 1000
}

fn_Web_HTML_GetPos_Move(css) 
{
	;return ;+
	;y 85 + 40
	ret := p.ExecuteScript("function f(css) { a = document.querySelector(css); t = 35 + 40 - window.scrollY + a.offsetHeight / 2; l = a.offsetWidth / 2; while(a) { t += a.offsetTop; l += a.offsetLeft; a = a.offsetParent; } return (l << 16) | t; } return f(""" css """);")
	_left := (ret & 0xFFFF0000) >> 16
	_top := ret & 0x0000FFFF
	MouseMove, % _left, % _top
	sleep, 250
}

fn_web_HTML_GetText(css)
{
	return p.ExecuteScript("function f(css) { return document.querySelector(""" css """).outerText; } return f();")
}

fn_debug_log(str)
{
	FileAppend, % str "`n`n", debug.log
}
fn_debug_log2(str)
{
	FileAppend, % str "`n", 태그검색기록.txt
}

#include <DisplayObject>

getpw()
{
	return "tjddms1"
}