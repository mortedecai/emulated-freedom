package dev.mortedecai.emulated.freedom.chip8;

import dev.mortedecai.emulated.freedom.chip8.interpreter.Chip8Interpreter;

/**
 * Driver program for the chip-8 emulator
 */
public class Main {
    static void main() {
        Chip8Interpreter interpreter = new Chip8Interpreter();
        IO.println(interpreter.toJSON());
    }
}
