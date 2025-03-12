# show_slab_creation

This repository provides a simple Linux kernel module that demonstrates creating a local slab for memory allocation. The module (built as `show_slab_creation.ko`) creates a custom slab ("my_slab"), allocates memory from it, and then frees it.

## Prerequisites

- Linux kernel headers for your current kernel version
- Build tools (e.g., `build-essential`)

Install dependencies (Debian/Ubuntu):

```bash
sudo apt-get install build-essential linux-headers-$(uname -r)
```

## Building the Module

Compile the module by running:

```bash
make
```

## Usage

1. **Insert the Module:**

   ```bash
   sudo insmod show_slab_creation.ko
   ```

2. **Verify Kernel Log:**

   Check the kernel log to see the allocation details:

   ```bash
   dmesg | tail
   ```

3. **Remove the Module:**

   ```bash
   sudo rmmod show_slab_creation
   ```

## Clean Up

Remove build artifacts with:

```bash
make clean
```

## License

Dual-licensed under MIT and GPL.
