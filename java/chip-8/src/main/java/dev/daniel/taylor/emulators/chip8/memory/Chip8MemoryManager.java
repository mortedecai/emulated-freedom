package dev.daniel.taylor.emulators.chip8.memory;

public class Chip8MemoryManager implements MemoryManager {
    public static final int MAX_MEMORY_FOOTPRINT = 4 * 1024;
    public static final int PROGRAM_LOAD_START = 0x200;
    private byte[] memory;

    public Chip8MemoryManager() {
        this.memory = new byte[MAX_MEMORY_FOOTPRINT];
        for (int i = 0; i < MAX_MEMORY_FOOTPRINT; i++) {
            this.memory[i] = (byte)0;
        }
    }
    @Override
    public boolean loadData(int startingLocation, byte[] data) throws EmulatorMemoryException {
        if (startingLocation + data.length > Chip8MemoryManager.MAX_MEMORY_FOOTPRINT) {
            throw new EmulatorMemoryException("oom: program too large");
        }
        System.arraycopy(data, 0, this.memory, startingLocation, data.length);
        // TODO: {DT} Change to logging setup
        IO.println("stored " + data.length + " bytes in memory.");
        return true;
    }

    @Override
    public byte readByte(int memoryLocation) throws EmulatorMemoryException {
        if (memoryLocation < 0 || memoryLocation >= MAX_MEMORY_FOOTPRINT) {
            throw new EmulatorMemoryException("invalid starting location:  " + memoryLocation);
        }
        return this.memory[memoryLocation];
    }

    @Override
    public byte[] readBytes(int startingMemoryLocation, int count) throws EmulatorMemoryException {
        byte[] toReturn = new byte[count];
        System.arraycopy(this.memory, startingMemoryLocation, toReturn, 0, count);
        return toReturn;
    }

    @Override
    public int getMemoryLoadStart() {
        return Chip8MemoryManager.PROGRAM_LOAD_START;
    }
}
