#!/bin/sh

expr='expr -e'

mem_phys=`sysctl -n hw.physmem`
mem_pgs=`sysctl -n hw.pagesize`
sys_jail=`sysctl -n security.jail.jailed`

# guess hardware memory size
chip_size=1
chip_guess=`$expr $mem_phys / 8 - 1`
while [ $chip_guess -ne 0 ]; do
	chip_guess=`$expr $chip_guess / 2`
	chip_size=`$expr $chip_size \* 2`
done
mem_hw=`$expr \( $mem_phys - 1 \) / $chip_size`
mem_hw=`$expr $mem_hw \* $chip_size + $chip_size`

# determine the individual known information
mem_all=`sysctl -n vm.stats.vm.v_page_count`
mem_all=`$expr $mem_all \* $mem_pgs`
mem_wire=`sysctl -n vm.stats.vm.v_wire_count`
mem_wire=`$expr $mem_wire \* $mem_pgs`
mem_active=`sysctl -n vm.stats.vm.v_active_count`
mem_active=`$expr $mem_active \* $mem_pgs`
mem_inactive=`sysctl -n vm.stats.vm.v_inactive_count`
mem_inactive=`$expr $mem_inactive \* $mem_pgs`
mem_cache=`sysctl -n vm.stats.vm.v_cache_count`
mem_cache=`$expr $mem_cache \* $mem_pgs`
mem_free=`sysctl -n vm.stats.vm.v_free_count`
mem_free=`$expr $mem_free \* $mem_pgs`

# determine the individual unknown information
mem_gap_vm=`$expr $mem_all - \( $mem_wire + $mem_active + $mem_inactive + $mem_cache + $mem_free \)`
mem_gap_sys=`$expr $mem_phys - $mem_all`
mem_gap_hw=`$expr $mem_hw - $mem_phys`

# determine logical summary information
mem_total=$mem_hw
mem_avail=`$expr $mem_inactive + $mem_cache + $mem_free`
mem_used=`$expr $mem_total - $mem_avail`

# print system results
printf "System memory information (page size is %d bytes)\n" $mem_pgs
if [ $sys_jail -eq 1 ]; then
	printf "WE ARE IN THE JAIL\n"
	printf "mem_wire:      %12d (%7dMB) %s\n" $mem_wire `$expr $mem_wire / 1048576` 'Wired: disabled for paging out'
	printf "mem_active:    %12d (%7dMB) %s\n" $mem_active `$expr $mem_active / 1048576` 'Active: recently referenced'
	printf "mem_inactive:  %12d (%7dMB) %s\n" $mem_inactive `$expr $mem_inactive / 1048576` 'Inactive: recently not referenced'
	printf "mem_cache:     %12d (%7dMB) %s\n" $mem_cache `$expr $mem_cache / 1048576` 'Cached: almost avail. for allocation'
	printf "mem_free:      %12d (%7dMB) %s\n" $mem_free `$expr $mem_free / 1048576` 'Free: fully available for allocation'
	printf -- "-------------- ------------ -----------\n"
	printf "mem_phys:      %12d (%7dMB) %s\n" $mem_phys `$expr $mem_phys  / 1048576` 'Total real memory available'
else
	printf "mem_wire:      %12d (%7dMB) [%3d%%] %s\n" $mem_wire `$expr $mem_wire / 1048576` `$expr $mem_wire \* 100 / $mem_all` 'Wired: disabled for paging out'
	printf "mem_active:  + %12d (%7dMB) [%3d%%] %s\n" $mem_active `$expr $mem_active / 1048576` `$expr $mem_active \* 100 / $mem_all` 'Active: recently referenced'
	printf "mem_inactive:+ %12d (%7dMB) [%3d%%] %s\n" $mem_inactive `$expr $mem_inactive / 1048576` `$expr $mem_inactive \* 100 / $mem_all` 'Inactive: recently not referenced'
	printf "mem_cache:   + %12d (%7dMB) [%3d%%] %s\n" $mem_cache `$expr $mem_cache / 1048576` `$expr $mem_cache \* 100 / $mem_all` 'Cached: almost avail. for allocation'
	printf "mem_free:    + %12d (%7dMB) [%3d%%] %s\n" $mem_free `$expr $mem_free / 1048576` `$expr $mem_free \* 100 / $mem_all` 'Free: fully available for allocation'
	printf "mem_gap_vm:  + %12d (%7dMB) [%3d%%] %s\n" $mem_gap_vm `$expr $mem_gap_vm / 1048576` `$expr $mem_gap_vm  \* 100 / $mem_all` 'Memory gap: UNKNOWN'
	printf -- "-------------- ------------ ----------- ------\n"
	printf "mem_all:     = %12d (%7dMB) [100%%] %s\n" $mem_all `$expr $mem_all / 1048576` 'Total real memory managed'
	printf "mem_gap_sys: + %12d (%7dMB)        %s\n" $mem_gap_sys `$expr $mem_gap_sys / 1048576` 'Memory gap: Kernel?!'
	printf -- "-------------- ------------ -----------\n"
	printf "mem_phys:    = %12d (%7dMB)        %s\n" $mem_phys `$expr $mem_phys / 1048576` 'Total real memory available'
	printf "mem_gap_hw:  + %12d (%7dMB)        %s\n" $mem_gap_hw `$expr $mem_gap_hw / 1048576` 'Memory gap: Segment Mappings?!'
	printf -- "-------------- ------------ -----------\n"
	printf "mem_hw:      = %12d (%7dMB)        %s\n" $mem_hw `$expr $mem_hw / 1048576` 'Total real memory installed'
fi

# print logical results
if [ $sys_jail -ne 1 ]; then
	printf "\nSystem memory summary\n"
	printf "mem_used:      %12d (%7dMB) [%3d%%] %s\n" $mem_used `$expr $mem_used / 1048576` `$expr $mem_used \* 100 / $mem_total` 'Logically used memory'
	printf "mem_avail:   + %12d (%7dMB) [%3d%%] %s\n" $mem_avail `$expr $mem_avail / 1048576` `$expr $mem_avail \* 100 / $mem_total` 'Logically available memory'
	printf -- "-------------- ------------ ----------- ------\n"
	printf "mem_total:   = %12d (%7dMB) [100%%] %s\n" $mem_total `$expr $mem_total / 1048576` 'Logically total memory'
fi
