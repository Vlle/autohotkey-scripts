; @Author:  Vlle
; @Date:    2016-12-01
; @Version: 1.0


; ======================< Notify >=====================================================
; ==================< Notify >=====================================================

; Notify as Function
;  - direct output
;  - return instance
Notify(args*) {
	n := new notify(args*)
	if (n.opt.fadeStayTime>0) or (n.opt.fadeTime>0)
		n.FadeInOut()
	return n
}

; Notify (Banner Notifications)
; Some Gui Code comes from tmplinshi's KeypressOSD
;
; @Arguments
;  - str      text   - Text to display
;  - str/int  parent - Where to show Gui - str: Window Title, int: Monitor Number
;  - int      guiNum - Number of the Gui (useless at the moment)
;  - str      opt    - options (look below)
;
class Notify
{
	; =============< options >===========================
	static optConf := [["fadeStayTime","t","time"], ["fadeTime","f","fade"], ["fadeWait","w","wait"], ["maxOpacity","o","opacity"], ["bgColor","b","background"], ["text","T","text"], ["fontColor","C","color"], ["fontSize","S","size"]]
	opt := {}
	
	opt.fadeStayTime := 2000
	opt.fadeTime     := 200
	;opt.fadeWait     := True ; defined in __New
	opt.maxOpacity   := 200
	
	opt.bgColor      := "000000"
	
	opt.text         := ""
	opt.font         := "Arial"
	opt.fontColor    := "FFFFFF"
	opt.fontSize     := 20
	opt.fontBold     := "bold" ; "bold" or ""
	
	opacity   := 0
	parent    := 1
	
	
	; =============< __New >===========================
	; Create Gui and set Variables
	__New(text="", parent=1, opt="", fadeWait=True)
	{
		global Notify_GuiText
		
		this.name := GetUniqueGuiName()
		
		Gui, % this.name . ": new"
		Gui, % this.name . ": +LastFound +AlwaysOnTop -Caption +ToolWindow +Owner +E0x20 +E0x8000000" ; +E0x20 = click trough(when transparent), E0x8000000(WS_EX_NOACTIVATE) = don't focus
		this.id := WinExist()
		
		Gui, % this.name . ": Margin", 0, 15
		Gui, % this.name . ": Color", % this.opt.bgColor
		Gui, % this.name . ": Font", % "c"this.opt.fontColor " s"this.opt.fontSize " "this.opt.fontBold, % this.opt.font
		
		; options
		if opt !=
			this.SetOpt(opt)
		this.opt.fadeWait := fadeWait
		
		; Text
		Gui, % this.name . ": Add", Text, Center vNotify_GuiText, %text% ; width is set with Parent
		this.opt.text := text
		
		; Parent
		this.setParent(parent)
		
		; Show (Invisible)
		WinSet, Transparent, 0
		Sleep, 1
		Gui, % this.name . ": +ToolWindow" ; Prevent showing in Taskbar
		Gui, % this.name . ": Show", % "NA" " x"(this.winX) " y"(this.winY+this.winH*0.08) " w"(this.winW)
	}
	
