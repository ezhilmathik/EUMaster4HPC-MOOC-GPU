subroutine Print_Hello_World()
  integer ::i, temp
  do i=1,5
     temp = temp + i
  end do
  print *, "Result: ", temp
end subroutine Print_Hello_World

program main
  implicit none
  call Print_Hello_World()
end program main


