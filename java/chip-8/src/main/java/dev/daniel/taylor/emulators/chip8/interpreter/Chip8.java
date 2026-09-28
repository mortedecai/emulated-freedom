package dev.daniel.taylor.emulators.chip8.interpreter;

import dev.daniel.taylor.emulators.chip8.memory.EmulatorMemoryException;
import dev.daniel.taylor.emulators.chip8.memory.MemoryManager;

import com.google.inject.Inject;

import java.io.IOException;
import java.io.InputStream;

public class Chip8 implements Interpreter {
    private static final String PFX_RESOURCE = "res:";
    private final MemoryManager memoryManager;

    @Inject
    public Chip8(final MemoryManager memoryManager) {
        this.memoryManager = memoryManager;
    }

    @Override
    public boolean loadProgram(final String path) {
        if (path.startsWith(PFX_RESOURCE)) {
            loadResourceProgram(path.substring(PFX_RESOURCE.length()));
        }
        return false;
    }

    @Override
    public void clearProgram() {
        throw new IllegalStateException("not yet implemented");
    }

    @Override
    public void runProgram() {
        throw new IllegalStateException("not yet implemented");
    }

    /**
     * Loads a CHIP-8 program from the resource directory.
     * @return true if the file was loaded into memory successfully.
     */
    private boolean loadResourceProgram(final String path) {
        ClassLoader loader = getClass().getClassLoader();
        try (InputStream inputStream = loader.getResourceAsStream(path)) {
            if (null == inputStream) {
                throw new IllegalArgumentException("resource file not found: " + path);
            }

            byte[] data = inputStream.readAllBytes();
            return this.memoryManager.loadData(this.memoryManager.getMemoryLoadStart(), data);
        } catch (IOException | EmulatorMemoryException e) {
            throw new RuntimeException(e);
        }
    }
}
