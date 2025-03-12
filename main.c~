/*
 * show_slab_creation
 ****************************************************************
 * Brief Description:
 * A kernel module that how create local slab of fixed size.
 */
#include "linux/gfp_types.h"
#include <linux/gfp.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/printk.h>
#include <linux/slab.h>

MODULE_AUTHOR("KubaTaba1uga");
MODULE_DESCRIPTION("a simple LKM showing local SLAB creation");
MODULE_LICENSE("Dual MIT/GPL");
MODULE_VERSION("0.1");

static ssize_t slab_size;
static struct kmem_cache *slab_ptr;

static int __init show_slab_creation_init(void) {
  char *buf;
  int err;

  pr_info("Inserted\n");

  // Create local SLAB
  slab_size = 1024 * 1024;
  slab_ptr = kmem_cache_create("my_slab", slab_size, 0, SLAB_PANIC, NULL);
  if (!slab_ptr) {
    err = -ENOMEM;
    goto cleanup;
  }

  // Allocate some memory from local SLAB
  buf = kmem_cache_alloc(slab_ptr, GFP_KERNEL);
  if (!buf) {
    err = -ENOMEM;
    goto cleanup_slab_ptr;
  }

  memcpy(buf, "wck", 4);
  pr_info("buf=%s\n", buf);

  kmem_cache_free(slab_ptr, buf);

  return 0;

cleanup_slab_ptr:
  kmem_cache_destroy(slab_ptr);

cleanup:
  return err;
}

static void __exit show_slab_creation_exit(void) {
  kmem_cache_destroy(slab_ptr);
  pr_info("Removed\n");
}

module_init(show_slab_creation_init);
module_exit(show_slab_creation_exit);
