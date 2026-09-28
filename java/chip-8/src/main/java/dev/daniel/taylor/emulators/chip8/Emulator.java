package dev.daniel.taylor.emulators.chip8;

import com.google.inject.Guice;
import com.google.inject.Inject;
import com.google.inject.Injector;
import dev.daniel.taylor.emulators.chip8.interpreter.Chip8;
import dev.daniel.taylor.emulators.chip8.interpreter.Interpreter;

/**
 * Emulator is the Driver class for the Chip-8 Emulator.
 * @author Dan Taylor (@mortedecai)
 */
public class Emulator {
    //private static final String fontProgramPath = "res:roms/font.ch8";
    // TODO: {DT} Change back to just the font load after testing.
    private static final String fontProgramPath = "res:roms/font-and-print.ch8";

    private Interpreter interpreter;

    @Inject
    Emulator(Interpreter interpreter) {
        this.interpreter = interpreter;
    }

    /**
     * starts the emulator running
     */
    void start() {
        this.interpreter.loadProgram(fontProgramPath);
    }

    static void main(String[] args) {
        IO.println("Chip-8 Emulator Starting");
        IO.print("Arguments:");
        IO.println(printArgs(args));
        Injector injector = Guice.createInjector(new Module());
        Emulator emulator = injector.getInstance(Emulator.class);
        emulator.start();
    }

    public static String printArgs(String[] args) {
        StringBuilder sb = new StringBuilder();
        sb.append('[');
        for (int i = 0; i < args.length; i++) {
            sb.append(' ');
            sb.append(args[i]);
        }
        sb.append(" ]");
        return sb.toString();
    }
}
