#include <sys/param.h>
#include <sys/module.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/proc.h>
#include <sys/mutex.h>

static void
lab3_print_processes(void)
{
        struct proc *p;

        printf("Khromov LAB3: process list begin\n");

        mutex_enter(&proc_lock);

        LIST_FOREACH(p, &allproc, p_list) {
                printf("Khromov LAB3: pid=%d comm=%s\n",
                    p->p_pid,
                    p->p_comm);
        }

        mutex_exit(&proc_lock);

        printf("Khromov LAB3: process list end\n");
}

MODULE(MODULE_CLASS_MISC, lab3, NULL);

static int
lab3_modcmd(modcmd_t cmd, void *arg)
{
        switch (cmd) {
        case MODULE_CMD_INIT:
                printf("Khromov LAB3: module loaded\n");
                lab3_print_processes();
                return 0;

        case MODULE_CMD_FINI:
                printf("Khromov LAB3: module unloaded\n");
                return 0;

        default:
                return ENOTTY;
        }
}