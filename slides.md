---
paginate: true
page_number: true
---

![bg right:40% 90%](mario-adjacent-crab.png)

# **NES Programming in Rust**

## Sydney Rust Meetup 2023-03-01

#### Stephen Sherratt (@gridbugs)

gridbugs.org
github.com/gridbugs
hachyderm.io/@gridbugs
twitch.tv/gridbugs

---

# Demo (video) 🤞🤞🤞

![bg left:40% 90%](screenshot.png)

[https://youtu.be/QHoISiWdPXo](https://youtu.be/QHoISiWdPXo)

---

![bg 80%](github.png)

---
# 6502 Assembler Rust EDSL

Defining and calling a function with string labels:

```rust
b.label("set_cursor_to_tile_coord"); // define a function with a label
b.inst(Txa, ());               // x component passed in X register
b.inst(Asl(Accumulator), ());  // multiply by 8 (width of tile)
b.inst(Asl(Accumulator), ());
b.inst(Asl(Accumulator), ());
b.inst(Sta(Absolute), Addr(var::cursor::X));
b.inst(Tya, ());               // y component passed in Y register
...
b.inst(Rts, ());               // Return from subroutine
...
// call a function
b.inst(Ldx(ZeroPage), var::bit_table_entry::TILE_X);
b.inst(Ldy(ZeroPage), var::bit_table_entry::TILE_Y);
b.inst(Jsr(Absolute), "set_cursor_to_tile_coord");
```
---
# 6502 Assembler Rust EDSL

Static data:

```rust
b.label("blink_colour_table");
const BLINK_COLOURS: [u8; 8] = [
    0x20,
    0x20,
    0x10,
    0x10,
    0x00,
    0x00,
    0x10,
    0x10,
];
for c in BLINK_COLOURS {
    b.literal_byte(c);
}
...
b.inst(Tax, ()); // transfer the blink index into X register
b.inst(Ldy(AbsoluteXIndexed), "blink_colour_table"); // read current blink colour
b.write_ppu_address(0x3F11); // write the blink colour to the palette
b.inst(Sty(Absolute), Addr(0x2007));
```

---
# 6502 Assembler Rust EDSL

Platform-specific extension:

```rust
trait BlockNes {
    fn init_ppu(&mut self);
    fn write_ppu_address(&mut self, addr: u16);
    fn write_ppu_value(&mut self, value: u8);
    fn set_ppu_nametable_coord(&mut self, col: u8, row: u8);
    fn set_ppu_palette_universal_background(&mut self, value: u8);
    ...
}

impl BlockNes for Block { ... }

fn program(b: &mut Block) {
    b.inst(...);
    ...
}
```

---
# 6502 Assembler Rust EDSL

Rust is a macro language!

```rust
// Read 8 consecutive bytes from a little-endian address stored
// at var::bit_table_address::LO into a buffer beginning at
// var::bit_table_entry::START.
b.inst(Ldx(Immediate), 0);
for i in 0..8 {
    b.inst(Lda(XIndexedIndirect), var::bit_table_address::LO);
    b.inst(Sta(ZeroPage), var::bit_table_entry::START + i);
    b.inst(Inc(ZeroPage), var::bit_table_address::LO);
}
```
---
# 6502 Assembler Rust EDSL

![bg right:30% 90%](inc.png)

Addressing mode errors are type errors:

```rust
b.inst(Inc(AbsoluteYIndexed), 0x0000);
```

```
error[E0277]: the trait bound
`AbsoluteYIndexed: instruction::dec::AddressingMode`
is not satisfied
```

---

# Usage

```rust
use mos6502_assembler::Block;

fn prg_rom() -> Vec<u8> {
    // A Block is an intermediate representation that keeps track of labels
    // and a cursor so you can put code/data at specific addresses.
    let mut b = Block::new();
    // describe program
    b.inst(...);
    b.label(...);
    b.literal_byte(...);
    // ...etc

    // convert from intermediate representation to byte array
    // (this pass is needed to resolve labels)
    let mut prg_rom = Vec::new();
    b.assemble(/* start address */ 0x8000, /* ROM bank size */ 0x4000, &mut prg_rom)
        .expect("Failed to assemble");
    prg_rom
}
```
