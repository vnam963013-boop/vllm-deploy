import time
import os
import sys
import multiprocessing

def get_system_info():
    """Dynamically get system CPU cores and total memory (GB)"""
    cpu_count = multiprocessing.cpu_count()
    
    # Get total memory (applicable for Linux)
    mem_total_gb = 1.0
    try:
        with open('/proc/meminfo', 'r') as f:
            for line in f:
                if 'MemTotal' in line:
                    mem_total_kb = int(line.split()[1])
                    mem_total_gb = mem_total_kb / 1024 / 1024
                    break
    except:
        # Fallback
        mem_total_gb = 2.0 
        
    return cpu_count, mem_total_gb

def cpu_worker(target_cpu_ratio, duration):
    """
    Control CPU usage of a single core by mixing work and sleep periods.
    e.g., target_cpu_ratio=0.20 means work for 0.01s, sleep for 0.04s.
    """
    end_time = time.time() + duration
    frame_time = 0.05  # Total time per frame: 50ms
    work_time = frame_time * target_cpu_ratio
    sleep_time = frame_time - work_time

    while time.time() < end_time:
        start_frame = time.time()
        # Busy loop
        while time.time() - start_frame < work_time:
            pass
        # Idle state
        time.sleep(sleep_time)

def run_stress(duration=10):
    cpu_count, mem_total_gb = get_system_info()
    
    # Target: 20% Total CPU, 30% Total Memory
    target_core_load = 0.20 * cpu_count
    if target_core_load > 0.95:
        # Limit single core max load to 95% for safety
        target_core_load = 0.95
        
    target_mem_gb = mem_total_gb * 0.30
    
    print("-" * 40)
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Triggering stress cycle...")
    print(f"System Info: {cpu_count} CPU core(s), Total Memory: {mem_total_gb:.2f} GB")
    print(f"Target: Total CPU 20% (Single core load: {target_core_load*100:.1f}%), Memory: {target_mem_gb:.2f} GB (30%)")

    # 1. Memory Stress
    print("-> Allocating memory...", flush=True)
    chunk_size = 125000  # Each chunk is approx 1MB
    total_chunks = int(target_mem_gb * 1024)
    
    memory_holder = []
    try:
        for _ in range(total_chunks):
            memory_holder.append([1.0] * chunk_size)
        print("-> Memory allocated. Starting CPU stress...", flush=True)
        
        # 2. CPU Stress
        cpu_worker(target_core_load, duration)
        
    except MemoryError:
        print("⚠️ Warning: MemoryError encountered. Aborting memory allocation for safety.")
    finally:
        # 3. Clean up and release memory
        del memory_holder
        print("-> Stress cycle finished. Resources released.", flush=True)

if __name__ == "__main__":
    interval = 60       # Run every 60 seconds
    stress_time = 10    # Apply load for 10 seconds per cycle
    
    print(f"Safe stress service started. Running every {interval}s with a {stress_time}s load duration.")
    print("Console will stay quiet during idle periods. Press Ctrl+C to stop.")
    
    try:
        while True:
            start_cycle = time.time()
            run_stress(duration=stress_time)
            
            # Precise sleep calculation (subtracting the 10s stress duration)
            time_spent = time.time() - start_cycle
            sleep_needed = interval - time_spent
            if sleep_needed > 0:
                time.sleep(sleep_needed)
    except KeyboardInterrupt:
        print("\nStress test stopped by user.")
