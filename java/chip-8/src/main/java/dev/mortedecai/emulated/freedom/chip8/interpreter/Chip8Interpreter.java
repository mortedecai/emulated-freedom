package dev.mortedecai.emulated.freedom.chip8.interpreter;

import dev.mortedecai.emulated.freedom.chip8.memory.MemoryManager;

/**
 * The Chip8Interpreter is the main object for the Chip-8 Java based interpreter.
 * It holds the underlying memory, registers, opcode parser, etc.
 */
public class Chip8Interpreter {
    private final MemoryManager memoryManager;

    public Chip8Interpreter() {
        this.memoryManager = MemoryManager.Chip8MemoryManager();
    }

    public String toJSON() {
        return "{\n\r\t\"chip8\": {\n\r\t\t" + memoryManager.toJSON() + "\n\r\t}\n\r}\n\r";
    }
}
