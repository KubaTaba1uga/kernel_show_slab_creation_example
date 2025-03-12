/*
 * show_slab_allocator
 ****************************************************************
 * Brief Description:
 * A kernel module that demonstrates slab memory allocation for an array
 * of five pointers. In the module's initialization code, each pointer in the
 * array is allocated 1 KB of memory using kmalloc().
 *
 * Memory Layout Diagram:
 *
 *  +-------+-------+-------+-------+-------+
 *  | 0  .  | 1  .  | 2  .  | 3  .  | 4  .  |
 *  +---|---+---|---+---|---+---|---+---|---+
 *      v       v       v       v       v
 *    +---+   +---+   +---+   +---+   +---+
 *    |mem|   |mem|   |mem|   |mem|   |mem|   <-- 1 KB each
 *
 * In the module cleanup code, all allocated memory is freed. The module takes
 * care to handle error cases by checking each kmalloc() call and ensuring that
 * any memory successfully allocated is freed if an error occurs.
 */
#include <linux/gfp_types.h>
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/gfp.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/printk.h>

MODULE_AUTHOR("KubaTaba1uga");
MODULE_DESCRIPTION("a simple LKM showing SLAB usage");
MODULE_LICENSE("Dual MIT/GPL");
MODULE_VERSION("0.1");

static ssize_t slab_array_len;
static char **slab_array_ptr;

static int __init show_slab_allocator_init(void)
{
	ssize_t buf_size = 1024;
	int err;

	pr_info("Inserted\n");

	slab_array_len = 5;
	slab_array_ptr = kzalloc(sizeof(int *) * slab_array_len, GFP_KERNEL);
	if (!slab_array_ptr) {
		pr_err("Unable to allocate memory for `slab_array_ptr`\n");
		err = -ENOMEM;
		goto cleanup;
	}

	for (ssize_t i = 0; i < slab_array_len; i++) {
		slab_array_ptr[i] = kmalloc(buf_size, GFP_KERNEL);
		if (!slab_array_ptr[i]) {
			pr_err("Unable to allocate memory for `slab_array_ptr[%zd]`\n", i);
			err = -ENOMEM;
			goto cleanup_slab_array_ptr;
		}
	}

	memcpy(slab_array_ptr[0], "as", 3);
	memcpy(slab_array_ptr[1], "bs", 3);
	memcpy(slab_array_ptr[2], "cs", 3);
	memcpy(slab_array_ptr[3], "ds", 3);
	memcpy(slab_array_ptr[4], "es", 3);

	for (ssize_t i = 0; i < slab_array_len; i++) {
		char *buf = slab_array_ptr[i];

		pr_info("%zd:%s\n", i, buf);
	}

	return 0;

 cleanup_slab_array_ptr:
	for (ssize_t i = 0; i < slab_array_len; i++) {
		if (!slab_array_ptr[i])
			continue;
		kfree(slab_array_ptr[i]);
	}

	kfree(slab_array_ptr);

 cleanup:
	return err;
}

static void __exit show_slab_allocator_exit(void)
{
	for (ssize_t i = 0; i < slab_array_len; i++) {
		kfree(slab_array_ptr[i]);
	}

	kfree(slab_array_ptr);

	pr_info("Removed\n");
}

module_init(show_slab_allocator_init);
module_exit(show_slab_allocator_exit);
