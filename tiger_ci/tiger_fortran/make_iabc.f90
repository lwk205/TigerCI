! This Source Code Form is subject to the terms of the Mozilla Public
! License, v. 2.0. If a copy of the MPL was not distributed with this
! file, You can obtain one at http://mozilla.org/MPL/2.0/.
module iabc_mod
 use fortran_timing
 use global_var_mod
 use molecule_var_mod
 use cholesky_structs
 use wp_tov_mod
 use io_unit_numbers
 use IOBuffer
#ifdef TIGER_USE_OMP
 use three_four_seg_var_mod
 use omp_lib
#endif
 implicit none
    
    contains
subroutine make_iabc(cho_data)
! A subroutine to construct the (ia|bc) integrals for the sigmavector routines
 implicit none

 integer::a,b,c  ! orbital indices
 integer::i
 integer::max_ia    
 integer::ia_count,ia_count2,ia_count3,ab_count
 integer::icount      
 integer::idum,idum2,idum3,idum4,idum5,idum6,idum7
 integer::idummy,idummy2,idummy3     
 integer::ivar,ivar2,ivar3,ivar4,ivar5
 integer::ab_filter,b_filter,i_label
 integer::ic_pairs
 integer::rec_count,rec_count2
 integer::block_len
 integer::num_c_s,max_a_dom,max_i_dom,active_i_counter
 integer::num_i_blocks,num_i_active,orphaned_i_s
 integer::allocatestatus,deallocatestatus      
 integer,dimension(num_internal):: i_list,i_dom_size
 integer,dimension(num_external):: a_list
 integer,dimension(num_internal,num_external)::ic_block
 integer,dimension(num_external)::c_list,c_list2
 integer,dimension(:),allocatable::i_ind,a_ind       

 real(real8)::zero,one     
 real(real8),allocatable,dimension(:,:)::ia_cho
 real(real8),allocatable,dimension(:,:,:)::bc_cho_ten,small_ia_cho_ten,small_bc_cho_ten,iabc_block_ten
 integer::numthreads,ten_pointer
#ifdef TIGER_FINE_TIMES
 type(clock) :: timer
#endif
 
 logical::transform_int  ! Decides if we need to transform integrals
 type(cholesky_data)::cho_data

#ifdef TIGER_USE_OMP
 numthreads = numberOfThreads
#else
 numthreads = 1
#endif
 ! START AUTOGENERATED INITIALIZATION 
