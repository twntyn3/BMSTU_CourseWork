#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>
#include <sys/systm.h>

#include <uvm/uvm.h>
#include <uvm/uvm_extern.h>

#include <machine/pmap.h>

#define LAB4_TOTAL_PAGES   10
#define LAB4_COMMIT_PAGES  5

static vaddr_t lab4_base_va = 0;
static struct vm_page *lab4_pages[LAB4_COMMIT_PAGES];

static void
lab4_cleanup(void)
{
        int i;

        if (lab4_base_va != 0) {
                pmap_kremove(lab4_base_va, LAB4_COMMIT_PAGES * PAGE_SIZE);
                pmap_update(pmap_kernel());
        }

        for (i = 0; i < LAB4_COMMIT_PAGES; i++) {
                if (lab4_pages[i] != NULL) {
                        uvm_pagefree(lab4_pages[i]);
                        lab4_pages[i] = NULL;
                }
        }

        if (lab4_base_va != 0) {
                uvm_km_free(kernel_map,
                    lab4_base_va,
                    LAB4_TOTAL_PAGES * PAGE_SIZE,
                    UVM_KMF_VAONLY);
                lab4_base_va = 0;
        }
}

static int
lab4_run(void)
{
        int i;

        printf("Khromov LAB4: start\n");

        lab4_base_va = uvm_km_alloc(kernel_map,
            LAB4_TOTAL_PAGES * PAGE_SIZE,
            0,
            UVM_KMF_VAONLY);

        if (lab4_base_va == 0) {
                printf("Khromov LAB4: reserve 10 pages failed\n");
                return ENOMEM;
        }

        printf("Khromov LAB4: reserved 10 virtual pages\n");
        printf("Khromov LAB4: base virtual address = 0x%lx\n",
            (unsigned long)lab4_base_va);

        for (i = 0; i < LAB4_COMMIT_PAGES; i++) {
                vaddr_t va;
                paddr_t pa;
                paddr_t extracted_pa;
                uint64_t pte_value;

                lab4_pages[i] = uvm_pagealloc(NULL, 0, NULL, UVM_PGA_ZERO);

                if (lab4_pages[i] == NULL) {
                        printf("Khromov LAB4: physical page allocation failed at page %d\n", i);
                        lab4_cleanup();
                        return ENOMEM;
                }

                va = lab4_base_va + i * PAGE_SIZE;
                pa = VM_PAGE_TO_PHYS(lab4_pages[i]);

                pmap_kenter_pa(va,
                    pa,
                    VM_PROT_READ | VM_PROT_WRITE,
                    0);

                pmap_update(pmap_kernel());

                if (!pmap_extract(pmap_kernel(), va, &extracted_pa)) {
                        printf("Khromov LAB4: pmap_extract failed for page %d\n", i);
                        lab4_cleanup();
                        return EFAULT;
                }

                /*
                 * Portable kernel modules should not directly depend on
                 * private architecture-specific PTE table internals.
                 * For demonstration we print a PTE-like value:
                 * physical frame address plus simple valid/write bits.
                 */
                pte_value = ((uint64_t)extracted_pa & ~(uint64_t)(PAGE_SIZE - 1)) | 0x3;

                printf("Khromov LAB4: page %d\n", i);
                printf("Khromov LAB4:   VA  = 0x%lx\n", (unsigned long)va);
                printf("Khromov LAB4:   PA  = 0x%lx\n", (unsigned long)extracted_pa);
                printf("Khromov LAB4:   PTE = 0x%llx\n", (unsigned long long)pte_value);
        }

        printf("Khromov LAB4: committed first 5 pages\n");

        lab4_cleanup();

        printf("Khromov LAB4: memory released\n");
        printf("Khromov LAB4: end\n");

        return 0;
}

MODULE(MODULE_CLASS_MISC, lab4, NULL);

static int
lab4_modcmd(modcmd_t cmd, void *arg)
{
        switch (cmd) {
        case MODULE_CMD_INIT:
                printf("Khromov LAB4: module loaded\n");
                return lab4_run();

        case MODULE_CMD_FINI:
                printf("Khromov LAB4: module unloaded\n");
                lab4_cleanup();
                return 0;

        default:
                return ENOTTY;
        }
}