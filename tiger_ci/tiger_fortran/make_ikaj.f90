! This Source Code Form is subject to the terms of the Mozilla Public
! License, v. 2.0. If a copy of the MPL was not distributed with this
! file, You can obtain one at http://mozilla.org/MPL/2.0/.
module ikaj_mod
use IOBuffer
use c_sort_finterface
contains
  subroutine make_ikaj(cho_data)
    ! A subroutine to construct the (ik|aj) integrals for the sigmavector routines

    use global_var_mod
    use molecule_var_mod
    use cholesky_structs
    use wp_tov_mod
    use sort_utils
    use io_unit_numbers
#ifdef TIGER_USE_OMP
    use omp_lib
#endif
    use c_sort_finterface

    implicit none

    integer::a,c,d ! orbital indices
    integer::i,j,k 
    integer::max_ik
    integer::i1,k1
    integer::ij_ind,ak_ind
    integer::ik_count,ik_count2,ik_count3,ak_count
    integer::icount     
    integer::idum,idum2,idum3
    integer::ij_pairs,ik_pairs
    integer::rec_count,rec_count2
    integer::block_len
    integer::block_size,max_block_size
    integer::allocatestatus,deallocatestatus
    integer,dimension(num_internal,num_internal)::ij_block
    integer,dimension(:),allocatable::i_ind,k_ind,ij_step
    integer::imax
    integer,dimension(:),allocatable::ivec,ivec2,ivec3
!    integer,dimension(:,:),allocatable::sort_scr

    real(real8),allocatable,dimension(:,:)::ik_cho
    real(real8),allocatable,dimension(:)::rvec
    real(real8),dimension(numcho)::ja_vec

    logical::transform_int  ! Decides if we need to transform integrals
    type(cholesky_data)::cho_data
    integer::threadID

#ifdef TIGER_USE_OMP
    threadID = OMP_get_thread_num()+1
#else
    threadID = 1
