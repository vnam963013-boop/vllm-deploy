# filename: stress_test.py
import time
import os

def stress_cpu(duration_sec):
    """
    Stresses the CPU for a specified duration using a busy-wait loop.
    This consumes CPU cycles without using external libraries.
    """
    print(f"Starting CPU stress for {duration_sec} seconds...")
    end_time = time.time() + duration_sec
    # This loop continuously executes, keeping a CPU core busy.
    while time.time() < end_time:
        pass
    print("CPU stress finished.")

def stress_memory(duration_sec):
    """
    Stresses memory by continuously allocating large lists of data.
    This is done without external libraries, using standard Python list objects.
    """
    print(f"Starting memory stress for {duration_sec} seconds...")
    end_time = time.time() + duration_sec
    memory_chunks = []
    # Allocate memory until the duration is almost over.
    # We need to be careful not to let it grow indefinitely if the stress duration is very short.
    # This loop will keep allocating memory.
    try:
        while time.time() < end_time:
            # Allocate a moderately large chunk of memory.
            # Adjust the size (e.g., 1000000 elements) based on your machine's RAM
            # and how much you want to consume.
            # Using a large list of numbers as an example.
            chunk_size = 500000 # roughly 2MB per chunk * 8 bytes per float = ~1.6GB per chunk
            new_chunk = [i * 1.0 for i in range(chunk_size)]
            memory_chunks.append(new_chunk)
            # Optional: small sleep to prevent it from consuming *all* memory instantly if duration is short.
            # time.sleep(0.001)
    except MemoryError:
        print("MemoryError encountered: Not enough memory to allocate.")
    finally:
        # It's good practice to clear it, though in this script, it'll be short-lived.
        # For long-running stress tests, managing memory release is crucial.
        del memory_chunks # Release memory
        print("Memory stress finished.")


def run_stress_test(stress_duration=10, interval_sec=60):
    """
    Runs CPU and memory stress tests periodically.

    Args:
        stress_duration (int): The duration in seconds for each stress test.
        interval_sec (int): The total interval in seconds between the start of stress tests.
    """
    print(f"Stress test script started. Running every {interval_sec} seconds, with a {stress_duration} second load.")
    print("Press Ctrl+C to stop.")

    while True:
        print("-" * 30)
        print(f"Starting stress cycle at {time.strftime('%Y-%m-%d %H:%M:%S')}")

        # Run CPU stress
        stress_cpu(stress_duration)

        # Run Memory stress
        # Ensure memory stress doesn't start if CPU stress already took too long
        if time.time() - (time.time() - stress_duration) < stress_duration:
            stress_memory(stress_duration)
        else:
            print("Skipping memory stress due to CPU stress taking too long.")


        # Calculate remaining sleep time
        elapsed_time_this_cycle = time.time() - (time.time() - stress_duration) # approx time since cycle began
        wait_time = interval_sec - elapsed_time_this_cycle
        if wait_time > 0:
            print(f"Cycle finished. Waiting for {wait_time:.2f} seconds before next cycle...")
            time.sleep(wait_time)
        else:
            print("Stress test duration exceeded interval. Starting next cycle immediately.")
        print("-" * 30)

if __name__ == "__main__":
    try:
        run_stress_test(stress_duration=10, interval_sec=60)
    except KeyboardInterrupt:
        print("\nStress test script stopped by user.")
    except Exception as e:
        print(f"\nAn unexpected error occurred: {e}")
