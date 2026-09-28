package dev.daniel.taylor.emulators.chip8.memory;

/**
 * MemoryManager provides the interface to interact with the emulated memory space.
 *
 * This includes managing reads and writes, ensuring nothing happens outside the allowable memory space.
 */
public interface MemoryManager {
    /**
     * Loads the provided <code>data</code> bytes into contiguous memory starting at <code>staritngLocation</code>.
     * @param startingLocation The memory location to start writing in.
     * @param data The data to write to the memory location.
     * @return True if the data is written successfully, false otherwise.
     * @throws EmulatorMemoryException if there is an issue loading the data into the memory space.
     */
    boolean loadData(int startingLocation, byte[] data) throws EmulatorMemoryException;

    /**
     * ReadByte reads a single byte at the specified memory location.
     * If there is any issue reading that memory location, an EmulatorMemoryException is thrown with the correct error code.
     * @param memoryLocation The memory location to read.
     * @return The byte at <code>memoryLocation</code>.
     * @throws EmulatorMemoryException if there is an issue reading from <code>memoryLocation</code>.
     */
    byte readByte(int memoryLocation) throws EmulatorMemoryException;
    /**
     * ReadBytes reads the bytes from <code>startingMemoryLocaiton</code> for <code>count</code> bytes.
     * If there is any issue reading that memory set, an EmulatorMemoryException is thrown with the correct error code.
     * @param startingMemoryLocation The memory location to read.
     * @return The bytes from [<code>startingMemoryLocation</code> to <code>startingMemoryLocation + count</code>).
     * @throws EmulatorMemoryException if there is an issue reading from <code>memoryLocation</code>.
     */
    byte[] readBytes(int startingMemoryLocation, int count) throws EmulatorMemoryException;

    /**
     * Gets the memory location at which programs are able to start being loaded into memory.
     * @return The memory location the program is loaded into.
     */
    int getMemoryLoadStart();
}
