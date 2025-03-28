# zxdiag
![App window](Sample.png?raw=true)

A lightweight, cross-platform alternative to DirectX Diagnostic Tool (dxdiag) written in Zig and raylib.

## About
- Fast, native performance with zero garbage collection
- Real-time system information monitoring
- Built with Zig for memory safety and C-like performance
- Modern UI with tabs for System, Display, Sound, and Input information
- Export diagnostics to log files

## Requirements
- Zig 0.11.0 or later
- raylib
- raygui
- zenity (for file dialogs)

## Build & Run
Clone the repository
```bash
git clone https://github.com/iliyalb/zxdiag
cd zxdiag
```

Create vendor directory
```bash
mkdir -p vendor
```

Download and extract raylib
```bash
cd vendor
git clone https://github.com/raysan5/raylib.git
cd raylib
git checkout 4.5.0
cd ..
```

Download and extract raygui
```bash
git clone https://github.com/raysan5/raygui.git
cd raygui
git checkout 3.0
cd ../..
```

Build and run
```bash
zig build run
```

## Contributing
Contributions are welcome! Feel free to submit issues and pull requests.

## License
This is free and unencumbered software released into the public domain under The Unlicense.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

See [UNLICENSE](LICENSE) for full details.
