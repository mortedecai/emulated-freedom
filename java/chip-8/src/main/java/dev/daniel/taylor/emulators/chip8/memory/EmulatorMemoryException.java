package dev.daniel.taylor.emulators.chip8.memory;

/**
 * EmulatorMemoryException is a wrapper exception to differentiate memory issues from other emulator issues.
 */
public class EmulatorMemoryException extends Exception {
  /**
   * Creates a new EmulatorMemoryException which holds information about the memory issue encountered.
   * @param message The message exception.
   */
  public EmulatorMemoryException(String message) {
        super(message);
    }
}