i_dom_size = 0
num_c_s = 0
icount = 0
idummy = 0
idum3 = 0
idum2 = 0
idum7 = 0
idum6 = 0
idum5 = 0
idum4 = 0
ivar = 0
max_a_dom = 0
c_list = 0
num_i_active = 0
max_i_dom = 0
i_list = 0
ab_filter = 0
block_len = 0
ivar4 = 0
ivar5 = 0
idummy3 = 0
idummy2 = 0
ivar2 = 0
ivar3 = 0
i_label = 0
a = 0
b = 0
b_filter = 0
a_list = 0
idum = 0
c_list2 = 0
! END AUTOGENERATED INITIALIZATION 
!*******************************************************************************

  ic_pairs = 0  ! Number of kept (ic) pairs
  ic_block = 0  ! Number of (ia|bc) integrals in each (ic) block
  ab_count = 0
  
  ! setup the buffered iabc file
  call for_double_buf_openfile(for_buf_int_poolID,cd_iabc_no,&
     scratch_directory // 'cd_iabc.dat',len(scratch_directory) + 11)

#if defined TIGER_USE_OMP
  if(.not.allocated(omp_offsets_iabc_icount)) then
    allocate(omp_offsets_iabc_icount(num_internal), stat=allocatestatus)
    call allocatecheck(allocatestatus,"omp_offsets_iabc_icount")
  endif
#endif
  
  idum7= 0

  do i = 1,num_internal
  
#if defined TIGER_USE_OMP
     omp_offsets_iabc_icount(i) = idum7
#endif
     do c = num_internal+1,num_orbitals

        if (ignorable_pair(i,c) ) cycle

        ic_pairs = ic_pairs + 1 
        ab_count = 0 

        do a = num_internal+1,num_orbitals
           if (ignorable_pair(i,a) ) cycle
           if (ignorable_pair(c,a) ) cycle

           do b = num_internal+1,num_orbitals
          
              if (ignorable_pair(b,c) ) cycle
              if (ignorable_pair(b,a) ) cycle
              if (ignorable_pair(i,b) ) cycle

              ab_count = ab_count + 1
              idum7 = idum7 + 1

           enddo
        enddo
        ic_block(i,c-num_internal) = ab_count ! # of (ia|cb) integrals in this (ic) block
     enddo
  enddo

! Record blck size before cumulative counter

  !rewind(unit=342) 
  !max_block_size = 0 
  !do i = 1, num_internal
  !   do c = num_internal+1,num_orbitals
  !      if (ignorable_pair(i,c) .eq. 0) cycle
  !      idum = ic_block(i,c-num_internal) 
  !      write(unit=342) idum 
  !      if (idum .gt. max_block_size) max_block_size = idum 
  !
  !   enddo
  !enddo

  icount = 0 
  do i = 1,num_internal
     do c = 1,num_external 
        if (ic_block(i,c) .eq. 0) cycle
        idum = ic_block(i,c)
        ic_block(i,c) = icount 
        icount = icount + idum 
     enddo
  enddo


!*******************************************
! Find the maximum size of domain amongst all {i}s

  i_dom_size = 0
  max_i_dom = 0

  do i = 1,num_internal
     idum = 0
     do a = num_internal+1,num_orbitals
        if (.not. ignorable_pair(a,i) ) then
           idum = idum + 1
!           i_dom_list(idum,i) = a
        endif
     enddo

     i_dom_size(i) = idum
     if (max_i_dom .lt. idum) max_i_dom = idum

     if (idum == 0) then
     write(6,*) "Domain size for orbital",i,"is zero.Check it out!"
     call flush(6)
     stop
     endif

  enddo

! Find the maximum size of domain amongst all {a}s

  max_a_dom = 0
  do a = num_internal+1,num_orbitals
     idum = 0 
     do b = num_internal+1,num_orbitals 
        if (ignorable_pair(a,b) ) cycle
        idum = idum + 1
     enddo
     if (max_a_dom .lt. idum) max_a_dom = idum
  enddo


!******************************************

!******************************************************************************
  max_ia = int(max_mem_ints/numcho)
  max_ia = max_ia - 1

! Test if memory assigned is big enough

  if (2*max_a_dom .gt. max_ia) then
  write(6,*) "There is not eneough memory for assembling the (ia|bc) integrals"
  call flush(6)
  stop
  endif


!******************************************************************************

  allocate(ia_cho(numcho,max_ia),stat=allocatestatus)
  allocate(bc_cho_ten(numcho,max_a_dom,numthreads),stat=allocatestatus)
  allocate(small_bc_cho_ten(numcho,max_a_dom,numthreads),stat=allocatestatus)
  allocate(small_ia_cho_ten(numcho,max_i_dom,numthreads),stat=allocatestatus)
  allocate(iabc_block_ten(max_i_dom,max_i_dom,numthreads),stat=allocatestatus)



  allocate(i_ind(max_ia),stat=allocatestatus)
  allocate(a_ind(max_ia),stat=allocatestatus)


!******************************************************************************
! Construct the (ia|cb) integrals. Buffered version.
! Step 1; Read max block of (ia) buffer
! Step 2: Go to work construct all (ia|cb) integrals with (ia) block. 
! Step 3: Get new (ia) block and repeat till all (ia) blocks are exhausted

  transform_int = .false.

  ia_count = 0           
  ia_count2 = 0    
  ia_count3 = 0
  rec_count = 0
  rec_count2 = 0
  block_len = 0

  zero = 0.0D0
  one = 1.0D0
 
  idum6 = 0
  ivar5 = 0
  
  do i = 1,num_internal
     do a = num_internal+1,num_orbitals

        if (ignorable_pair(a,i) ) cycle

        idum = a*(a-1)/2+i
        idum = cho_data%mo_ind_inv(idum)

! Read in max {ia} block   

        ia_count = ia_count + 1   ! For counting ia_index in (ia) buffer
        ia_count2 = ia_count2 + 1 ! Actual progress of ia loop

        if (idum .ne. 0) then
        call for_double_buf_readblock(mo_int_no, idum, ia_cho(1:numcho,ia_count), 1)
        !read(unit=mo_int_no,rec=idum) ia_cho(1:numcho,ia_count)
        endif

        i_ind(ia_count) = i
        a_ind(ia_count) = a

        if (ia_count .eq. max_ia) then ! Buffer is now full or everything has been read into buffer
        transform_int = .true.   ! Go to transform integrals portion because buffer is full

!       Check number of different i blocks. Be careful of the exception where i has 0 size block.. Anomaly.
        i_list = 0
        num_i_blocks = 1
        idum = i_ind(1) 
        i_list(1)  = idum   ! Keeps a list of i_s
        do idum2 = 1,ia_count
           if (idum /= i_ind(idum2)) then
               num_i_blocks = num_i_blocks + 1
               idum = i_ind(idum2)
               i_list(num_i_blocks) =  idum   
           endif
        enddo

        num_i_active = num_i_blocks ! Update the number of useful i_s 

! Consider the case when one cannot fill the entire i{a}
! Do boundary testing
        idum = i_ind(ia_count)
        idum2 = a_ind(ia_count)
        idum4 = 0
        do idum3 = idum2+1,num_orbitals
           if (ignorable_pair(idum,idum3) ) cycle
           idum4 = idum4 + 1
        enddo

        orphaned_i_s = 0
        if (idum4 .ge. 1) then    ! There are orphaned i{a}. Find how many of those
           idum2 = i_list(num_i_blocks) ! get the index of the orphaned i ! Compare against i_ind(ia_count)
           idum3 = 0
           do idum = 1, ia_count
              if (idum2 /= i_ind(idum)) cycle
              idum3 = idum3 + 1
           enddo
        orphaned_i_s = idum3      ! This is the number of orphaned i_s
        num_i_active = num_i_blocks - 1 ! Update the actual number of useful i_blocks

        endif 

        endif ! endif ia_count = max_ia


        if (ia_count2 .eq. ic_pairs) then ! Everything has been read into buffer
        transform_int = .true.   ! Go to transform integrals portion because buffer is full
        write(6,*) "Everything in Buffer"

!       Check number of different i blocks. Be careful of the exception where i has 0 size block.. Anomaly.
        i_list = 0
        num_i_blocks = 1
        idum = i_ind(1)
        i_list(1) = idum ! Keeps a list of i_s
        do idum2 = 1,ia_count
           if (idum /= i_ind(idum2)) then
               num_i_blocks = num_i_blocks + 1
               idum = i_ind(idum2)
               i_list(num_i_blocks) = idum  
           endif
        enddo
        num_i_active = num_i_blocks ! Update the number of useful i_s

! Consider the case when one cannot fill the entire i{a}
! For this case all the i_s must be filled. Can't have any orphaned i_s
        orphaned_i_s = 0
        idum = i_ind(ia_count)
        idum2 = a_ind(ia_count)
        idum4 = 0
        do idum3 = idum2+1,num_orbitals
           if (ignorable_pair(idum,idum3) ) cycle
           idum4 = idum4 + 1
        enddo

        if (idum4 .ge. 1) then
           write(6,*) "Something seriously wrong!"
           write(6,*) "You have orphaned i_s in (ia|bc)"
           call flush(6)
           stop
        endif

        endif  ! endif ia_count2 = ic_pairs


!*************************************************************************************** 
        if (transform_int) then ! (ia) buffer is full. Use them to construct (ia|bc) integrals

! Read entire b{c} block which is relevant to at least one of the i_s in the i{a} block
#ifdef TIGER_FINE_TIMES
           call start_clock(timer)
#endif
                      
           !$omp parallel &
           !$omp default(none) &
           !$omp private(b_filter,idum2,c_list,num_c_s,idum,active_i_counter,i_label,icount,ab_filter, &
           !$omp a_list,idummy2,idummy3,idum3,c_list2,idum4,idum5,idummy,ivar2,ivar5,ivar4,ten_pointer) &
           !$omp shared(num_internal,num_orbitals,ignorable_pair,cho_data,numcho,ia_cho,num_i_active,i_list,i_dom_size, &
           !$omp a_ind,zero,one,ic_block,small_ia_cho_ten,iabc_block_ten,small_bc_cho_ten,bc_cho_ten,max_a_dom,max_i_dom)
           
           !$omp do schedule(static)
           do b = num_internal+1,num_orbitals
           
#ifdef TIGER_USE_OMP
              ten_pointer = OMP_get_thread_num()+1
#else
              ten_pointer = 1
#endif
           
              b_filter = 0
              do idum = 1,num_i_active   ! Still have to check at a later stage if a particular i is useful for this b
                 idum2 = i_list(idum)
                if (.not. ignorable_pair(idum2,b)) b_filter = 1
              enddo
                            
              if (b_filter == 0)  cycle ! This entire b block is useless

! Now read in the b{c} block
              bc_cho_ten(1:numcho,1:max_a_dom,ten_pointer)= 0.0D0    ! Size of bc_cho not right
              c_list = 0
              num_c_s = 0

              do c = num_internal+1,num_orbitals
 
                 if (ignorable_pair(c,b) ) cycle

                 idum = max(b,c)
                 idum = idum*(idum-1)/2+min(b,c)
                 idum = cho_data%mo_ind_inv(idum)

                 num_c_s = num_c_s + 1
                 c_list(num_c_s) = c   ! Keeps a list of c_s in the b{c} block

                 if (idum .ne. 0) then
                    call for_double_buf_readblock(mo_int_no, idum, bc_cho_ten(1:numcho,num_c_s,ten_pointer), ten_pointer)
                 endif

              enddo  ! enddo c   

               
              active_i_counter = 1
              do idum = 1,num_i_active  ! Go through all the complete i blocks

                 i_label  = i_list(idum)   ! i_label stores the current i value
                 icount =  i_dom_size(i_label)

                 if (.not. ignorable_pair(i_label,b) ) then ! Otherwise the current b is not useful for this i_block

                 ab_filter = 0                    ! Check for WP between b and a
                 a_list = 0
                 do idummy2 = 1,icount
                    idummy3 = a_ind(active_i_counter+idummy2-1)
                    if (ignorable_pair(idummy3,b)) cycle 
                    ab_filter = ab_filter + 1
                    a_list(ab_filter) = idummy3
                    small_ia_cho_ten(1:numcho,ab_filter,ten_pointer) = ia_cho(1:numcho,active_i_counter+idummy2-1)
                 enddo
 

                 if (ab_filter .gt. 0) then 
! Here you want to sift through the i{a} and b{c} block for useful pieces.
! Get only the c_s in b{c} which you can find in i{a}
                 idum3 = 0
                 !small_bc_cho= 0.0D0 jmd: not really needed as we put bc_cho in there next
                 c_list2 = 0
                 do idum4 = 1,num_c_s
                    idum5 = c_list(idum4) ! Get the c value
                    if (ignorable_pair(idum5,i_label) ) cycle  ! WP between i and c
                    idummy = 0            ! Check for wp between a and c
                    do idummy2 = 1,ab_filter
                       idummy3 = a_list(idummy2)
                       if (.not. ignorable_pair(idummy3,idum5)) idummy = 1 
                    enddo
                    if (idummy == 1) idum3 = idum3 + 1     ! Count the useful c_s
                    c_list2(idum3) = idum5
                    small_bc_cho_ten(1:numcho,idum3,ten_pointer) = bc_cho_ten(1:numcho,idum4,ten_pointer)
                 enddo                      

! Now you have the relevant small b{c} block. Construct the (ia|bc) integrals
                 call dgemm('T','N',ab_filter,idum3,numcho,one,small_ia_cho_ten(:,:,ten_pointer),numcho,&
                            small_bc_cho_ten(:,:,ten_pointer),numcho,&
                            zero,iabc_block_ten(:,:,ten_pointer),max_i_dom)
                            
! Write to file 
                 ivar5 = ic_block(i_label,b-num_internal)
                 do ivar = 1,idum3
                    ivar2 =  c_list2(ivar)
                    do ivar3 = 1,ab_filter
                       ivar4 = a_list(ivar3)
                       if (ignorable_pair(ivar4,ivar2)  ) cycle
                        ivar5 = ivar5 + 1
!                        idum6 = idum6 + 1
                         call for_double_buf_writeElement(cd_iabc_no,ivar5,iabc_block_ten(ivar3,ivar,ten_pointer),ten_pointer)
                    enddo
                 enddo

                 endif ! if wp(b,a)
                
                 endif  ! if wp (i,b)

                 active_i_counter = active_i_counter + icount
           

              enddo ! enddo num_i_active

          enddo ! enddo b
          !$omp end do nowait
          !$omp end parallel
          
#ifdef TIGER_FINE_TIMES
          write(*,*) "Walltime for relevant make_iabc loop:", get_clock_wall_time(timer)
#endif

! There might be some orphan  i{a} who are not used because buffer does not contain the entire block
! Shift these blocks to the top of the buffer and adjust for ia_count

          if (orphaned_i_s /= 0) then

          write(6,*) "There are leftovers"
          idum2 = ia_count-orphaned_i_s
          do idum = 1,orphaned_i_s
             idum2 = idum2 + 1
             ia_cho(1:numcho,idum) = ia_cho(1:numcho,idum2)
             i_ind(idum) = i_ind(idum2)
             a_ind(idum) = a_ind(idum2)
          enddo
          ia_count = orphaned_i_s  ! Adjust for ia_count as the buffer is not empty
          else
          ia_count = 0 !jmd: reset the ia_count counter
          endif

          transform_int = .false.

        endif ! transform_int
!********************************************************************************************

     enddo ! a
  enddo ! i
 
  deallocate(ia_cho,stat=deallocatestatus)
  deallocate(bc_cho_ten,stat=deallocatestatus)
  deallocate(small_bc_cho_ten,stat=deallocatestatus)
  deallocate(small_ia_cho_ten,stat=deallocatestatus)
  deallocate(iabc_block_ten,stat=deallocatestatus)



  deallocate(i_ind,stat=deallocatestatus)
  deallocate(a_ind,stat=deallocatestatus)

 end subroutine make_iabc
 
 function makeOneIABC(i,a,b,c,cho_data)
   
   use global_var_mod
   use cholesky_structs
   use io_unit_numbers
   use molecule_var_mod
   
   implicit none
   
   integer,intent(in)::i,a,b,c
   type(cholesky_data),intent(in)::cho_data
   real(real8)::makeOneIABC
   
   integer::cho_point1,cho_point2
   real(real8),parameter::zero=real(0.0,real8)
   real(real8),external::ddot
  
   ! a always bigger than i
   cho_point1 = a*(a-1)/2+i
   cho_point1 = cho_data%mo_ind_inv(cho_point1)
  
   cho_point2 = max(b,c)
   cho_point2 = cho_point2*(cho_point2-1)/2+min(b,c)
   cho_point2 = cho_data%mo_ind_inv(cho_point2)
  
   ! we have them in memory
   ! check an adapted CS criterion
   if(cho_data%cho_norms(cho_point1)*cho_data%cho_norms(cho_point2) >= integral_threshold) then
      makeOneIABC = ddot(numcho,cho_data%cho_vectors(:,cho_point1),1,cho_data%cho_vectors(:,cho_point2),1)
!      makeOneIABC = dot_product(cho_data%cho_vectors(:,cho_point1),cho_data%cho_vectors(:,cho_point2))
   else
      makeOneIABC = zero
   endif
 
 end function makeOneIABC

end module 
