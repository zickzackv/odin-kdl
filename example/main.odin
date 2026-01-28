package kdlExample
import "base:runtime"

import sa "core:container/small_array"
import "core:flags"
import "core:fmt"
import oos "core:os"
import os "core:os/os2"
import "core:strings"
import kdl "kdl"

Options :: struct {
	verbose:  bool `usage:"Show verbose output"`,
	debug:    bool `args:"hidden" usage:"print debug info"`,
	file:     oos.Handle `args:"pos=0,required,file=r" usage:"kdl input file."`,
	overflow: string,
}

// global options
opt: Options

Action :: union #no_nil {
	int,
	string,
}

Button :: struct {
	number:   int,
	action:   Action,
	disabled: bool,
}

Led :: struct {
  number:     int,
	mode:       int,
	color:      int,
	duration:   int,
	brightness: int,
}

Resolution :: struct {
	number:  int,
	enabled: bool,
	dpi:     int,
	active:  bool,
}

Profile :: struct {
	number:      int,
	active:      bool,
	name:        string,
	enabled:     bool,
	resolutions: sa.Small_Array(3, Resolution),
	// dpi is actually the currently active resolutions dpi
	rate:        int,
	angle_snap:  int,
	debounce:    int,
	buttons:     sa.Small_Array(10, Button),
	leds:        sa.Small_Array(2, Led),
}

Parser_State :: struct {
	profile:        ^Profile,
	current_node:   enum {
		None,
		Profile,
		Button,
		Led,
		Resolution,
		DPI,
		Rate,
		Name,
		Mode,
		Color,
		Duration,
		Brightness,
	},
	active_action:  enum {
		None,
		Key,
		Macro,
		Alias,
	},
	current_button: ^Button,
	current_led:    ^Led,
	current_res:    ^Resolution,
}

MAX_PROFILES :: 1

profiles: [MAX_PROFILES]Profile

main :: proc() {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)

	parse_args()

	file := os.new_file(uintptr(int(opt.file)), "input.kdl")

	if opt.debug {
		fmt.printfln("%#v", opt)
		fmt.printfln("%#v", file)
	}

	parser := kdl.create_stream_parser(reader, cast(rawptr)file, .DEFAULTS)
	defer kdl.destroy_parser(parser)

	profile := Profile{}
	parse_kdl(parser, &profile)
	fmt.printfln("%#v", profile)
}

parse_kdl :: proc(parser: ^kdl.parser, p: ^Profile) {
	state := Parser_State {
		profile = p,
	}

	for {
		ev := kdl.parser_next_event(parser)
		if ev == nil || ev.event == .EOF do break

		#partial switch ev.event {
		case .START_NODE:
			name := string(ev.name.data)
			switch name {
			case "Profile":
				state.current_node = .Profile
			case "Button":
				// Fallunterscheidung: Sind wir schon in einem Button?
				// Wenn ja, ist das neue "Button" ein Alias-Knoten.
				if state.current_node == .Button {
					state.active_action = .Alias
				} else {
					sa.append(&p.buttons, Button{})
					idx := sa.len(p.buttons) - 1
					state.current_button = sa.get_ptr(&p.buttons, idx)
					state.current_node = .Button
				}
			case "Key":
				state.active_action = .Key
			case "Macro":
				state.active_action = .Macro
			case "Resolution":
				sa.append(&p.resolutions, Resolution{})
				idx := sa.len(p.resolutions) - 1
				state.current_res = sa.get_ptr(&p.resolutions, idx)
				state.current_node = .Resolution
			case "DPI":
				state.current_node = .DPI
			case "Led":
				sa.append(&p.leds, Led{})
				idx := sa.len(p.leds) - 1
				state.current_led = sa.get_ptr(&p.leds, idx)
				state.current_node = .Led
			case "Rate":
				state.current_node = .Rate
			case "Name":
				state.current_node = .Name
			case "Mode":
				state.current_node = .Mode
			case "Color":
				state.current_node = .Color
			case "Duration":
				state.current_node = .Duration
			case "Brightness":
				state.current_node = .Brightness
			}

		case .ARGUMENT:
			handle_argument(&state, ev)

		case .PROPERTY:
			handle_property(&state, ev)

		case .END_NODE:
			// Wenn eine Action (Key/Macro/Alias) endet, setzen wir nur den Action-Status zurück
			if state.active_action != .None {
				state.active_action = .None
			} else {
				state.current_node = .Profile
			}
		}
	}
}

