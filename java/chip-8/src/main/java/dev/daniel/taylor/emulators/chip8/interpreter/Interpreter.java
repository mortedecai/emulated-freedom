package dev.daniel.taylor.emulators.chip8.interpreter;

/**
 * Interpreter is the interface representation of an interpreter for a CHIP-8 ROM.
 *
 * The interpreter interface allows the user to load a program into memory, clear the program and
 * start executing the program.
 */
public interface Interpreter {
    /**
     * Loads the CHIP-8 binary data from <code>path</code> into memory starting at address <code>0x200</code>.
     * @param path The path of the binary ROM to load.
     * @return true if the load was successful, false otherwise.
     */
    boolean loadProgram(final String path);

    /**
     * clearProgram sets the memory from <code>0x200</code> to 0.
     */
    void clearProgram();

    /**
     * runProgram starts the program running from memory location 0x200.
     */
    void runProgram();
}
