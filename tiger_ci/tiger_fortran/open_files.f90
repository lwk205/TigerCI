! Copyright (c) 1998-2004, University of California, Los Angeles, Emily A. Carter
!                       2004-2016, Princeton University, Emily A. Carter
! All rights reserved.
!
! Redistribution and use in source and binary forms, with or without modification, are
! permitted provided that the following conditions are met:
!
! 1. Redistributions of source code must retain the above copyright notice, this list of
!     conditions and the following disclaimer.
!
! 2. Redistributions in binary form must reproduce the above copyright notice, this list
!     of conditions and the following disclaimer in the documentation and/or other
!     materials provided with the distribution.
!
! 3. Neither the name of the copyright holder nor the names of its contributors may be
!     used to endorse or promote products derived from this software without specific
!     prior written permission.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
! CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
! INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
! MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
! DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
! CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
! SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
! NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
! CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
! STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
! ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
! OF THE POSSIBILITY OF SUCH DAMAGE.
!**************************************************************
  !//  OPEN_FILES - THI SUBROUTINE JUST OPENS FILES
  !// 
  !//  WRITTEN BY DEREK WALTER, 1999
  !//  WARNING: THIS CODE DOES NOT CONFORM TO Y2K STANDARDS!! 
!**************************************************************
  !!DEC$ DEFINE HP_INTEGRALS
  
subroutine open_files
  
  use global_var_mod
  use molecule_var_mod
  use io_unit_numbers
  
  implicit none
  
  integer::icount

  real(kind=real8)::rdum