handle_argument :: proc(s: ^Parser_State, ev: ^kdl.event_data) {
	// 1. Priorität: Sind wir gerade dabei, eine Action zu befüllen?
	if s.current_node == .Button && s.active_action != .None {
		#partial switch s.active_action {
		case .Key, .Macro:
			if ev.value.type == .STRING {
				s.current_button.action = strings.clone(string(ev.value.string.data))
			}
		case .Alias:
			if ev.value.type == .NUMBER {
				s.current_button.action = int(ev.value.number.integer)
			}
		}
		return
	}


	// 2. Standard-Argumente (Profile Nummer, Button Nummer, etc.)
	#partial switch s.current_node {
	case .Profile:
		if ev.value.type == .NUMBER do s.profile.number = int(ev.value.number.integer)
		if ev.value.type == .STRING do s.profile.name = strings.clone(string(ev.value.string.data))
	case .Name:
		if ev.value.type == .STRING do s.profile.name = strings.clone(string(ev.value.string.data))
	case .Button:
		if ev.value.type == .NUMBER do s.current_button.number = int(ev.value.number.integer)
	case .Rate:
		if ev.value.type == .NUMBER do s.profile.rate = int(ev.value.number.integer)
	case .Led:
  	if ev.value.type == .NUMBER do s.current_led.number = int(ev.value.number.integer)
	case .Mode:
		if ev.value.type == .STRING {
			mode_value := string(ev.value.string.data)
			if mode_value == "off" do s.current_led.mode = 0
			if mode_value == "on" do s.current_led.mode = 1
			if mode_value == "cycle" do s.current_led.mode = 2
			if mode_value == "brightness" do s.current_led.mode = 3
		} else {
			s.current_led.mode = 0
		}
	case .Color:
		if ev.value.type == .NUMBER do s.current_led.color = int(ev.value.number.integer)
	case .Duration:
		if ev.value.type == .NUMBER do s.current_led.duration = int(ev.value.number.integer)
	case .Brightness:
		if ev.value.type == .NUMBER do s.current_led.brightness = int(ev.value.number.integer)
	case .Resolution:
  	if ev.value.type == .NUMBER do s.current_res.number = int(ev.value.number.integer)
	case .DPI:
		if ev.value.type == .NUMBER do s.current_res.dpi = int(ev.value.number.integer)
	}
}

// Spezialisierter Handler für Properties (name=value)
handle_property :: proc(state: ^Parser_State, ev: ^kdl.event_data) {
	prop_name := string(ev.name.data)
	p := state.profile

	#partial switch state.current_node {
	case .Profile:
		if prop_name == "active" {
			state.profile.active = bool(ev.value.boolean)
		}
	case .Resolution:
		if sa.len(p.resolutions) > 0 {
			idx := sa.len(p.resolutions) - 1
			res := sa.get_ptr(&p.resolutions, idx)
			switch prop_name {
			case "enable":
				res.enabled = bool(ev.value.boolean)
			case "active":
				res.active = bool(ev.value.boolean)
			}
		}
	}
}

reader :: proc "c" (file: rawptr, buffer: cstring, size: uint) -> uint {
	context = runtime.default_context()
	read_bytes, error := os.read(cast(^os.File)file, ([^]u8)(buffer)[:size])
	if error != nil {
		fmt.println(error)
		return cast(uint)read_bytes
	}
	return cast(uint)read_bytes
}

parse_args :: proc() {
	style: flags.Parsing_Style = .Unix

	flags.parse_or_exit(&opt, os.args, style)
}

