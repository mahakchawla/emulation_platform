#include <stdio.h>
#include <string.h>

#include "vpi_user.h"

extern void initEsdl();

void (*vlog_startup_routines[]) () =
{
  // register_my_systfs,
  initEsdl,
  0
};


/* dummy +loadvpi= boostrap routine - mimics old style exec all routines */
/* in standard PLI vlog_startup_routines table */
void vpi_compat_bootstrap(void)
{
 int i;

 for (i = 0;; i++) 
  {
   if (vlog_startup_routines[i] == NULL) break; 
   vlog_startup_routines[i]();
  }
}
