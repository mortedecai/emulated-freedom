package dev.daniel.taylor.emulators.chip8;

/**
 * Emulator is the Driver class for the Chip-8 Emulator.
 * @author Dan Taylor (@mortedecai)
 */
public class Emulator {

    public static void main(String[] args) {
        IO.println("Chip-8 Emulator Starting");
        IO.print("Arguments:");
        IO.println(printArgs(args));
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
