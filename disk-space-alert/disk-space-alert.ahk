; @Author  Vlle
; @Date    2017-07-13
; @Version 0.1

; @Description
;  Show notification when free Diskspace drops below specified size.

#SingleInstance, Force
#NoEnv
;#NoTrayIcon

Menu, tray, icon, %A_WinDir%\system32\mmcndmgr.dll, 16

; ==============================================

GoTo, main
#include <class_notify>

;F2:: Reload
main:

; ==============================================

global cfg := new Config(A_ScriptDir . "\config.ini")
global ntfy := new Notify("", cfg.ntfy_monitor, "opacity="(cfg.ntfy_opacity*2.25)" background="(cfg.ntfy_rgb)" time="(cfg.ntfy_time*1000), False)

; ==============================================

diskspace_min := humanReadableToByte(cfg.alert_below) // 1024**2

DriveSpaceFree, diskspace, % cfg.drive
if (diskspace > diskspace_min) {
    ntfy.setText("Free Diskspace: "(diskspace//1024)"GB, Alert below: "(diskspace_min//1024)"GB")
    ntfy.FadeInOut(5000,, True)
}

loop {
    if (A_Index != 1)
        sleep, % cfg.interval *1000
    
    DriveSpaceFree, diskspace, % cfg.drive
    
    if (diskspace <= diskspace_min)
    {
        ntfy.setText("Free Diskspace: "(diskspace//1024)"GB")
        if !FileExist(cfg.alert_sound)
            ntfy.FadeInOut() ; Fade Gui in and out
        else
        { ; Fade Gui in and out with Sound
            ntfy.fadeIn()
            fadedInAt := A_TickCount
            SoundPlay, % cfg.alert_sound, 1
            if (A_TickCount-fadedInAt < ntfy.opt.fadeStayTime) ; Sleep if Sound was too short
                Sleep, % ntfy.opt.fadeStayTime-(A_TickCount-fadedInAt)
            ntfy.fadeOut()
        }
    }
}
ExitApp



; ======================< Configuration >===============================================================================================
; ==================< Configuration >===============================================================================================

class Config {
    _ := {}
    
    __new(configFile) {
        ObjRawSet(this, "", {})
        
        this.configFile := configFile
    }
    
	__get(key)
	{
        local val
		if (key != "base") and (subStr(key,1,1) != "_")
		{
			if !this[""].haskey(key) {
				IniRead, val, % this.configFile, main, % key, % A_Space
                this["",key] := trim(val)
            }
            return this["",key]
		}
	}
}



; ======================< Functions >===============================================================================================
; ==================< Functions >===============================================================================================

humanReadableToByte(size) {
    local type
    
    type := subStr(size, -1)
    if type is alpha
    {
        size := subStr(size, 1, StrLen(size)-2)
        
        if (type = "TB") {
            size *= 1024**4
        } else if (type = "GB") {
            size *= 1024**3
        } else if (type = "MB") {
            size *= 1024**2
        } else if (type = "KB") {
            size *= 1024**1
        }
    }
    
    return size
}

errorExit(message) {
    MsgBox, % message
    ExitApp
}
