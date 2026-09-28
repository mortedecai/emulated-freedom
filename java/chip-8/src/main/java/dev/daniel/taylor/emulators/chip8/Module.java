package dev.daniel.taylor.emulators.chip8;

import com.google.inject.AbstractModule;
import dev.daniel.taylor.emulators.chip8.interpreter.Chip8;
import dev.daniel.taylor.emulators.chip8.interpreter.Interpreter;
import dev.daniel.taylor.emulators.chip8.memory.Chip8MemoryManager;
import dev.daniel.taylor.emulators.chip8.memory.MemoryManager;

public class Module extends AbstractModule {
    @Override
    protected void configure() {
        bind(Interpreter.class).to(Chip8.class);
        bind(MemoryManager.class).to(Chip8MemoryManager.class);
    }
}
