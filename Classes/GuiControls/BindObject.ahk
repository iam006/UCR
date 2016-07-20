﻿; ======================================================================== BINDOBJECT ===============================================================
; A BindObject represents a collection of keys / mouse / joystick buttons
class _BindObject {
	Type := 0 ; 0 = Unset, 1 = Key / Mouse, 2 = stick button, 3 = stick hat
	Buttons := []
	Wild := 0
	Block := 0
	Suppress := 0
	
	__New(obj){
		this._Deserialize(obj)
	}
	
	_Serialize(){
		obj := {Buttons: [], Wild: this.Wild, Block: this.Block, Suppress: this.Suppress, Type: this.Type}
		Loop % this.Buttons.length(){
			obj.Buttons.push(this.Buttons[A_Index]._Serialize())
		}
		return obj
	}
	
	_Deserialize(obj){
		for k, v in obj {
			if (k = "Buttons"){
				Loop % v.length(){
					this.Buttons.push(new _Button(v[A_Index]))
				}
			} else {
				this[k] := v
			}
		}
	}
	
	; Builds a human-readable form of the BindObject
	BuildHumanReadable(){
		max := this.Buttons.length()
		str := ""
		Loop % max {
			str .= this.Buttons[A_Index].BuildHumanReadable()
			if (A_Index != max)
				str .= " + "
		}
		return str
	}
}