	; =============< __Delete >===========================
	__Delete()
	{
		if this.IsVisible()
			this.FadeOut()
		Gui, % this.name . ": destroy"
	}
	
	
	; =============< Is Visible >===========================
	IsVisible() {
		return this.opacity>0 ? True : False
	}
	
	
	; =============< Set options >===========================
	; @Args
	;  - str opt - options separated by spaces (use Quotation marks for spaces in an option: SetOpt("T""My Text with a Quotation mark: """", and many Spaces"" o200")
	;
	; @Return str array - changed Options
	;
	; Available options (case sensitive):
	;  t - Time Message Stays (without fading)
	;  f - Fading Time
	;  o - Opacity (0-255)
	;  b - Background Color: "RRGGBB"
	;  T - Text
	;  C - Font Color: "RRGGBB"
	;  S - Font Size
	SetOpt(opt)
	{
		changed := SetOpt(this.opt, opt, this.optConf)
		for, i, k in changed
		{
			v := this.opt[k]
			
			if (k=="maxOpacity") { ; Opacity (0-255)
				this.opt.maxOpacity := v<1? 1 : v>255 ? 255 : v
			}
			else if (k=="bgColor") { ; Background Color: "RRGGBB"
				Gui, % this.name . ": Color", %v%
			}
			else if (k=="text") { ; Text
				setText := 1
			}
			else if (k=="fontColor") { ; Font Color: "RRGGBB"
				Gui, % this.name . ": Font", c%v%
				GuiControl, % this.name . ": Font", Notify_GuiText
			}
			else if (k=="fontSize") { ; Font Size
				setText := 1
				Gui, % this.name . ": Font", s%v%
			}
		}
		if setText
			this.setText(this.opt.text, 1)
		return changed
	}

	
	; =============< Set Text >===========================
	; Gui will not be high enough when there are automatic linebreaks
	; Use slowMode if you change(d) the Font or number of Lines
	SetText(text, slowMode=0)
	{
		GuiControl, % this.name . ":", Notify_GuiText, %text%
		this.opt.text := text
		if !slowMode
			return
		
		guiSize := winGetRect("ahk_id" this.id)
		
		if (guiSize[1] and guiSize[2])
		{
			GuiControlGet, Notify_GuiText, % this.name . ": Pos"
			
			lines := 0
			loop, parse, % text, `n
				lines += 1
			
			textH := lines * GetTextExtentPoint(text, this.opt.font, this.opt.fontSize, this.opt.fontBold)[2]
			GuiControl, % this.name . ": Move", Notify_GuiText, h%textH%
			GuiControl, % this.name . ": Font", Notify_GuiText
			Gui, % this.name . ": Show", % "NoActivate" " x"(this.winX) " y"(this.winY+this.winH*0.08) " w"(this.winW) " h"(guiSize[2]+textH-Notify_GuiTextH)
		}
	}
	
	
	; =============< Set Parent >===========================
	; Set Window or Monitor number, the Notification appears in.
	; If parent is an Integer, it is recogniced as a Monitor.
	SetParent(parent)
	{
		; if parent is a window, test if it's valid. If not use Monitor 1
		if parent is not integer
		{
			WinGet, winId, ID, %parent%
			if winId {
				WinGetPos,,, winW, winH, ahk_id%winId%
				if (winW and winH)
				     this.winX:=this.winY:=0, this.winW:=winW, this.winH:=winH
				else parent = 1
			}
			else parent = 1
		}
		
		if parent is not integer
		{
			DllCall("user32\SetParent", "uint", this.id, "uint", winId)
		}
		else
		{
			SysGet, MonitorCount, MonitorCount
			if (parent > MonitorCount) or (parent < 1)
				parent = 1
			SysGet, m, MonitorWorkArea, %parent%
			this.winX:=(mLeft), this.winY:=(mTop), this.winW:=(mRight-mLeft), this.winH:=(mBottom-mTop)
			
			; Un-SetParent (previous Parent wasn't a Monitor)
			if !(this.parent // 1) and (this.parent != 0) ; is not integer
			{
				WinGet, activeId, ID, A
				WinExist("ahk_id" this.id)
				WinHide ; to make it not pop up with WinSet Transparent
				WinSet, Transparent, 255 ; After SetParent the Opacity can't get higher than it was before (don't know why)
				DllCall("user32\SetParent", "uint", this.id, "uint", 0) ; Un-SetParent
				WinSet, Transparent, 0 ; Make invisible
				WinShow ; Show invisible Gui
				WinMove,,,,, % this.winW ; Redraw (WinSet Redraw doesn't work)
				IfWinNotActive, ahk_id %activeId%
					WinActivate, ahk_id %activeId%
				WinExist("ahk_id" this.id)
			}
			
			WinMove, % "ahk_id" this.id,, % this.winX, % (this.winY+this.winH*0.08), % this.winW
		}
		
		GuiControl, % this.name . ": Move", Notify_GuiText, % "w"(this.winW)
		this.parent := parent
	}
	
	
	; =============< Show >===========================
	; Change settings and show (use FadeInOut if you don't want to change Settings)
	; -1 means use previous
	Show(text="", parent=-1, opt="", fadeWait=-1)
	{
		if this.IsVisible()
			this.fadeOut()
		if opt
			this.SetOpt(opt)
		if (parent != -1) and ((parent != this.parent) or (parent == "A"))
			this.setParent(parent)
		if (fadeWait != -1)
			this.fadeWait := fadeWait
		if text !=
			this.setText(text)
		this.fadeInOut()
	}
	
	
	; =============< Fade in out >===========================
	; Fade Gui in and out
	; (-1 means use opt Variables)
	FadeInOut(fadeStayTime=-1, fadeTime=-1, fadeWait=-1)
	{
		% (fadeStayTime==-1 ? fadeStayTime := this.opt.fadeStayTime)
		% (fadeTime==-1     ? fadeTime     := this.opt.fadeTime)
		% (fadeWait==-1     ? fadeWait     := this.opt.fadeWait)
		
		this.fade(fadeTime, this.opt.maxOpacity, fadeWait)
		
		if fadeWait {
			Sleep, %fadeStayTime%
			this.fade(fadeTime, 0, 1)
		}
		else {
			f := ObjBindMethod(this, "Fade", fadeTime, 0)
			SetTimer, %f%, % -fadeStayTime-fadeTime
		}
	}
	
	; =============< Fade in >===========================
	; (-1 means use opt Variables)
	FadeIn(fadeTime=-1, fadeWait=-1) {
		this.fade(fadeTime, this.opt.maxOpacity, fadeWait)
	}
	
	; =============< Fade out >===========================
	; (-1 means use opt Variables)
	FadeOut(fadeTime=-1, fadeWait=-1) {
		this.fade(fadeTime, 0, fadeWait)
	}
	
	; =============< Fade >===========================
	; Fade to specified Opacity
	; @Arguments (-1 means use opt Variables)
	;  - int  fadeTime  - How much ms fading takes
	;  - int  toOpacity - Fade to this Opacity (0-255)
	;  - bool fadeWait  - Wait till Animation ends?
	;
	Fade(fadeTime=-1, toOpacity=-1, fadeWait=-1)
	{
		Gui, % this.name . ": +AlwaysOnTop" ; get's lost sometimes
		% (fadeTime==-1  ? fadeTime  := this.opt.fadeTime)
		% (toOpacity==-1 ? toOpacity := (this.opacity>0 ? 0 : this.opt.maxOpacity))
		% (fadeWait==-1  ? fadeWait  := this.opt.fadeWait)
		
		WinFade(this.id, this.opacity, toOpacity, fadeTime, fadeWait)
		this.opacity := toOpacity
	}
}