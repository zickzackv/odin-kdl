package kdlExample

import "core:fmt"
import sa "core:container/small_array"

// Pretty Print Funktionen
print_profile :: proc(p: Profile) {
	fmt.println("═══════════════════════════════════════════════════════")
	fmt.printf("Profile %d", p.number)
	if p.name != "" {
		fmt.printf(" - \"%s\"", p.name)
	}
	if p.active {
		fmt.print(" [ACTIVE]")
	}
	fmt.println()
	fmt.println("═══════════════════════════════════════════════════════")

	// Settings
	if p.rate > 0 {
		fmt.printf("  Poll Rate: %d Hz\n", p.rate)
	}
	if p.angle_snap > 0 {
		fmt.printf("  Angle Snap: %d°\n", p.angle_snap)
	}
	if p.debounce > 0 {
		fmt.printf("  Debounce: %d ms\n", p.debounce)
	}

	// Resolutions
	if sa.len(p.resolutions) > 0 {
		fmt.println("\n  Resolutions:")
		for i in 0..<sa.len(p.resolutions) {
			res := sa.get(p.resolutions, i)  // Kein & und kein ^
			status := ""
			if res.active do status = " [ACTIVE]"
			if !res.enabled do status = " [DISABLED]"
			fmt.printf("    %2.1d. %d DPI%s\n", res.number, res.dpi, status)
		}
	}

	// Buttons
	if sa.len(p.buttons) > 0 {
		fmt.println("\n  Buttons:")
		for i in 0..<sa.len(p.buttons) {
			btn := sa.get(p.buttons, i)  // Kein & und kein ^
			action_str := ""
			switch a in btn.action {
			case int:
				action_str = fmt.tprintf("→ Button %d", a)
			case string:
				action_str = fmt.tprintf("\"%s\"", a)
			}
			disabled := btn.disabled ? " [DISABLED]" : ""
			fmt.printf("    %2.1d: %s%s\n", btn.number, action_str, disabled)
		}
	}

	// LEDs
	if sa.len(p.leds) > 0 {
		fmt.println("\n  LEDs:")
		for i in 0..<sa.len(p.leds) {
			led := sa.get(p.leds, i)  // Kein & und kein ^
			mode_str := ""
			switch led.mode {
			case 0: mode_str = "Off"
			case 1: mode_str = "On"
			case 2: mode_str = "Cycle"
			case 3: mode_str = "Brightness"
			case: mode_str = fmt.tprintf("Unknown(%d)", led.mode)
			}
			fmt.printf("    %2.1d: %s", led.number, mode_str)
			if led.color > 0 {
				fmt.printf(", Color: #%06X", led.color)
			}
			if led.brightness > 0 {
				fmt.printf(", Brightness: %d%%", led.brightness)
			}
			if led.duration > 0 {
				fmt.printf(", Duration: %dms", led.duration)
			}
			fmt.println()
		}
	}

	fmt.println("═══════════════════════════════════════════════════════")
}
