subroutine Print_Hello_World()
  integer ::i, temp
  !$acc parallel
  do i=1,5
     temp = temp + i
  end do
  !$acc end parallel
  print *, "Result: ", i
end subroutine Print_Hello_World

program main
  use openacc
  implicit none
  call Print_Hello_World()
end program main


