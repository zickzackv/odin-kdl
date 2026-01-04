package kdlExample

import "core:runtime"
import "core:flags"
import "core:fmt"
import oos "core:os"
import os "core:os/os2"
import kdl "kdl"

Options :: struct {
	verbose:  bool `usage:"Show verbose output"`,
	debug:    bool `args:"hidden" usage:"print debug info"`,
	file:     oos.Handle `args:"pos=0,required,file=r" usage:"kdl input file."`,
	overflow: string,
}

// global options
opt: Options

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


	ev: ^kdl.event_data = nil
	for {
		ev = kdl.parser_next_event(parser)
		fmt.println(ev)
		if ev.event == kdl.event.EOF || ev.event == kdl.event.PARSE_ERROR {
			break
		}
	}
}

// read_func :: proc "c" (rawptr, cstring, uint) -> c.size_t
reader :: proc "c" (file: rawptr, buffer: cstring, size: uint) -> uint {
	context = runtime.default_context()
	read_bytes, error := os.read(cast(^os.File)file, ([^]u8)(buffer)[:size])
  if error != nil {
    fmt.println(error)
    return cast(uint)read_bytes
  }
  return cast(uint)read_bytes
}

parse_args :: proc()
{
	style: flags.Parsing_Style = .Unix

	flags.parse_or_exit(&opt, os.args, style)
}