#endif

    ! START AUTOGENERATED INITIALIZATION 
    ak_count = 0
    idum = 0
    ak_ind = 0
    ja_vec = 0.0
    block_size = 0
    rec_count2 = 0
    k1 = 0
    i1 = 0
    imax = 0
    idum3 = 0
    idum2 = 0
    allocatestatus = 0
    rec_count = 0
    ij_ind = 0
    ik_count = 0
    ik_pairs = 0
    deallocatestatus = 0
    icount = 0
    ij_block = 0
    max_block_size = 0
    c = 0
    a = 0
    d = 0
    j = 0
    k = 0
    i = 0
    ik_count2 = 0
    ik_count3 = 0
    ij_pairs = 0
    block_len = 0
    max_ik = 0
    transform_int = .false.
    ! END AUTOGENERATED INITIALIZATION 
    !*******************************************************************************

    ij_pairs = 0  ! Number of kept (ij) pairs
    ij_block = 0  ! Number of (ik|aj) integrals in each (ij) block
    ak_count = 0 

    do i = 1,num_internal
       do j = 1,i-1

          !        if (pprr(idum) .lt. 1.0D-8) cycle
          !        idum = max(i,j)
          !        idum = idum*(idum-1)/2+min(i,j)
          !        if (mo_ind_inv(idum) .eq. 0) cycle

          if (ignorable_pair(i,j) ) cycle

          ij_pairs = ij_pairs + 1 
          ak_count = 0 

          do k = 1, num_internal
             if (ignorable_pair(i,k) ) cycle
             if (ignorable_pair(j,k) ) cycle

             !          idum2 = max(a,b)
             !          idum2 = idum2*(idum2-1)/2+min(a,b)
             !          if (mo_ind_inv(idum2) .eq. 0) cycle

             do a = num_internal+1,num_orbitals
                if (ignorable_pair(i,a) ) cycle
                if (ignorable_pair(j,a) ) cycle
                if (ignorable_pair(k,a) ) cycle

                !              idum2 = max(a,b)
                !              idum2 = idum2*(idum2-1)/2+min(a,b) 
                !              if (mo_ind_inv(idum2) .eq. 0) cycle
                ak_count = ak_count + 1

             enddo
          enddo
          ij_block(i,j) = ak_count ! # of (ik|aj) integrals in this (ij) block
       enddo
    enddo

    ! Record block size before cumulative counter

    idum3 = 0
    max_block_size = 0 
    do i = 1, num_internal
       do j = 1,i-1

          !        if (pprr(idum) .lt. 1.0D-8) cycle
          !        idum = max(i,j)
          !        idum = idum*(idum-1)/2+min(i,j)
          !        if (mo_ind_inv(idum) .eq. 0) cycle
          if (ignorable_pair(i,j) ) cycle

          idum = ij_block(i,j) 
          idum2 = i*(i-1)/2+j
          write(unit=370,rec=idum2) idum 
          if (idum .gt. max_block_size) max_block_size = idum 
          idum3 = idum3 + idum

       enddo
    enddo


    icount = 0 
    do i = 1,num_internal
       do j = 1,i-1
          if (ij_block(i,j) .eq. 0) cycle
          idum = ij_block(i,j)
          ij_block(i,j) = icount 
          icount = icount + idum 
       enddo
    enddo

    ! Count # of (ik) pairs
    ik_pairs = 0
    do i = 2,num_internal
       do k = 1,num_internal
          if (ignorable_pair(i,k)) cycle
          ik_pairs = ik_pairs + 1
       enddo
    enddo


    !******************************************************************************
    ! Set a maximum buffer size
    max_ik = int(max_mem_ints/numcho)
    max_ik = max_ik - 1

    !******************************************************************************
    inquire(iolength=idum) number_bas
    open(unit=667,file=scratch_directory // 'scr_ind2.dat',access='direct',recl=idum,form='unformatted')

    !  allocate(ik_cho(max_ik,numcho),stat=allocatestatus)
    allocate(ik_cho(numcho,max_ik),stat=allocatestatus)
    allocate(i_ind(max_ik),stat=allocatestatus)
    allocate(k_ind(max_ik),stat=allocatestatus)
    allocate(ij_step(num_internal*(num_internal+1)/2),stat=allocatestatus)
    ij_step = 0 ! To keep the offset position of each ic block on disk

    allocate(rvec(max_ik),stat=allocatestatus)
    allocate(ivec(max_ik),ivec2(max_ik),stat=allocatestatus)

    !******************************************************************************
    ! Construct the (ik|aj) integrals. Buffered version.
    ! Step 1; Read max block of (ik) buffer
    ! Step 2: Go to work construct all (ik|aj) integrals with (ik) block. 
    ! Step 3: Get new (ik) block and repeat till all (ik) blocks are exhausted
    ! Step 4: Resort (ik|aj) 

    transform_int = .false.

    ik_count = 0           
    ik_count2 = 0    
    ik_count3 = 0
    rec_count = 0
    rec_count2 = 0
    block_len = 0

    idum3 = 0

    do i = 2,num_internal
       imax = i
       do k = 1,num_internal
          if (ignorable_pair(i,k) ) cycle

          idum = max(i,k)
          idum = idum*(idum-1)/2+min(i,k)
          idum = cho_data%mo_ind_inv(idum)

          ! Read in max {ik} block   

          ik_count = ik_count + 1   ! For counting ik_index in (ik) buffer
          ik_count2 = ik_count2 + 1 ! Actual progress of ik loop

          if (idum .ne. 0) then
             call for_double_buf_readblock(mo_int_no, idum, ik_cho(1:numcho,ik_count), threadID)
          endif

          i_ind(ik_count) = i
          k_ind(ik_count) = k

          if (ik_count .eq. max_ik) then ! Buffer is now full or everything has been read into buffer
             transform_int = .true.   ! Go to transform integrals portion because buffer is full
             block_len = max_ik
          endif

          if (ik_count2 .eq. ik_pairs) then ! Everything has been read into buffer
             transform_int = .true.   ! Go to transform integrals portion because buffer is full
             block_len = ik_count 
          endif


          !*************************************************************************************** 
          if (transform_int) then ! (ik) buffer is full. Use them to construct (ik|aj) integrals

             do j = 1,imax-1 ! We will construct all the (ik|aj) integrals for the current (ik) block

                do a = num_internal+1,num_orbitals

                   if (ignorable_pair(j,a) ) cycle

                   ja_vec = 0.0D0

                   idum = a*(a-1)/2+j
                   idum = cho_data%mo_ind_inv(idum)

                   if (idum .ne. 0) then
                      call for_double_buf_readblock(mo_int_no, idum, ja_vec(1:numcho), threadID)
                   endif

                   idum2 = 0
                   ik_count3 = 0
                   rvec = 0.0D0 

                   do d = 1,block_len

                      ik_count3 = ik_count3 + 1
                      i1 = i_ind(ik_count3) 
                      k1 = k_ind(ik_count3)

                      if (j .ge. i1) cycle ! exit ?

                      if (ignorable_pair(i1,j) ) cycle
                      if (ignorable_pair(i1,a) ) cycle 
                      if (ignorable_pair(k1,j) ) cycle
                      if (ignorable_pair(k1,a) ) cycle

                      !                 idum = i1*(i1-1)/2+j
                      !                 if (pprr(idum) .lt. 1.0D-8) cycle


                      ij_ind = (i1)*(i1-1)/2+j ! cpd index
                      ak_ind = (k1-1)*num_orbitals+a

                      idum2 = idum2 + 1
                      idum3 = idum3 + 1

                      ij_step(ij_ind) = ij_step(ij_ind) + 1 ! Don't misplace this line

                      ivec(idum2) = ij_block(i1,j) + ij_step(ij_ind)

                      ivec2(idum2) = ak_ind

                      !                 rvec(idum2) = dot_product(ik_cho(ik_count3,1:numcho),ja_vec(1:numcho))
                      rvec(idum2) = dot_product(ik_cho(1:numcho,ik_count3),ja_vec(1:numcho))

                   enddo

                   do c = 1,idum2
                      rec_count = ivec(c)
                      call for_double_buf_writeElement(cd_ikaj_no,rec_count,rvec(c),threadID)
                   enddo


                   do c = 1,idum2               ! record cpd indexes
                      rec_count = ivec(c)
                      write(unit=667,rec=rec_count) ivec2(c)
                   enddo

                enddo
             enddo

             transform_int = .false.  ! Reset to false when (ik) buffer is exhausted
             i_ind = 0 
             k_ind = 0
             ik_cho = 0.0D0
             ik_count = 0

          endif ! transform_int
          !********************************************************************************************

       enddo ! a
    enddo ! i

    deallocate(ik_cho,stat=deallocatestatus)
    deallocate(i_ind,stat=deallocatestatus)
    deallocate(k_ind,stat=deallocatestatus)
    deallocate(ij_step,stat=deallocatestatus)
    deallocate(rvec,stat=deallocatestatus)
    deallocate(ivec,ivec2,stat=deallocatestatus)

    ! Now we want to resort the (ik|aj) integrals

    allocate(rvec(max_block_size),stat=allocatestatus)
    ! AUTOGENERATED INITALIZATION
    rvec = 0.0
    ! END AUTOGENERATED INITIALIZATION 
    allocate(ivec(max_block_size),ivec2(max_block_size),ivec3(max_block_size),stat=allocatestatus)
    ! AUTOGENERATED INITALIZATION
    ivec = 0
    ivec2 = 0
    ivec3 = 0
    ! END AUTOGENERATED INITIALIZATION 
!    allocate(sort_scr(2,max_block_size),stat=allocatestatus)
    ! AUTOGENERATED INITALIZATION
!    sort_scr = 0
    ! END AUTOGENERATED INITIALIZATION 

    ivec3 = 0
    do i = 1,max_block_size
       ivec3(i) = i
    enddo

    icount = 0
    do i = 1,num_internal
       do j = 1,i-1
          if (ignorable_pair(i,j) ) cycle
          idum2 = i*(i-1)/2+j
          read(unit=370,rec=idum2) block_size
          do c = 1,block_size
             call for_double_buf_readElement(cd_ikaj_no,icount+c,rvec(c),threadID)
          enddo
          do c = 1,block_size
             read(unit=667,rec=icount+c) ivec(c)
          enddo

          ivec2(1:block_size) = ivec3(1:block_size)

          !call Iquicksrt(ivec(1:block_size),ivec2(1:block_size),block_size,sort_scr(1:2,1:block_size))
          call sort_int_array_with_index(ivec(1:block_size),ivec2(1:block_size))

          do c = 1,block_size ! Write sorted (ik|aj) block
             idum = ivec2(c)
             call for_double_buf_writeElement(cd_ikaj_no,icount+c,rvec(idum),threadID)
          enddo

          icount = icount + block_size

       enddo
    enddo

    close(unit=667,status='delete')

    ! Record cumulative block size
    do i = 1,num_internal
       do j = 1,i-1
          if (ignorable_pair(i,j) ) cycle
          idum = i*(i-1)/2+j
          write(unit=370,rec=idum) ij_block(i,j)
       enddo
    enddo


    deallocate(rvec,stat=deallocatestatus)
    deallocate(ivec,ivec2,ivec3,stat=deallocatestatus)
!    deallocate(sort_scr,stat=deallocatestatus)

  end subroutine make_ikaj
end module ikaj_mod
