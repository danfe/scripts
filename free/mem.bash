#!/usr/local/bin/bash

return_val=

((ameg = (1024*1024) ))

info[0]="Physical memory tunable"               # mem_phys
info[1]="User space memory available"           # mem_user (mem_phys-mem_wired)
info[2]="Maximum physical pages"                # mem_real
info[4]="Virual memory pages"                   # mem_vm_pages
info[5]="Cached: almost avail. to allocat"      # mem_cache
info[6]="Inactive: recently unreferenced"       # mem_inactive
info[7]="Active: recently referenced"           # mem_active
info[8]="Wired: disabled for paging out"        # mem_wire
info[9]="Free: fully available"                 # mem_free
info[10]="Virual memory (cached, etc.)"         # mem_vm


mem_rounded ()
{
    (( chip_size = 1 ))
    (( chip_guess = ($1 / 8) - 1))
    for (( ; chip_guess != 0 ; ))
    do
        (( chip_guess = chip_guess >> 1 ))
        (( chip_size = chip_size << 1 ))
    done

    (( return_val = (($1 / $chip_size) + 1) * $chip_size ))

    return 
}


MEM_PHYS=`sysctl -e hw.physmem`
MEM_USER=`sysctl -e hw.usermem`
MEM_REAL=`sysctl -e hw.realmem`
MEM_VM_PAGES=`sysctl -e vm.stats.vm.v_page_count`
MEM_CACHE=`sysctl -e vm.stats.vm.v_cache_count`
MEM_INACTIVE=`sysctl -e vm.stats.vm.v_inactive_count`
MEM_ACTIVE=`sysctl -e vm.stats.vm.v_active_count`
MEM_WIRE=`sysctl -e vm.stats.vm.v_wire_count`
MEM_FREE=`sysctl -e vm.stats.vm.v_free_count`
PAGE_SIZE=`sysctl -e hw.pagesize`


#   determine the individual known information
mem_phys=${MEM_PHYS#hw.physmem=}
mem_rounded $mem_phys
mem_hw=$return_val
page_size=${PAGE_SIZE#hw.pagesize=}


mem_user=$((${MEM_USER#hw.usermem=}))
mem_real=$((${MEM_REAL#hw.realmem=}))
mem_all=$((${MEM_VM_PAGES#vm.stats.vm.v_page_count=} * $page_size))
mem_cache=$((${MEM_CACHE#vm.stats.vm.v_cache_count=} * $page_size))
mem_inactive=$((${MEM_INACTIVE#vm.stats.vm.v_inactive_count=} * $page_size))
mem_active=$((${MEM_ACTIVE#vm.stats.vm.v_active_count=} * $page_size))
mem_wire=$((${MEM_WIRE#vm.stats.vm.v_wire_count=} * $page_size))
mem_free=$((${MEM_FREE#vm.stats.vm.v_free_count=} * $page_size))


#   determine logical summary information
mem_vm==$(($mem_cached + $mem_inactive + $mem_active + $mem_wired + $mem_free))

#   print system results
printf "SYSTEM MEMORY INFORMATION:\n"
printf "mem_phys:    = %12d (%7dMB)        %s\n" $mem_phys $(($mem_phys / $ameg)) "${info[0]}"
printf "mem_user:    = %12d (%7dMB)        %s\n" $mem_user $(($mem_user / $ameg)) "${info[1]}"
printf "mem_real:    = %12d (%7dMB)        %s\n" $mem_real $(($mem_real / $ameg)) "${info[2]}"
printf "mem_all:     = %12d (%7dMB) [100%%] %s\n" $mem_all $(($mem_all / $ameg)) "${info[4]}"
printf "mem_cache:   = %12d (%7dMB) [%3d%%] %s\n" $mem_cache $(($mem_cache / $ameg)) $(( ($mem_cache * 100) / $mem_all )) "${info[5]}"
printf "mem_inactive:= %12d (%7dMB) [%3d%%] %s\n" $mem_inactive $(($mem_inactive / $ameg)) $(( ($mem_inactive * 100) / $mem_all )) "${info[6]}"
printf "mem_active:  + %12d (%7dMB) [%3d%%] %s\n" $mem_active $(($mem_active / $ameg)) $(( ($mem_active * 100) / $mem_all )) "${info[7]}"
printf "mem_wire:      %12d (%7dMB) [%3d%%] %s\n" $mem_wire $(($mem_wire / $ameg)) $(( ($mem_wire * 100) / $mem_all )) "${info[8]}"
printf "mem_free:    + %12d (%7dMB) [%3d%%] %s\n" $mem_free $(($mem_free / $ameg)) $(( ($mem_free * 100) / $mem_all )) "${info[9]}"
echo "-------------- ------------ -----------"
printf "mem_hw:      = %12d (%7dMB)        %s\n" $mem_hw $(($mem_hw / $ameg)) "${info[10]}"
