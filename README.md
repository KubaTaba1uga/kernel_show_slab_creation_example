# show_slab_allocator

This repository contains a simple Linux kernel module that demonstrates memory allocation and deallocation using the slab allocator. 

## Usage

1. **Install Dependencies:**

   ```bash
   sudo apt-get install build-essential linux-headers-$(uname -r)
   ```

2. **Build the Module:**

   ```bash
   make
   ```

3. **Insert the Module:**

   ```bash
   sudo insmod show_slab_allocator.ko
   ```

4. **Verify Kernel Output:**

   Check the kernel log to see the allocation details:

   ```bash
   dmesg | tail
   ```

5. **Remove the Module:**

   ```bash
   sudo rmmod show_slab_allocator
   ```

## Clean Up

To remove build artifacts, run:

```bash
make clean
```

## License

Dual MIT/GPL

