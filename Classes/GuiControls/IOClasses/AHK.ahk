; ToDo - Rename to IOControlClasses ?
; AHK IOClasses
; These classes handle most of the functionality of a GUIControl's appearance while bound to one of these IOClasses

; These IOClasses are for input detection methods that AHK supports natively
; ie the Hotkey command and GetKeystate for input and SendXXXX etc for Output

; Common functions for AHK Keyboard and Mouse GuiControls
class AHK_KBM_Common extends _UCR.Classes.IOClasses.IOClassBase {
	static IsInitialized := 1
	static IsAvailable := 1
	
	static _Modifiers := ({91: {s: "#", v: "<"},92: {s: "#", v: ">"}
	,160: {s: "+", v: "<"},161: {s: "+", v: ">"}
	,162: {s: "^", v: "<"},163: {s: "^", v: ">"}
	,164: {s: "!", v: "<"},165: {s: "!", v: ">"}})

	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		max := this.Binding.length()
		str := ""
		Loop % max {
			str .= this.BuildKeyName(this.Binding[A_Index])
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
	
	; Builds the AHK key name
	BuildKeyName(code){
		static replacements := {33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Insert", 46: "Delete"}
		static additions := {14: "NumpadEnter"}
		if (ObjHasKey(replacements, code)){
			return replacements[code]
		} else if (ObjHasKey(additions, code)){
			return additions[code]
		} else {
			return GetKeyName("vk" Format("{:x}", code))
		}
	}
	
	; Returns true if this Button is a modifier key on the keyboard
	IsModifier(code){
		return ObjHasKey(this._Modifiers, code)
	}
	
	; Renders the keycode of a Modifier to it's AHK Hotkey symbol (eg 162 for LCTRL to ^)
	RenderModifier(code){
		return this._Modifiers[code].s
	}
}

; IOClass for AHK Keyboard and Mouse Input GuiControls
class AHK_KBM_Input extends _UCR.Classes.IOClasses.AHK_KBM_Common {
	static IOClass := "AHK_KBM_Input"
	static OutputType := "AHK_KBM_Output"
	BindOptions := {wild: 0, block: 0, suppress: 0}
	_CurrentBinding := 0
	
	_DisableItems := []

	AddMenuItems(){
		wild := this.ParentControl.AddMenuItem("Wild", "Wild", this._ChangedValue.Bind(this, 1))
		block := this.ParentControl.AddMenuItem("Block", "Block", this._ChangedValue.Bind(this, 2))
		suppress := this.ParentControl.AddMenuItem("Suppress Repeats", "SuppressRepeats", this._ChangedValue.Bind(this, 3))
		this._DisableItems := [wild, block, suppress]
	}
	
	_ChangedValue(o){
		if (o == 1){
			; Wild
			this.BindOptions.wild := !this.BindOptions.wild
		} else if (o == 2){
			; Block
			this.BindOptions.block := !this.BindOptions.block
		} else if (o == 3){
			; Suppress
			this.BindOptions.suppress := !this.BindOptions.suppress
		}
		bo := this._Serialize()
		bo.Delete("Binding")	; get rid of the binding, so it does not stomp on the current binding
		this.ParentControl.Set(bo)
	}
	
	UpdateMenus(cls){
		state := ((cls == this.IOClass) && this.ParentControl.GetBinding().Binding[1])
		for i, item in this._DisableItems {
			item.SetEnableState(state)
		}
	}

	_Delete(){
		this.RemoveBinding()
	}
	
	__Delete(){
		OutputDebug % "UCR| AHK_KBM_Input Freed"
	}
}

; IOClass for AHK Keyboard and Mouse Output GuiControls
class AHK_KBM_Output extends _UCR.Classes.IOClasses.AHK_KBM_Common {
	static IOType := 1
	static IOClass := "AHK_KBM_Output"

	SetState(state){
		tooltip % "UCR| SetState: " state
	}
	
	AddMenuItems(){
	}
	
	_ChangedValue(o){
	}
}

; IOClass for AHK Joystick Button Input GuiControls
class AHK_JoyBtn_Input extends _UCR.Classes.IOClasses.IOClassBase {
	static IOClass := "AHK_JoyBtn_Input"
	static IsInitialized := 1

	_CurrentBinding := 0
	
	_Delete(){
		this.RemoveBinding()
	}
	
	BuildHumanReadable(){
		return "Stick " this.DeviceID " Button " this.Binding[1]
	}
	
	ButtonEvent(e){
		this.ParentControl.ChangeStateCallback.Call(e)
	}
}

; IOClass for AHK Joystick Axis Input GuiControls
class AHK_JoyAxis_Input extends _UCR.Classes.IOClasses.IOClassBase {
	static IOClass := "AHK_JoyAxis_Input"
	static IsInitialized := 1
	_JoyMenus := []
	_StickMenus := []
	_AxisMenus := []
	
	AddMenuItems(){
		static AHKAxisList := ["X","Y","Z","R","U","V"]
		menu := this.ParentControl.AddSubMenu("Stick", "AHKStick")
		Loop 8 {
			this._StickMenus.push(menu.AddMenuItem(A_Index, A_Index, this._ChangedValue.Bind(this, A_Index)))
		}
		menu := this.ParentControl.AddSubMenu("Axes ", "Axes")
		this._JoyMenus.Push(menu)
		Loop 6 {
			this._AxisMenus.Push(menu.AddMenuItem(A_Index " - " AHKAxisList[A_Index], A_Index, this._ChangedValue.Bind(this, 100 + A_Index)))
		}
	}
	
	BuildHumanReadable(){
		if (this.DeviceID && this.Binding[1]){
			return "Stick " this.DeviceID ", Axis " this.Binding[1]
		} else if (this.DeviceID){
			return "Pick an Axis (Stick " this.DeviceID ")"
		}
	}
	
	_ChangedValue(o){
		bo := {IOClass: "AHK_JoyAxis_Input"}
		if (o < 9){
			; Stick ID
			bo.DeviceID := o
		} else if (o > 100 && o < 107){
			; Axis ID
			o -= 100
			bo.Binding := [o]
		}
		this.ParentControl.Set(bo)
	}
	
	UpdateMenus(cls){
		static AHKAxisList := ["X","Y","Z","R","U","V"]
		state := (this.DeviceID)
		for i, menu in this._JoyMenus {
			menu.SetEnableState(state)
		}
		Loop 8 {
			stick := A_Index
			ji := (GetKeyState(stick "JoyInfo"))
			this._StickMenus[A_Index].SetEnableState(ji)
			;if (UCR.UserSettings.GuiControls.ShowJoystickNames){
			;	name := " (" DllCall("JoystickOEMName\joystick_OEM_name", double,A_Index, "CDECL AStr") ")"
			;}
		}
		if (this.DeviceID){
			ji := (GetKeyState(this.DeviceID "JoyInfo"))
			if (this.DeviceID){
				Loop 4 {
					this._AxisMenus[A_Index].SetEnableState(InStr(ji, AHKAxisList[A_Index+2]))
				}
			}
		}
	}
}

; IOClass for AHK Joystick Hat Input GuiControls
class AHK_JoyHat_Input extends _UCR.Classes.IOClasses.IOClassBase {
	static IOClass := "AHK_JoyHat_Input"
	static IsInitialized := 1

	UpdateMenus(cls){
		
	}

	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		static hat_directions := ["Up", "Right", "Down", "Left"]
		return "Stick " this.DeviceID ", Hat " hat_directions[this.Binding[1]]
	}
}