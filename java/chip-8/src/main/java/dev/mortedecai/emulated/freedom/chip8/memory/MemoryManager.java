package dev.mortedecai.emulated.freedom.chip8.memory;

/**
 * MemoryManager is responsible for managing the chip-8 memory allocation.
 *
 * @author mortedecai
 */
public class MemoryManager {
    public static final int KILOBYTE = 1024;
    public static final int CHIP_8_MEMORY_MAX = 4 * KILOBYTE;

    /**
     * The memory for the emmulator
     */
    private byte[] memory;
    /**
     * The maximum amount of memory available in the manager
     */
    public final int maxMemory;

    /**
     * Factory method to return a Chip-8 Memory Manager.
     * This memory manager will have <i>CHIP_8_MEMORY_MAX</i> bytes of memory available for use.
     * @return a new MemoryManager with <i>CHIP_8_MEMORY_MAX</i> bytes of available memory.
     */
    public static MemoryManager Chip8MemoryManager() {
        return new MemoryManager(CHIP_8_MEMORY_MAX);
    }

    public String toJSON() {
        return "\"memory\": {\"maxMemory\": " + this.maxMemory + "}";
    }

    /**
     * Creates a new MemoryManager of the specified size.
     * @param size The number of bytes of memory to allocate.
     */
    private MemoryManager(final int size) {
        super();
        this.memory = new byte[size];
        this.maxMemory = size;
    }

}