! START AUTOGENERATED INITIALIZATION 
icount = 0
rdum = 0.0
! END AUTOGENERATED INITIALIZATION            
  
  !// INTEGRAL FILES:
  !// One E- INTEGRALS    
  open (unit = ioii, file = scratch_directory // "ij.int", &
        form = "unformatted", status = "unknown", action = "readwrite")

  !// (II|II) INTEGRALS
  !open (unit = ioiiii, file = scratch_directory // "iiii.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")  
  
  !// (II|KK) AND (IK|IK) INTEGRALS
  !open (unit = ioiijj, file = scratch_directory // "iijj.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")   
  
  !// (IJ|KK), (II|IJ), AND (IJ|IK) INTEGRALS
  !open (unit = ioijkk, file = scratch_directory // "ijkk.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")  
        
  !// (IA|IB) INTEGRALS FOR TREATMENT OF THREE SEGMENT LOOPS WITH
  !// ONE SEGMENT IN THE INTERNAL SPACE
  !open (unit = ioiaib, file = scratch_directory // "iaib.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                
        
  !// (AB|CD) INTEGRALS FOR PURELY EXTERNAL FOUR SEGMENT LOOPS
  !open (unit = ioabcd, file = scratch_directory // "abcd.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                      
  
  !// (IJ|KL) INTEGRALS FOR PURELY INTERNAL FOUR SEGMENT LOOPS
  !open (unit = ioijkl2, file = scratch_directory // "ijkl2.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                            
        
  !// (AI|JK) INTEGRALS FOR TREATMENT OF FOUR SEGMENT LOOPS WITH
  !// THREE SEGMENTS IN THE INTERNAL SPACE
  !open (unit = ioaijk, file = scratch_directory // "aijk.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                  
        
  !// (IA|JA) INTEGRALS FOR THREE SEGMENT LOOPS WITH J,I IN INTERNAL SPACE
  !open (unit = ioiaja, file = scratch_directory // "iaja.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                        
        
  !// (IJ|AB) INTEGRALS FOR FOUR SEGMENT LOOPS WITH TWO SEGMENTS IN INTERNAL SPACE
  !open (unit = ioijab, file = scratch_directory // "ijab.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                              
        
  !// (IK|JK) INTEGRALS FOR PURELY INTERNAL THREE SEGMENT LOOPS
  !open (unit = ioikjk, file = scratch_directory // "ikjk.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                                    
        
  !// (IJ|AJ) INTEGRALS FOR THREE SEGMENT LOOPS WITH TWO SEGMENT IN THE INTERNAL SPACE
  !open (unit = ioijaj, file = scratch_directory // "ijaj.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                                          
        
  !// (AI|BI) INTEGRALS FOR PURELY EXTERNAL TWO SEGMENT LOOPS
  !open (unit = ioaibi, file = scratch_directory // "aibi.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")
  
  !// (IP|JP) INTEGRALS FOR PURELYINTERNAL TWO SEGMENT LOOPS
  !open (unit = ioipjp, file = scratch_directory // "ipjp.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")    
        
  !// (IJ|IJ) INTEGRALS FOR PURELY INTERNAL {26} LOOPS
  open (unit = ioijij, file = scratch_directory // "ijij.int", &
        form = "unformatted",status = "unknown", action = "readwrite")        
        
  !// (IP|AP) INTEGRALS. FILE IS FOR TREATMENT OF TWO SEGMENT LOOPS WITH ONE
  !// SEGMENT IN THE INTERNAL SPACE
  !open (unit = ioipap, file = scratch_directory // "ipap.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")
     
  !// (IA|BC) INTEGRALS. FOUR SEGMENT LOOPS WITH ONE IN INTERNAL SPACE
  !open (unit = ioiabc, file = scratch_directory // "iabc.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")                 
        
  !// DIAGONAL ELEMENT MATRICES
  !open (unit = ioDiag, file = scratch_directory // "diagonal", &
  !      form = "unformatted", status = "unknown", action = "readwrite")
  
  open (unit = ioDiagStore, file = scratch_directory // "diagonal_store", &
        form = "unformatted", status = "unknown", action = "readwrite")      

  !// FOR JACOBI DAVIDSON DIAGONALIZATION
  open(unit=iojdtemp,file= scratch_directory // 'jdtemp.dat',form='unformatted')
 
  !// STORAGE OF CI VECTORS
!  open (unit = ioB, file = scratch_directory // "ci", &
!        form = "unformatted", status = "unknown", action = "readwrite")
        
  !open (unit = iowrk, file = scratch_directory // "ci_bk", &
  !      form = "unformatted", status = "unknown", action = "readwrite")

  !open (unit = ioCIFinal, file = scratch_directory // "ci_final", &
  !      form = "unformatted", status = "unknown", action = "readwrite")      
  
!  !// STORAGE OF SIGMA VECTORS
!  open (unit = ioAB, file = scratch_directory // "sigma", form = "unformatted", &
!        status = "unknown", action = "readwrite")
        
  !// PSEUDOSPECTRAL QUANTITIES
  !open (unit = ioqr, file = scratch_directory // "qr.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")     
        
  !open (unit = ioakl, file = scratch_directory // "akl.int", &
  !      form = "unformatted", status = "unknown", action = "readwrite")                 
  
  !// (IJ|AA) INTEGRALS FOR THREE SEGMENT LOOPS WITH J,I IN INTERNAL SPACE
  !open (unit = ioijaa, file = scratch_directory // "ijaa.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite")                                        
  
  !// (AI|BI) INTEGRALS FOR PURELY EXTERNAL TWO SEGMENT LOOPS
  !open (unit = ioaibi_new, file = scratch_directory // "aibi_new.int", &
  !      form = "unformatted",status = "unknown", action = "readwrite") 

  open (unit = iodiag1, file = scratch_directory // "diagonal1", &
        form = "unformatted", status = "unknown", action = "readwrite")
        
  !// DIAGONAL ELEMENT MATRICES
  !open (unit = iodiag2, file = scratch_directory // "diagonal2", &
  !      form = "unformatted", status = "unknown", action = "readwrite")

  rdum = 0.0D0

  !open(unit=404,file=scratch_directory // '2s2singles.dat',form='unformatted')

  
  inquire(iolength=icount) icount,icount,icount,icount,icount,icount,icount,icount,icount,icount,icount 
  open(unit=405,file=scratch_directory // 'ijaj_seg_info.dat',access='direct',form='unformatted',recl=icount)

end subroutine open_files
