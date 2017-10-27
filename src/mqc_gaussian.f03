      Module MQC_Gaussian
!
!     **********************************************************************
!     **********************************************************************
!     **                                                                  **
!     **               The Merced Quantum Chemistry Package               **
!     **                            (MQCPack)                             **
!     **                       Development Version                        **
!     **                            Based On:                             **
!     **                     Development Version 0.1                      **
!     **                                                                  **
!     **                                                                  **
!     ** Written By:                                                      **
!     **    Lee M. Thompson, Xianghai Sheng, and Hrant P. Hratchian       **
!     **                                                                  **
!     **                                                                  **
!     **                      Version 1.0 Completed                       **
!     **                           May 1, 2017                            **
!     **                                                                  **
!     **                                                                  **
!     ** Modules beloning to MQCPack:                                     **
!     **    1. MQC_General                                                **
!     **    2. MQC_DataStructures                                         **
!     **    3. MQC_Algebra                                                **
!     **    4. MQC_Files                                                  **
!     **    5. MQC_Molecule                                               **
!     **    6. MQC_EST                                                    **
!     **    7. MQC_Gaussian                                               **
!     **                                                                  **
!     **********************************************************************
!     **********************************************************************
!
!
!     Set-up USE Association with Key MQC Modules.
!
      USE MQC_General
      USE MQC_Files
      USE MQC_Algebra
      USE MQC_EST
      USE MQC_molecule
!
!----------------------------------------------------------------
!                                                               |
!     TYPE AND CLASS DEFINITIONS                                |
!                                                               |
!----------------------------------------------------------------
!
!     File types...
!
!     MQC_Gaussian_FChk_File
      Type,Extends(MQC_Text_FileInfo)::MQC_Gaussian_FChk_File
        Character(Len=72)::Title
        Character(Len=10)::JobType
        Character(Len=30)::Method,BasisSet
      Contains
        Procedure::OpenFile => MQC_Gaussian_FChk_Open
      End Type MQC_Gaussian_FChk_File
!
!
!     MQC_Gaussian_Unformatted_Matrix_File
!       This object extends and belongs to the Class MQC_FileInfo.
!       Specifically, it is intended for use with Gaussian unformatted
!       matrix files.
      Type,Extends(MQC_FileInfo)::MQC_Gaussian_Unformatted_Matrix_File
        logical::declared=.false.,header_read=.false.,header_written=.false.
        character(len=1)::readWriteMode=' '
        character(len=64)::LabFil=' ',GVers=' ',Title=' '
        integer::natoms,nbasis,nbasisUse,icharge,multiplicity,nelectrons,icgu, &
          NFC,NFV,ITran,IDum9,NShlAO,NPrmAO,NShlDB,NPrmDB,NBTot
        integer,dimension(:),allocatable::atomicNumbers,atomTypes,basisFunction2Atom, &
          IBasisFunctionType
        real,dimension(:),allocatable::atomicCharges,atomicWeights,cartesians
      Contains
        procedure,pass::OpenFile       => MQC_Gaussian_Unformatted_Matrix_Open
        procedure,pass::CloseFile      => MQC_Gaussian_Unformatted_Matrix_Close
        procedure,pass::load           => MQC_Gaussian_Unformatted_Matrix_Read_Header
        procedure,pass::create         => MQC_Gaussian_Unformatted_Matrix_Write_Header
        procedure,pass::isRestricted   => MQC_Gaussian_IsRestricted
        procedure,pass::isUnrestricted => MQC_Gaussian_IsUnrestricted
        procedure,pass::isGeneral      => MQC_Gaussian_IsGeneral
        procedure,pass::isComplex      => MQC_Gaussian_IsComplex
        procedure,pass::getVal         => MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer
        procedure,pass::getArray       => MQC_Gaussian_Unformatted_Matrix_Read_Array
        procedure,pass::getAtomInfo    => MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info
        procedure,pass::getBasisInfo   => MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info
        procedure,pass::getESTObj      => MQC_Gaussian_Unformatted_Matrix_Get_EST_Object
        procedure,pass::writeArray     => MQC_Gaussian_Unformatted_Matrix_Write_Array
        procedure,pass::writeESTObj    => MQC_Gaussian_Unformatted_Matrix_Write_EST_Object
      End Type MQC_Gaussian_Unformatted_Matrix_File
!
!
!     Data containers...
!
!     MQC_Gaussian_Molecule_Data
      Type,Extends(MQC_Molecule_Data)::MQC_Gaussian_Molecule_Data
        Type(MQC_Scalar)::Charge,Multiplicity
      End Type MQC_Gaussian_Molecule_Data
!
!
!----------------------------------------------------------------
!                                                               |
!     PROCEDURE INTERFACES                                      |
!                                                               |
!----------------------------------------------------------------
!


!
!
!     Subroutines/Functions...
!
      CONTAINS
!
!PROCEDURE MQC_Gaussian_ICGU
      subroutine MQC_Gaussian_ICGU(ICGU,wf_type,wf_complex)
!
!     This subroutine interprets the Gaussian ICGU flag (picked up from fchk and
!     matrix files). There are two wavefunction characteristics that can be
!     determined from ICGU: the spin type (Restricted, Unrestricted, General)
!     and the complex/real type (complex or real).
!
!     <ICGU> is an INPUT integer argument. <wf_type> is an OUTPUT character
!     argument that is filled with 'R', 'U', or 'G'. <wf_complex> is an OUTPUT
!     logical argument that is returned as TRUE is the wavefunction is complex.
!     Both <wf_type> and <wf_complex> are OPTIONAL arguments.
!
!     H. P. Hratchian, 2017.
!
!
      implicit none
      integer,intent(IN)::ICGU
      character(len=*),intent(OUT),OPTIONAL::wf_type
      logical,intent(OUT),OPTIONAL::wf_complex
!
      if(PRESENT(wf_type)) then
        if (Mod(ICGU,1000)/100.eq.2) then
          wf_type = 'G'
        elseIf (Mod(ICGU,1000)/100.eq.1) then
          if (Mod(ICGU,10).eq.1) then
            wf_type = 'R'
          elseIf (Mod(ICGU,10).eq.2) then
            wf_type = 'U'
          else
            call MQC_Error('Unknown flag at ICGU 1st digit in MQC_Gaussian_ICGU ')
          endIf
        else
          call MQC_Error('Unknown flag at ICGU 3rd digit in MQC_Gaussian_ICGU ')
        endIf
      endIf
      if(PRESENT(wf_complex)) then
        if (Mod(ICGU,100)/10.eq.2) then
          wf_complex = .true.
        elseIf (Mod(ICGU,100)/10.eq.1) then
          wf_complex = .false.
        else
          Call MQC_Error('Unknown flag at ICGU 2nd digit in MQC_Gaussian_ICGU ')
        endIf
      endIf
!
      return
      end subroutine MQC_Gaussian_ICGU

 
!
!PROCEDURE MQC_Gaussian_IsRestricted
      function MQC_Gaussian_IsRestricted(fileinfo)
!
!     This LOGICAL function returns TRUE if the job described by the Gaussian
!     matrix file defined by object <fileinfo> corresponds to a spin-restricted
!     wavefunction.
!
!     H. P. Hratchian, 2017.
!
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(in)::fileinfo
      logical::MQC_Gaussian_IsRestricted
      character(len=1)::wf_type
!
      call MQC_Gaussian_ICGU(fileinfo%icgu,wf_type=wf_type)
      MQC_Gaussian_IsRestricted = (wf_type=='R'.or.wf_type=='r')
!
      return
      end function MQC_Gaussian_IsRestricted
!
!
!PROCEDURE MQC_Gaussian_IsUnrestricted
      function MQC_Gaussian_IsUnrestricted(fileinfo)
!
!     This LOGICAL function returns TRUE if the job described by the Gaussian
!     matrix file defined by object <fileinfo> corresponds to a
!     spin-unrestricted wavefunction.
!
!     H. P. Hratchian, 2017.
!
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(in)::fileinfo
      logical::MQC_Gaussian_IsUnrestricted
      character(len=1)::wf_type
!
      call MQC_Gaussian_ICGU(fileinfo%icgu,wf_type=wf_type)
      MQC_Gaussian_IsUnrestricted = (wf_type=='U'.or.wf_type=='u')
!
      return
      end function MQC_Gaussian_IsUnrestricted
!
!
!PROCEDURE MQC_Gaussian_IsGeneral     
      function MQC_Gaussian_IsGeneral(fileinfo)
!
!     This LOGICAL function returns TRUE if the job described by the Gaussian
!     matrix file defined by object <fileinfo> corresponds to a general-spin 
!     wavefunction.
!
!     L. M. Thompson, 2017.
!
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(in)::fileinfo
      logical::MQC_Gaussian_IsGeneral
      character(len=1)::wf_type
!
      call MQC_Gaussian_ICGU(fileinfo%icgu,wf_type=wf_type)
      MQC_Gaussian_IsGeneral = (wf_type=='G'.or.wf_type=='g')
!
      return
      end function MQC_Gaussian_IsGeneral
!
!
!PROCEDURE MQC_Gaussian_IsComplex     
      function MQC_Gaussian_IsComplex(fileinfo)
!
!     This LOGICAL function returns TRUE if the job described by the Gaussian
!     matrix file defined by object <fileinfo> corresponds to a complex wavefunction.
!
!     L. M. Thompson, 2017.
!
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(in)::fileinfo
      logical::MQC_Gaussian_IsComplex,wf_complex
!
      call MQC_Gaussian_ICGU(fileinfo%icgu,wf_complex=wf_complex)
      MQC_Gaussian_IsComplex = wf_complex
!
      return
      end function MQC_Gaussian_IsComplex
!
!
!PROCEDURE MQC_Gaussian_FChk_Open
      Subroutine MQC_Gaussian_FChk_Open(FileInfo,FileName,UnitNumber, &
        OK,fileAction)
!
!     This Routine is used to connect a Gaussian formatted checkpoint file. Note
!     that optional dummy argument <fileAction> is ALWAYS IGNORED by this
!     routine.
!
!
!     Variable Declarations.
!
      Implicit None
      Class(MQC_Gaussian_FChk_File),Intent(InOut)::FileInfo
      Character(Len=*),Intent(In)::FileName
      Integer,Intent(In)::UnitNumber
      Logical,optional,Intent(Out)::OK
      character(len=*),intent(in),optional::fileAction
!
      Character(Len=256)::Temp_Char
      Integer::IError
      Logical::EOF,Temp_Logical
!
!
!     Begin by opening the FChk file as an MQC text file.
!
      Call MQC_Open_Text_File(FileInfo,FileName,UnitNumber,OK)
      If(.not.OK) Return
!
!     Load the title, job type, method, and basis set from the first two
!     lines of the file.
!
      Call FileInfo%GetBuffer(FileInfo%Title)
      If (FileInfo%LoadBuffer()) Call MQC_Error('Failiure loading FChk buffer')
      Call FileInfo%GetNextString(FileInfo%JobType,EOF,OK)
      Call FileInfo%GetNextString(FileInfo%Method,EOF,OK)
      Call FileInfo%GetNextString(FileInfo%BasisSet,EOF,OK)
!
      Return
      End Subroutine MQC_Gaussian_FChk_Open


!
!PROCEDURE Find_FChk_Entry
      Subroutine Find_FChk_Entry(EntryTag,FChkFile,FoundEntry,  &
        TypeFlag,NElements,Scalar_Integer,Scalar_Real,Scalar_Character, &
        Scalar_Logical,Vector_Integer,Vector_Real)
!
!     This subroutine searches a Gaussian formatted checkpoint file
!     (FChkFile) for an entry tag (EntryTag). It returns a logical
!     indicating if the entry was found (FoundEntry), what sort of entry
!     was found (TypeFlag), and the number of data elements of the entry
!     (NElements).
!
!     More specifically, FoundEntry is returned TRUE if the desired entry
!     is found. TypeFlag is a single character variable that will be
!     returned with 'I', 'R', or 'A' for integer, real, or character
!     (alpha) data type found. NElements will be returned with 0 if the
!     data entry is a scalar. If the data is an array, NElements will be
!     returned with the length of the array.
!
!     If a scalar value is found, the correct output variable of Scalar_*
!     is filled as long as it has been passed to this routine (as the
!     Scalar_* arguments are all OPTIONAL).
!
!     If an array is found, the correct output variable of Vector_* is
!     filled as long as it has been passed to this routine (as the Vector_*
!     arguments are all OPTIONAL).
!
!
!     H. P. Hratchian, 2016.
!
!
!     Variable Declarations
!
      Implicit None
      Character(Len=*),Intent(IN)::EntryTag
      Type(MQC_Gaussian_FChk_File),Intent(InOut)::FChkFile
      Logical,Intent(OUT)::FoundEntry
      Character(*),Intent(OUT)::TypeFlag
      Integer,Intent(OUT)::NElements
      Integer,Intent(OUT),OPTIONAL::Scalar_Integer
      Real,Intent(OUT),OPTIONAL::Scalar_Real
      Character(*),Intent(OUT),OPTIONAL::Scalar_Character
      Logical,Intent(OUT),OPTIONAL::Scalar_Logical
      Integer,Dimension(:),Intent(OUT),OPTIONAL::Vector_Integer
      Real,Dimension(:),Intent(OUT),OPTIONAL::Vector_Real
!
      Character(Len=40)::Lab
      Character(Len=2)::PlaceholderNEq
      Character(Len=22)::ValueHolder
      Character(Len=1024)::Temp_Char
      Logical::Fail,OK,EOF,IsArray
!
!
!     Format Statements
!
 2000 Format(A40,3X,A1,3X,A2,A22)
 8000 Format(1x,'Label: ',A40,' | Type=',A1,' | NEq=',A2,  &
        ' | Value=',A12)
!
!
!     Initialize FoundEntry, TypeFlag, and NElements. Then, ensure the fchk
!     is open.
!
      FoundEntry = .False.
      TypeFlag = ' '
      NElements = -1
      If(.not.FChkFile%IsOpen()) Return
!
!     Search the file for the entry tag. If it isn't found in the first
!     try, rewind the file and try again.
!
      Call MQC_Files_FF_Search(Fail,FChkFile,EntryTag,.True.)
      If(Fail) then
        Call FChkFile%Rewind(OK)
        If(.not.OK) Return
        Call MQC_Files_FF_Search(Fail,FChkFile,EntryTag,.True.)
      endIf
      If(Fail) Return
      FoundEntry = .True.
      Call FChkFile%GetBuffer(Temp_Char,.False.)
      Read(Temp_Char,2000) Lab,TypeFlag,PlaceholderNEq,ValueHolder
      Write(*,8000) Lab,TypeFlag,PlaceholderNEq,ValueHolder
      If(PlaceholderNEq.eq.'N=') then
        Read(ValueHolder,'(I22)') NElements
        fail = FChkFile%LoadBuffer()
        If(fail) Return
        Select Case (TypeFlag)
        Case('I')
          Write(*,*)' Found an INTEGER ARRAY'
          If(Present(Vector_Integer)) then
            If(Size(Vector_Integer).ge.NElements) &
              Call MQC_Files_Text_File_Read_Int_Vec(FChkFile,  &
                Vector_Integer,EOF,OK)
          endIf
        Case('R')
         Write(*,*)' Found a REAL ARRAY'
          If(Present(Vector_Real)) then
            If(Size(Vector_Real).ge.NElements) &
              Call MQC_Files_Text_File_Read_Real_Vec(FChkFile,  &
                Vector_Real,EOF,OK)
          endIf
        Case('C')
          Write(*,*)' Found a CHARACTER ARRAY'
        Case('L')
          Write(*,*)' Found a LOGICAL ARRAY'
        Case Default
          Return
        End Select
      else
        Select Case (TypeFlag)
        Case('I')
          If(Present(Scalar_Integer))  &
            Read(ValueHolder,'(I22)') Scalar_Integer
        Case('R')
          If(Present(Scalar_Real))  &
            Read(ValueHolder,'(E22.15)') Scalar_Real
        Case('C')
          If(Present(Scalar_Character))  &
            Read(ValueHolder,'(A12)') Scalar_Character
        Case('L')
          If(Present(Scalar_Logical))  &
            Read(ValueHolder,'(L1)') Scalar_Logical
        Case Default
          Return
        End Select
      endIf
!
      Return
      End Subroutine Find_FChk_Entry


!
!PROCEDURE MQC_Gaussian_Fill_Molecule_Data_FChk
      Subroutine MQC_Gaussian_Fill_Molecule_Data_FChk(FChkFile,  &
        MoleculeData)
!
!     This subroutine is used to fill a MQC_Molecule_Data type variable
!     from a provided (and already open) Gaussian formatted checkpoint
!     file.
!
!     H. P. Hratchian, 2016.
!
!
      Implicit None
      Type(MQC_Gaussian_FChk_File),Intent(InOut)::FChkFile
      Class(MQC_Gaussian_Molecule_Data),Intent(InOut)::MoleculeData
!
      Integer::NElements,NAtoms,Charge,Multiplicity
      Integer,Dimension(:),Allocatable::AtomicNumbers
      Real,Dimension(:),Allocatable::AtomicMasses,NuclearCharges,  &
        Cartesians_1D
      Real,Dimension(:,:),Allocatable::Cartesians
      Character(Len=1024)::Temp_Char
      Logical::OK
!
!     Get the integer flags from the fchk file and then allocate the local
!     arrays appropriately.
!
      Call Find_FChk_Entry(                              &
        'Number of atoms                            I',  &
        FChkFile,OK,Temp_Char,NElements,Scalar_Integer=NAtoms)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error loading NAtoms.')
      Call Find_FChk_Entry(                              &
        'Charge                                     I',  &
        FChkFile,OK,Temp_Char,NElements,Scalar_Integer=Charge)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error loading Charge.')
      Call Find_FChk_Entry(                              &
        'Multiplicity                               I',  &
        FChkFile,OK,Temp_Char,NElements,Scalar_Integer=Multiplicity)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error loading Multiplicity.')
      Allocate(AtomicNumbers(NAtoms),AtomicMasses(NAtoms),  &
        NuclearCharges(NAtoms),Cartesians_1D(3*NAtoms),  &
        Cartesians(3,NAtoms))
!
!     Now, fill the arrays from the fchk file.
!
      Call Find_FChk_Entry(                              &
        'Atomic numbers                             I',  &
        FChkFile,OK,Temp_Char,NElements,Vector_Integer=AtomicNumbers)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error - AtomicNumbers.')
      Call Find_FChk_Entry(                              &
        'Nuclear charges                            R',  &
        FChkFile,OK,Temp_Char,NElements,Vector_Real=NuclearCharges)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error - NuclearCharges.')
      Call Find_FChk_Entry(                              &
        'Current cartesian coordinates              R',  &
        FChkFile,OK,Temp_Char,NElements,Vector_Real=Cartesians_1D)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error - Cartesians.')
      Cartesians = Reshape(Cartesians_1D,(/3,NAtoms/))
      Call Find_FChk_Entry(                              &
        'Real atomic weights                        R',  &
        FChkFile,OK,Temp_Char,NElements,Vector_Real=AtomicMasses)
      If(.not.OK)  &
        Call MQC_Error('MQC_Gaussian: FChk error - AtomicMasses.')
!
!     Fill the molecular data object. Then de-allocate arrays.
!
      Call MQC_Gaussian_Fill_Molecule_Data(MoleculeData,NAtoms,  &
        AtomicNumbers,AtomicMasses,NuclearCharges,Cartesians,Charge,  &
        Multiplicity)
      DeAllocate(AtomicNumbers,AtomicMasses,NuclearCharges,  &
        Cartesians_1D,Cartesians)
!
      End Subroutine MQC_Gaussian_Fill_Molecule_Data_FChk


!
!PROCEDURE MQC_Gaussian_Fill_Molecule_Data
      Subroutine MQC_Gaussian_Fill_Molecule_Data(MoleculeData,NAtoms,  &
        AtomicNumbers,AtomicMasses,NuclearCharges,Cartesians,  &
        TotalCharge,Multiplicity)
!
!     This subroutine is used to fill a MQC_Molecule_Data type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Class(MQC_Molecule_Data),Intent(Out)::MoleculeData
      Integer,Intent(In)::NAtoms
      Integer,Dimension(NAtoms),Intent(In)::AtomicNumbers
      Real,Dimension(NAtoms),Intent(In)::AtomicMasses,NuclearCharges
      Real,Dimension(3,NAtoms),Intent(In)::Cartesians
      Integer,Intent(In)::TotalCharge,Multiplicity
!
!     Add data to the standard MQC_Molecule_Data elements.
!
      Call MQC_Molecule_Data_Fill(MoleculeData,NAtoms,  &
        AtomicNumbers,AtomicMasses,NuclearCharges,Cartesians)
      Select Type(MoleculeData)
      Type is(MQC_Gaussian_Molecule_Data)
        MoleculeData%Charge = TotalCharge
        MoleculeData%Multiplicity = Multiplicity
      endSelect
!
      End Subroutine MQC_Gaussian_Fill_Molecule_Data


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_Core_Hamiltonian
      Subroutine MQC_Gaussian_Fill_Core_Hamiltonian(NBasis,Core_Ham_Alpha, &
        Core_Ham_Beta,Core_Hamiltonian)
!
!     This subroutine is used to fill a MQC_Core_Hamiltonian type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis
      Real,Dimension(:,:),Allocatable,Intent(In)::Core_Ham_Alpha, &
        Core_Ham_Beta
      Type(MQC_Core_Hamiltonian),Intent(Out)::Core_Hamiltonian
!
!     Allocate the arrays inside of MO_Coefficients...
!
      If(Allocated(Core_Ham_Alpha)) Core_Hamiltonian%Alpha = Core_Ham_Alpha
      If(Allocated(Core_Ham_Alpha)) Core_Hamiltonian%Beta = Core_Ham_Beta
!
      End Subroutine MQC_Gaussian_Fill_Core_Hamiltonian


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_Fock_Matrix
      Subroutine MQC_Gaussian_Fill_Fock_Matrix(NBasis,Fock_Matrix_Alpha, &
        Fock_Matrix_Beta,Fock_Matrix)
!
!     This subroutine is used to fill a MQC_Fock_Matrix type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis
      Real,Dimension(:,:),Allocatable,Intent(In)::Fock_Matrix_Alpha, &
        Fock_Matrix_Beta
      Type(MQC_Fock_Matrix),Intent(Out)::Fock_Matrix
!
!     Allocate the arrays inside of MO_Coefficients...
!
      If(Allocated(Fock_Matrix_Alpha)) Fock_Matrix%Alpha = Fock_Matrix_Alpha
      If(Allocated(Fock_Matrix_Beta)) Fock_Matrix%Beta = Fock_Matrix_Beta
!
      End Subroutine MQC_Gaussian_Fill_Fock_Matrix


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_MO_Coefficients
      Subroutine MQC_Gaussian_Fill_MO_Coefficients(NBasis,MO_Coeffs_Alpha, &
        MO_Coeffs_Beta,MO_Coefficients)
!
!     This subroutine is used to fill a MQC_MO_Coefficients type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis
      Real,Dimension(:,:),Allocatable,Intent(In)::MO_Coeffs_Alpha, &
        MO_Coeffs_Beta
      Type(MQC_MO_Coefficients),Intent(Out)::MO_Coefficients
!
!     Allocate the arrays inside of MO_Coefficients...
!
      If(Allocated(MO_Coeffs_Alpha)) MO_Coefficients%Alpha = MO_Coeffs_Alpha
      If(Allocated(MO_Coeffs_Alpha)) MO_Coefficients%Beta = MO_Coeffs_Beta
!
      End Subroutine MQC_Gaussian_Fill_MO_Coefficients


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_Overlap_Matrix
      Subroutine MQC_Gaussian_Fill_Overlap_Matrix(NBasis,In_Overlap_Matrix, &
        Overlap_Matrix)
!
!     This subroutine is used to fill a MQC_Overlap_Matrix type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis
      Real,Dimension(:,:),Allocatable,Intent(In)::In_Overlap_Matrix
      Type(MQC_Overlap_Matrix),Intent(Out)::Overlap_Matrix
!
!     Allocate the arrays inside of MO_Coefficients...
!
      If(Allocated(In_Overlap_Matrix)) Overlap_Matrix%Alpha = In_Overlap_Matrix
!
      End Subroutine MQC_Gaussian_Fill_Overlap_Matrix


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_Wavefunction
      Subroutine MQC_Gaussian_Fill_Wavefunction(NBasis,NElectrons,ICGU, &
        Charge,Multiplicity,MO_Coeffs_Alpha,MO_Coeffs_Beta,Core_Hamiltonian_Alpha, &
        Core_Hamiltonian_Beta,Fock_Matrix_Alpha,Fock_Matrix_Beta,Overlap_Matrix, &
        Wavefunction)
!
!     This subroutine is used to fill a MQC_Wavefunction type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis,NElectrons,ICGU,Charge,Multiplicity
      Real,Dimension(:,:),Allocatable,Intent(In)::Overlap_Matrix,Core_Hamiltonian_Alpha, &
      Core_Hamiltonian_Beta,Fock_Matrix_Alpha,Fock_Matrix_Beta,MO_Coeffs_Alpha, &
      MO_Coeffs_Beta
      Class(MQC_Wavefunction),Intent(Out)::Wavefunction
!
!     Allocate the arrays inside of Wavefunction object...
!
      Wavefunction%NBasis = NBasis
      Wavefunction%NElectrons = NElectrons
      if (Mod(ICGU,1000)/100.eq.2) then
        Wavefunction%WF_Type = 'G'
      elseIf (Mod(ICGU,1000)/100.eq.1) then
        if (Mod(ICGU,10).eq.1) then
          Wavefunction%WF_Type = 'R'
        elseIf (Mod(ICGU,10).eq.2) then
          Wavefunction%WF_Type = 'U'
        else
          Call MQC_Error('Unknown flag at ICGU 1st bit in MQC_Gaussian_Fill_Wavefunction ')
        endIf
      else
        Call MQC_Error('Unknown flag at ICGU 3rd bit in MQC_Gaussian_Fill_Wavefunction ')
      endIf
      if (Mod(ICGU,100)/10.eq.2) then
        Wavefunction%WF_Complex = .True.
      elseIf (Mod(ICGU,100)/10.eq.1) then
        Wavefunction%WF_Complex = .False.
      else
        Call MQC_Error('Unknown flag at ICGU 2nd bit in MQC_Gaussian_Fill_Wavefunction ')
      endIf
      Wavefunction%Charge = Charge
      Wavefunction%Multiplicity = Multiplicity
      Wavefunction%NAlpha = (NElectrons + (Multiplicity-1))/2
      Wavefunction%NBeta = NElectrons-(NElectrons + (Multiplicity-1))/2
      if(Allocated(Core_Hamiltonian_Alpha)) Wavefunction%Core_Hamiltonian%Alpha = Core_Hamiltonian_Alpha
      if(Allocated(Core_Hamiltonian_Beta)) Wavefunction%Core_Hamiltonian%Beta = Core_Hamiltonian_Beta
      if(Allocated(Fock_Matrix_Alpha)) Wavefunction%Fock_Matrix%Alpha = Fock_Matrix_Alpha
      if(Allocated(Fock_Matrix_Beta)) Wavefunction%Fock_Matrix%Beta = Fock_Matrix_Beta
      if(Allocated(MO_Coeffs_Alpha)) Wavefunction%MO_Coefficients%Alpha = MO_Coeffs_Alpha
      if(Allocated(MO_Coeffs_Beta)) Wavefunction%MO_Coefficients%Beta = MO_Coeffs_Beta
      if(Allocated(Overlap_Matrix)) Wavefunction%Overlap_Matrix%Alpha = Overlap_Matrix
!     LMT: Put funciton in EST for computing density matrix and fill this here
!     LMT: Put funciton in EST for computing orbital energy and fill this here
!     LMT: Put funciton in EST for Symmetry and fill this here
!     LMT: Put funciton in EST for Basis and fill this here
!     LMT: PSCF extentions? 
!
      End Subroutine MQC_Gaussian_Fill_Wavefunction


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Fill_ERIs
      Subroutine MQC_Gaussian_Fill_ERIs(NBasis,ERIs,ERIs_Full,Integral_Type)
!
!     This subroutine is used to fill a MQC_TwoERIs type variable
!     given INPUT dummy arguments for each of its constituents entries.
!
      Implicit None
      Integer,Intent(In)::NBasis
      Real,Dimension(:,:,:,:),Allocatable,Intent(In)::ERIs
      Character(Len=64)::Integral_Type
      Type(MQC_TwoERIs),Intent(Out)::ERIs_Full
!
!     Allocate the arrays inside of MO_Coefficients...
!
      ERIs_Full%AO = .True.
      ERIs_Full%UHF = .False.
      ERIs_Full%Storage_Type = 'Full'
      ERIs_Full%Integral_Type = Integral_Type
      If(Allocated(ERIs)) ERIs_Full%TwoERIs = ERIs
!
      End Subroutine MQC_Gaussian_Fill_ERIs


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Read_Matrix_File
      Subroutine MQC_Gaussian_Read_Matrix_File(DEBUG_PRINT,FileName,  &
        MoleculeInfo,Wavefunction,ERIs_Full,NumberBasisFunctions, &
        NumberElectrons,ElectronicMultiplicity,Basis2AtomMap,Overlap_Matrix, &
        MO_Coefficients,Core_Hamiltonian,Fock_Matrix)
!
!     This subroutine is used to read a Gaussian (binary) Matrix File.
!
!
!     Dummy Arguments
      Implicit None
      Logical,Intent(In)::DEBUG_PRINT
      Character(Len=256),Intent(In)::FileName
      Class(MQC_Molecule_Data),Optional,Intent(Out)::MoleculeInfo
      Type(MQC_MO_Coefficients),Optional,Intent(Out)::MO_Coefficients
      Type(MQC_Fock_Matrix),Optional,Intent(Out)::Fock_Matrix
      Type(MQC_Core_Hamiltonian),Optional,Intent(Out)::Core_Hamiltonian
      Type(MQC_Overlap_Matrix),Optional,Intent(Out)::Overlap_Matrix
      Class(MQC_Wavefunction),Optional,Intent(Out)::Wavefunction
      Type(MQC_TwoERIs),Optional,Intent(Out)::ERIs_Full
      Integer,Dimension(:),Allocatable,Optional,Intent(Out)::Basis2AtomMap
      Integer,Optional,Intent(Out)::NumberBasisFunctions,NumberElectrons, &
        ElectronicMultiplicity
!      Real,Dimension(:,:,:,:),Allocatable,Optional,Intent(Out)::ERIs_Full
!
!     Test Variables/Arrays...
      Real,Dimension(:),Allocatable::Overlap_Symm,Fock_AO_Symm
      Real,Dimension(:,:),Allocatable::MO_Coeffs_Alpha,MO_Coeffs_Beta, &
        Overlap_Sq,Fock_AO_Sq,Fock_MO_Sq,Fock_Matrix_Alpha,Fock_Matrix_Beta, &
        Core_Hamiltonian_Alpha,Core_Hamiltonian_Beta,In_Overlap_Matrix
!      Type(ERI_Value),Dimension(:),Allocatable::ERIs
      Real,Dimension(:,:,:,:),Allocatable::ERIs
!      Integer::ERI_i,ERI_j,ERI_k,ERI_l
!
!     General Set of Variables...
      Integer,Parameter::IGMat_Unit=10,IGMat_LStr=64
      Integer::IError
!
!     Varibles for key read-in values...
      Integer::IGMat_Version,NLab,NAtoms,NBasis,NBasisUse,NBasisSymm, &
        ICharge,Multiplicity,NElectrons,Len12L,Len4L,IOpCl,ICGU
      Integer,Dimension(:),Allocatable::AtomicNumbers,AtomTypes, &
        Map_BF2Atom,BF_TypeDefs
      Real,Dimension(:),Allocatable::NuclearCharges,AtomicWeights
      Real,Dimension(:,:),Allocatable::CartesianCoordinates
      Character(Len=IGMat_LStr)::FileType_Label=' ',Gaussian_Version=' '
      Character(Len=64)::Title=' ',Integral_Type
!
!     Temp variables used when reading matrix headers.
      Integer::NI,NR,NTot,NPerRec,N1,N2,N3,N4,N5,ISym,NRecords
      Character(len=64)::Matrix_Label
!
!     Temp variables...
      Integer::iStart,IEnd,IStart1,IEnd1,i,j,II,JJ,KK,LL,Int_Tmp1
      Integer,Dimension(:),Allocatable::Int_Vector_Tmp1
      Integer,Dimension(:,:),Allocatable::Int_Matrix_Tmp1
      Real::Real_Tmp1
      Real,Dimension(:),Allocatable::Real_Vector_Tmp1,Real_Vector_Tmp2
      Real,Dimension(:,:),Allocatable::Real_Matrix_Tmp1,Real_Matrix_Tmp2
      Character(len=64)::Char_Tmp1
!
!
!     Format Statements.
!
 1000 Format(1x,'Reading file ',A)
 2000 Format(1x,'Atom',5x,'Atomic Num',5x,'Atom Type',6x,'Atomic Charge')
 2010 Format(1x,I3,6x,I6,10x,I6,10x,F10.5)
 2200 Format(1x,'Atom',15x,'x',17x,'y',17x,'z')
 2210 Format(1x,I3,6x,F15.8,3x,F15.8,3x,F15.8)
 5000 Format(1x,'(',I3,',',I3,'|',I3,',',I3,') = ',F15.8)
!
!
!     Read and open the user-defined Gaussian Matrix File.
!
      If(DEBUG_PRINT) Write(*,1000) TRIM(FileName)
      Open(Unit=IGMat_Unit,File=FileName,Form='Unformatted', &
        Status='Old',IOStat=IError)
!
!     Read Record 1.
!       File Type Label, G-Matrix File Version, NLab, Gaussian Version.
      Read(IGMat_Unit) FileType_Label(1:IGMat_LStr),IGMat_Version,NLab, &
        Gaussian_Version(1:IGMat_LStr)
      If(DEBUG_PRINT) then
        Write(*,*)' Hrant - FileType_Label  : ',TRIM(FileType_Label)
        Write(*,*)'         IGMat_Version   : ',IGMat_Version
        Write(*,*)'         NLab            : ',NLab
        Write(*,*)'         Gaussian_Version: ',TRIM(Gaussian_Version)
        Write(*,*)
      EndIf
!
!     Read Record 2.
!       Title, NAtoms, NBasis, NBasisUse, Charge, Multiplicity, NElectrons,
!       Len12L, Len4L, IOpCl, and ICGU.
      Read(IGMat_Unit) Title,NAtoms,NBasis,NBasisUse,ICharge, &
        Multiplicity,NElectrons,Len12L,Len4L,IOpCl,ICGU
      If(DEBUG_PRINT) then
        Write(*,*)'        Title            : ',TRIM(Title)
        Write(*,*)'        NAtoms           : ',NAtoms
        Write(*,*)'        NBasis           : ',NBasis
        Write(*,*)'        NBasisUse        : ',NBasisUse
        Write(*,*)'        ICharge          : ',ICharge
        Write(*,*)'        Multiplicity     : ',Multiplicity
        Write(*,*)'        NElectrons       : ',NElectrons
        Write(*,*)'        Len12L           : ',Len12L
        Write(*,*)'        Len4L            : ',Len4L
        Write(*,*)'        IOpCl            : ',IOpCl
        Write(*,*)'        ICGU             : ',ICGU
        Write(*,*)
      EndIf
      If(PRESENT(NumberBasisFunctions)) NumberBasisFunctions = NBasis
      If(PRESENT(NumberElectrons)) NumberElectrons = NElectrons
      If(PRESENT(ElectronicMultiplicity)) ElectronicMultiplicity = Multiplicity
!
!     Read Records 3-5.
!       Atomic numbers, Atom types, Atomic charges (possibly different from
!       atomic number is ECPs were used).
      Allocate(AtomicNumbers(NAtoms),AtomTypes(NAtoms), &
        NuclearCharges(NAtoms))
      Read(IGMat_Unit) (AtomicNumbers(i),i=1,NAtoms)
      Read(IGMat_Unit) (AtomTypes(i),i=1,NAtoms)
      Read(IGMat_Unit) (NuclearCharges(i),i=1,NAtoms)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,2000)
        Do i = 1,NAtoms
          Write(*,2010) i,AtomicNumbers(i),AtomTypes(i),NuclearCharges(i)
        EndDo
        Write(*,*)
      EndIf
!
!     Read Record 6.
!       Cartesian coordinates.
      Allocate(CartesianCoordinates(3,NAtoms))
      Read(IGMat_Unit) ((CartesianCoordinates(i,j),i=1,3),j=1,NAtoms)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,2200)
        Do i = 1,NAtoms
          Write(*,2210) i,CartesianCoordinates(:,i)
        EndDo
        Write(*,*)
      EndIf
!
!     Read Record 7.
!       Map_BF2Atom, BF_TypeDefs.
      Allocate(Int_Vector_Tmp1(2*NBasis),Map_BF2Atom(NBasis), &
        BF_TypeDefs(NBasis))
      Read(IGMat_Unit) (Int_Vector_Tmp1(i),i=1,2*NBasis)
      Map_BF2Atom = Int_Vector_Tmp1(1:NBasis)
      BF_TypeDefs = Int_Vector_Tmp1(NBasis+1:2*NBasis)
      DeAllocate(Int_Vector_Tmp1)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,*)' Hrant - Map_BF2Atom,BF_TypeDefs'
        Do i = 1,NBasis
          Write(*,*) Map_BF2Atom(i),BF_TypeDefs(i)
        EndDo
        Write(*,*)
      EndIf
      If(PRESENT(Basis2AtomMap)) then
        Allocate(Basis2AtomMap(NBasis))
        Basis2AtomMap = Map_BF2Atom
      EndIf
!
!     Read Record 8.
!       Atomic weights.
      Allocate(AtomicWeights(NAtoms))
      Read(IGMat_Unit) (AtomicWeights(i),i=1,NAtoms)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,*)' Hrant - Atomic Weights'
        Do i = 1,NAtoms
          Write(*,*) AtomicWeights(i)
        EndDo
        Write(*,*)
      EndIf
!
!     Read Record 9.
!       Atomic weights.
      Allocate(Int_Vector_Tmp1(4))
      Int_Vector_Tmp1 = 0
      Read(IGMat_Unit) (Int_Vector_Tmp1(i),i=1,3)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,*)' Hrant - Window Flags:'
        Write(*,*)'   NFC   = ',Int_Vector_Tmp1(1)
        Write(*,*)'   NFV   = ',Int_Vector_Tmp1(2)
        Write(*,*)'   ITran = ',Int_Vector_Tmp1(3)
        Write(*,*)'   IDum  = ',Int_Vector_Tmp1(4)
        Write(*,*)
      EndIf
      DeAllocate(Int_Vector_Tmp1)
!
!     Read Record 10.
!       This is a placeholder.
      Read(IGMat_Unit)
!
!     Read Record 11.
!       16 Integers. The first 5 are currently used flags and the rest are
!       placeholders for now.
      Allocate(Int_Vector_Tmp1(16))
      Int_Vector_Tmp1 = 0
      Read(IGMat_Unit) (Int_Vector_Tmp1(i),i=1,16)
      If(DEBUG_PRINT) then
        Write(*,*)
        Write(*,*)' Hrant - Record 11 Flags with Meaning...'
        Write(*,*)'   NShellAO = ',Int_Vector_Tmp1(1)
        Write(*,*)'   NPrimAO  = ',Int_Vector_Tmp1(2)
        Write(*,*)'   NShellDB = ',Int_Vector_Tmp1(3)
        Write(*,*)'   NPrimDB  = ',Int_Vector_Tmp1(4)
        Write(*,*)'   NBTot    = ',Int_Vector_Tmp1(5)
        Write(*,*)
        Write(*,*)' Hrant - Record 11 Flags ... ALL OF THEM'
        Do i = 1,16
          Write(*,*) i,Int_Vector_Tmp1(i)
        EndDo
        Write(*,*)
      EndIf
      DeAllocate(Int_Vector_Tmp1)
      NBasisSymm = NBasis*(NBasis+1)/2
!
!     Read the matrices now...
      If(DEBUG_PRINT) Write(*,*)
      Do
        Read(IGMat_Unit,End=900) Matrix_Label,NI,NR,NTot,NPerRec,N1, &
          N2,N3,N4,N5,ISym
        If(DEBUG_PRINT) Write(*,*)' Matrix Label    = ',TRIM(Matrix_Label)
        If(TRIM(Matrix_Label).eq.'END') Exit
        NRecords = (NTot+NPerRec-1)/NPerRec
        If(DEBUG_PRINT) then
          Write(*,*)'   NI       = ',NI
          Write(*,*)'   NR       = ',NR
          Write(*,*)'   NTot     = ',NTot
          Write(*,*)'   NPerRec  = ',NPerRec
          Write(*,*)'   N1       = ',N1
          Write(*,*)'   N2       = ',N2
          Write(*,*)'   N3       = ',N3
          Write(*,*)'   N4       = ',N4
          Write(*,*)'   N5       = ',N5
          Write(*,*)'   ISym     = ',ISym
          Write(*,*)
          Write(*,*)'   NRecords = ',NRecords
        EndIf
!        Write(*,*) 'about to do overlap', PRESENT(Overlap_Matrix),Present(Wavefunction), &
!          TRIM(Matrix_Label)
        If((PRESENT(Overlap_Matrix).or.Present(Wavefunction))  &
          .and.TRIM(Matrix_Label).eq.'OVERLAP') then
          Allocate(Overlap_Symm(NBasisSymm))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Overlap_Symm(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Overlap_Symm(IStart:NTot)
          If(PRESENT(Overlap_Matrix).or.Present(Wavefunction)) then
            Allocate(In_Overlap_Matrix(NBasis,NBasis))
            Call Matrix_Symm2Sq(NBasis,Overlap_Symm,In_Overlap_Matrix)
          EndIf
!
!
        else if((PRESENT(Core_Hamiltonian).or.Present(Wavefunction)).and.  &
          TRIM(Matrix_Label).eq.'CORE HAMILTONIAN ALPHA') then
          Allocate(Real_Vector_Tmp1(NBasisSymm))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:NTot)
          Allocate(Core_Hamiltonian_Alpha(NBasis,NBasis))
          Call Matrix_Symm2Sq(NBasis,Real_Vector_Tmp1,Core_Hamiltonian_Alpha)
          DeAllocate(Real_Vector_Tmp1)
!
        else if((PRESENT(Core_Hamiltonian).or.Present(Wavefunction)).and.  &
          TRIM(Matrix_Label).eq.'CORE HAMILTONIAN BETA') then
          Allocate(Real_Vector_Tmp1(NBasisSymm))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:NTot)
          Allocate(Core_Hamiltonian_Beta(NBasis,NBasis))
          Call Matrix_Symm2Sq(NBasis,Real_Vector_Tmp1,Core_Hamiltonian_Beta)
          DeAllocate(Real_Vector_Tmp1)
!
!
        else if((PRESENT(Fock_Matrix).or.Present(Wavefunction))  &
          .and.TRIM(Matrix_Label).eq.'ALPHA FOCK MATRIX') then
          Allocate(Fock_AO_Symm(NBasisSymm))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Fock_AO_Symm(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Fock_AO_Symm(IStart:NTot)
          Allocate(Fock_Matrix_Alpha(NBasis,NBasis))
          Call Matrix_Symm2Sq(NBasis,Fock_AO_Symm,Fock_Matrix_Alpha)
          DeAllocate(Fock_AO_Symm)
!
        else if((PRESENT(Fock_Matrix).or.Present(Wavefunction))  &
          .and.TRIM(Matrix_Label).eq.'BETA FOCK MATRIX') then
          Allocate(Fock_AO_Symm(NBasisSymm))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Fock_AO_Symm(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Fock_AO_Symm(IStart:NTot)
          Allocate(Fock_Matrix_Beta(NBasis,NBasis))
          Call Matrix_Symm2Sq(NBasis,Fock_AO_Symm,Fock_Matrix_Beta)
          DeAllocate(Fock_AO_Symm)
!
!
        else if((PRESENT(MO_Coefficients).or.Present(Wavefunction)).and.  &
          TRIM(Matrix_Label).eq.'ALPHA MO COEFFICIENTS') then
          Allocate(MO_Coeffs_Alpha(NBasis,NBasis), &
            Real_Vector_Tmp1(NBasis*NBasis))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:NTot)
          iStart = 1
          Do i = 1,NBasis
            IStart = (i-1)*NBasis+1
            IEnd   = i*NBasis
            MO_Coeffs_Alpha(:,i) = Real_Vector_Tmp1(IStart:IEnd)
          EndDo
          DeAllocate(Real_Vector_Tmp1)
!
        else if((PRESENT(MO_Coefficients).or.Present(Wavefunction)).and.  &
          TRIM(Matrix_Label).eq.'BETA MO COEFFICIENTS') then
          Allocate(MO_Coeffs_Beta(NBasis,NBasis), &
            Real_Vector_Tmp1(NBasis*NBasis))
          iStart = 1
          Do i = 1,NRecords-1
            IEnd = IStart + NPerRec - 1
            Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:IEnd)
            iStart = iStart + NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Real_Vector_Tmp1(IStart:NTot)
          iStart = 1
          Do i = 1,NBasis
            IStart = (i-1)*NBasis+1
            IEnd   = i*NBasis
            MO_Coeffs_Beta(:,i) = Real_Vector_Tmp1(IStart:IEnd)
          EndDo
          DeAllocate(Real_Vector_Tmp1)
!
!
        else if(PRESENT(ERIs_Full).and.  &
          TRIM(Matrix_Label).eq.'REGULAR 2E INTEGRALS') then
          Integral_Type = 'Regular'
          If(Present(ERIs_Full)) then
            Allocate(ERIs(NBasis,NBasis,NBasis,NBasis))
            ERIs = 0.0
          endIf
          Allocate(Int_Matrix_Tmp1(4,NPerRec),Real_Vector_Tmp1(NPerRec))
          IStart = 1
          Do i = 1,NRecords-1
            Read(IGMat_Unit,End=900) Int_Matrix_Tmp1,Real_Vector_Tmp1
            Do j = 1,NPerRec
              II = Int_Matrix_Tmp1(1,j)
              JJ = Int_Matrix_Tmp1(2,j)
              KK = Int_Matrix_Tmp1(3,j)
              LL = Int_Matrix_Tmp1(4,j)
              If(DEBUG_PRINT) &
                Write(*,5000) II,JJ,KK,LL,Real_Vector_Tmp1(j)
              If(Present(ERIs_Full)) then
                ERIs(II,JJ,KK,LL) = Real_Vector_Tmp1(j)
                ERIs(JJ,II,KK,LL) = Real_Vector_Tmp1(j)
                ERIs(II,JJ,LL,KK) = Real_Vector_Tmp1(j)
                ERIs(JJ,II,LL,KK) = Real_Vector_Tmp1(j)
                ERIs(KK,LL,II,JJ) = Real_Vector_Tmp1(j)
                ERIs(KK,LL,JJ,II) = Real_Vector_Tmp1(j)
                ERIs(LL,KK,II,JJ) = Real_Vector_Tmp1(j)
                ERIs(LL,KK,JJ,II) = Real_Vector_Tmp1(j)
              endIf
            EndDo
            IStart = IStart+NPerRec
          EndDo
          Read(IGMat_Unit,End=900) Int_Matrix_Tmp1,  &
            Real_Vector_Tmp1
          Do j = 1,NTot-IStart+1
            II = Int_Matrix_Tmp1(1,j)
            JJ = Int_Matrix_Tmp1(2,j)
            KK = Int_Matrix_Tmp1(3,j)
            LL = Int_Matrix_Tmp1(4,j)
            If(DEBUG_PRINT) &
              Write(*,5000) II,JJ,KK,LL,Real_Vector_Tmp1(j)
            If(Present(ERIs_Full)) then
              ERIs(II,JJ,KK,LL) = Real_Vector_Tmp1(j)
              ERIs(JJ,II,KK,LL) = Real_Vector_Tmp1(j)
              ERIs(II,JJ,LL,KK) = Real_Vector_Tmp1(j)
              ERIs(JJ,II,LL,KK) = Real_Vector_Tmp1(j)
              ERIs(KK,LL,II,JJ) = Real_Vector_Tmp1(j)
              ERIs(KK,LL,JJ,II) = Real_Vector_Tmp1(j)
              ERIs(LL,KK,II,JJ) = Real_Vector_Tmp1(j)
              ERIs(LL,KK,JJ,II) = Real_Vector_Tmp1(j)
            endIf
          EndDo
          DeAllocate(Int_Matrix_Tmp1,Real_Vector_Tmp1)
        else
          Do i = 1,NRecords
            Read(IGMat_Unit,End=900)
          EndDo
        endIf
      EndDo
      Goto 999
 900  Write(*,*)
      Write(*,*)' PROBLEM READING FIRST MATRIX INFO!'
      Write(*,*)
!
 999  Continue
      If(Present(MoleculeInfo))  &
        Call MQC_Gaussian_Fill_Molecule_Data(MoleculeInfo,NAtoms,  &
        AtomicNumbers,AtomicWeights,NuclearCharges,  &
        CartesianCoordinates,ICharge,Multiplicity)
      If(Present(Core_Hamiltonian))  &
        Call MQC_Gaussian_Fill_Core_Hamiltonian(NBasis,Core_Hamiltonian_Alpha, &
        Core_Hamiltonian_Beta,Core_Hamiltonian)
      If(Present(Fock_Matrix))  &
        Call MQC_Gaussian_Fill_Fock_Matrix(NBasis,Fock_Matrix_Alpha, &
        Fock_Matrix_Beta,Fock_Matrix)
      If(Present(MO_Coefficients))  &
        Call MQC_Gaussian_Fill_MO_Coefficients(NBasis,MO_Coeffs_Alpha, &
        MO_Coeffs_Beta,MO_Coefficients)
      If(Present(Overlap_Matrix))  &
        Call MQC_Gaussian_Fill_Overlap_Matrix(NBasis,In_Overlap_Matrix, &
        Overlap_Matrix)
      If(Present(Wavefunction))  &
        Call MQC_Gaussian_Fill_Wavefunction(NBasis,NElectrons,ICGU, &
        ICharge,Multiplicity,MO_Coeffs_Alpha,MO_Coeffs_Beta,Core_Hamiltonian_Alpha, &
        Core_Hamiltonian_Beta,Fock_Matrix_Alpha,Fock_Matrix_Beta, &
        In_Overlap_Matrix,Wavefunction)
      If(Present(ERIs_Full))  &
        Call MQC_Gaussian_Fill_ERIs(NBasis,ERIs,ERIs_Full,Integral_Type)
!
      End Subroutine MQC_Gaussian_Read_Matrix_File


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Open
      subroutine MQC_Gaussian_Unformatted_Matrix_Open(fileinfo,filename,unitnumber,ok)
!
!     This Routine is used to set-up a Gaussian unformatted matrix file
!     object file. The dummy argument <FileName> is an input argument
!     giving the the name of the file. For now, the dummy argument
!     <unitnumber> must be sent, but it is ultimately. The output dummy
!     argument <ok> is returned TRUE if everything proceeds without error;
!     otherwise, <ok> is returned FALSE.
!
!     NOTE: This routine does NOT actually open the file. Instead, this
!     routine serves as the required OpenFile deferred procedure binding
!     for members of the MQC_FileInfo class. Because the unformatted matrix
!     file is a Fortran unformatted file, the file will only be read OR
!     write. So, there are two different routines for working with the file
!     -- one for READ mode and one for WRITE mode. Also, note that the
!     matrix file has header scalars and arrays that must initially be
!     read/written. Then arrays/matrices can be read/written.
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::filename
      integer,intent(in)::unitnumber
      logical,intent(out)::ok
!
      integer::iout=6,unit_number
!
!
!     Begin by opening the file.
!
      if(fileinfo%IsOpen()) call MQC_Gaussian_Unformatted_Matrix_Close(fileinfo)
      ok = .true.
      fileinfo%filename       = TRIM(filename)
      fileinfo%UnitNumber     = unitnumber
      fileinfo%declared       = .false.
      fileinfo%CurrentlyOpen  = .true.
!
      return
      end subroutine MQC_Gaussian_Unformatted_Matrix_Open


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Close
      subroutine MQC_Gaussian_Unformatted_Matrix_Close(fileinfo)
!
!     This Routine is used to close a Gaussian unformatted matrix file.
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
!
!
!     Close the matrix file using the gauopen routines.
!
      if(fileinfo%isOpen()) call Close_MatF(fileinfo%UnitNumber)
      fileinfo%filename       = ' '
      fileinfo%CurrentlyOpen  = .false.
      fileinfo%UnitNumber     = 0
      fileinfo%declared       = .false.
      fileinfo%header_read    = .false.
      fileinfo%readWriteMode  = ' '
      fileinfo%LabFil         = ' '
      fileinfo%GVers          = ' '
      fileinfo%Title          = ' '
      DEALLOCATE(fileinfo%atomicNumbers)
      DEALLOCATE(fileinfo%atomTypes)
      DEALLOCATE(fileinfo%basisFunction2Atom)
      DEALLOCATE(fileinfo%atomicCharges)
      DEALLOCATE(fileinfo%atomicWeights)
      DEALLOCATE(fileinfo%cartesians)
!
      return
      end Subroutine MQC_Gaussian_Unformatted_Matrix_Close


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Read_Header
      subroutine MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
        filename)
!
!     This Routine is used to connect a Gaussian unformatted matrix file
!     and read the header records. If sent, this routine also loads an
!     MQC_Molecule_Data object. The dummy argument <FileName> is an input
!     argument giving the the name of the file.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open may be called
!     before calling this routine. However, it is also OK to call this
!     routine first. In that case, this routine will first call
!     Routine MQC_Gaussian_Unformatted_Matrix_Open.
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in),OPTIONAL::filename
!
      integer::iout=6
!
!     Temporary local variables used when calling the gauopen routines.
      integer::IVers,NLab,Len12L,Len4L,IOpCl
!      integer::NFC,NFV,ITran,IDum9,NShlAO,NPrmAO,NShlDB,NPrmDB,NBTot
      character(len=64)::cBuffer
!
!     Local temp variables.
      real,dimension(:),allocatable::tempArray
      character(len=256)::my_filename
      logical::DEBUG=.true.,ok
!
!
!     Format statements.
!
 1000 format(1x,'Reading data from file: ',A,/,1x,'Unit number: ',I3,/)
 1010 format(3x,' Label ',A,' IVers=',I2,' NLab=',I2,' Version=',A,  &
        /,3x,' Title ',A,  &
        /,3x,' NAtoms=',I6,' NBasis=',I6,' NBsUse=',I6,' ICharg=',I6,  &
        ' Multip=',I6,' NElec=',I6,' Len12L=',I1,' Len4L=',I1,' IOpCl=',I6,  &
        ' ICGU=',I3)
!
!
!     Begin by seeing if a new file or filename has been sent by the calling
!     program unit. If so, then get the file declared before reading the
!     header information.
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call fileinfo%OPENFILE(TRIM(filename),0,ok)
          if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
        else
          call MQC_Error('Error reading Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call fileinfo%OPENFILE(TRIM(filename),0,ok)
          if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'R' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call fileinfo%OPENFILE(my_filename,0,ok)
        if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
      endIf
      if(fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call fileinfo%OPENFILE(my_filename,0,ok)
        if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
      endIf
!
!     Set the readWriteMode flag in fileinfo to 'R' and then read the
!     header scalar flags.
!
      if(.not.fileinfo%header_read) then

        fileinfo%readWriteMode = 'R'
        call Open_Read(TRIM(fileinfo%filename),fileinfo%UnitNumber,  &
          fileinfo%labfil,ivers,nlab,fileinfo%gvers,fileinfo%title,  &
          fileinfo%natoms,fileinfo%nbasis,fileinfo%nbasisUse,  &
          fileinfo%icharge,fileinfo%multiplicity,fileinfo%nelectrons,len12l,  &
          len4l,iopcl,fileinfo%icgu)
        allocate(fileinfo%atomicNumbers(fileinfo%natoms),  &
          fileinfo%atomTypes(fileinfo%natoms),  &
          fileinfo%atomicCharges(fileinfo%natoms),  &
          fileinfo%atomicWeights(fileinfo%natoms))
        allocate(fileinfo%cartesians(fileinfo%natoms*3))
        allocate(fileinfo%basisFunction2Atom(fileinfo%NBasis),  &
          fileinfo%IBasisFunctionType(fileinfo%NBasis))
        call Rd_Head(fileinfo%unitNumber,NLab,fileinfo%natoms,fileinfo%nbasis,  &
          fileinfo%atomicNumbers,fileinfo%atomTypes,fileinfo%atomicCharges,  &
          fileinfo%cartesians,fileinfo%basisFunction2Atom,fileinfo%IBasisFunctionType,  &
          fileinfo%atomicWeights,fileinfo%NFC,fileinfo%NFV,fileinfo%ITran, &
          fileinfo%IDum9,fileinfo%NShlAO,fileinfo%NPrmAO,fileinfo%NShlDB,  &
          fileinfo%NPrmDB,fileinfo%NBTot)
        fileinfo%CurrentlyOpen = .true.
        fileinfo%header_read   = .true.
      endIf
      if(DEBUG) write(IOut,1010) TRIM(fileinfo%LabFil),IVers,NLab,  &
        TRIM(fileinfo%GVers),TRIM(fileinfo%Title),fileinfo%natoms,  &
        fileinfo%NBasis,fileinfo%nbasisUse,fileinfo%ICharge,  &
        fileinfo%Multiplicity,fileinfo%nelectrons,Len12L,Len4L,  &
        IOpCl,fileinfo%ICGU
!
      return
      end subroutine MQC_Gaussian_Unformatted_Matrix_Read_Header


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Write_Header
      subroutine MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
        filename)
!
!     This Routine is used to connect a Gaussian unformatted matrix file
!     and write the header records. The dummy argument <FileName> is an input
!     argument giving the the name of the file.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open may be called
!     before calling this routine. However, it is also OK to call this
!     routine first. In that case, this routine will first call
!     Routine MQC_Gaussian_Unformatted_Matrix_Open.

!     L. M. Thompson, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in),OPTIONAL::filename
!
      integer::iout=6
!
!     Temporary local variables used when calling the gauopen routines.
      integer::IOpCl=-1
      integer::NAt3,NFC,NFV,ITran,IDum9,NShlAO,NPrmAO,NShlDB,NPrmDB,NBTot
!
!     Local temp variables.
      character(len=256)::my_filename
      logical::DEBUG=.true.,ok
!
!
!     Format statements.
!
 1010 format(3x,' Label ',A,' Version=',A,  &
        /,3x,' Title ',A,  &
        /,3x,' NAtoms=',I6,' NBasis=',I6,' NBsUse=',I6,' ICharg=',I6,  &
        ' Multip=',I6,' NElec=',I6,' IOpCl=',I6,  &
        ' ICGU=',I3)
!
!
!     Begin by seeing if a new file or filename has been sent by the calling
!     program unit. If so, then get the file declared before writing the
!     header information.
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call fileinfo%OPENFILE(TRIM(filename),0,ok)
          if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
        else
          call MQC_Error('Error reading Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call fileinfo%OPENFILE(TRIM(filename),0,ok)
          if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'W' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call fileinfo%OPENFILE(my_filename,0,ok)
        if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
      endIf
      if(fileinfo%header_written) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call fileinfo%OPENFILE(my_filename,0,ok)
        if(.not.ok) Call MQC_Error('Error opening Gaussian matrix file.')
      endIf
!
!     Set the readWriteMode flag in fileinfo to 'W' and then write the
!     header scalar flags.
!
      fileinfo%readWriteMode = 'W'
      call Open_Write(TRIM(fileinfo%filename),fileinfo%UnitNumber,  &
        fileinfo%labfil,fileinfo%gvers,fileinfo%title,  &
        fileinfo%natoms,fileinfo%nbasis,fileinfo%nbasisUse,  &
        fileinfo%icharge,fileinfo%multiplicity,fileinfo%nelectrons,iopcl, &
        fileinfo%icgu)
      nAt3 = fileinfo%natoms*3
      NShlAO = 2
      NPrmAO = 6
      call Wr_Head(fileinfo%unitNumber,fileinfo%natoms,nAt3,fileinfo%nbasis,  &
        fileinfo%atomicNumbers,fileinfo%atomTypes,fileinfo%atomicCharges,  &
        fileinfo%cartesians,fileinfo%basisFunction2Atom,fileinfo%IBasisFunctionType,  &
        fileinfo%atomicWeights,fileinfo%NFC,fileinfo%NFV,fileinfo%ITran,fileinfo%IDum9, &
        fileinfo%NShlAO,fileinfo%NPrmAO,fileinfo%NShlDB,fileinfo%NPrmDB,fileinfo%NBTot)
      fileinfo%CurrentlyOpen = .true.
      fileinfo%header_written   = .true.
      
      if(DEBUG) write(IOut,1010) TRIM(fileinfo%LabFil),  &
        TRIM(fileinfo%GVers),TRIM(fileinfo%Title),fileinfo%natoms,  &
        fileinfo%NBasis,fileinfo%nbasisUse,fileinfo%ICharge,  &
        fileinfo%Multiplicity,fileinfo%nelectrons,  &
        IOpCl,fileinfo%ICGU
!
      return
      end subroutine MQC_Gaussian_Unformatted_Matrix_Write_Header


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Read_Array
      subroutine MQC_Gaussian_Unformatted_Matrix_Read_Array(fileinfo,  &
       label,matrixOut,vectorOut,r4TensorOut,filename)
!
!     This Routine is used to look-up a matrix in a unformatted matrix file load
!     that array into either (OPTIONAL) output dummy MQC_Matrix argument
!     <matrixOut>, (OPTIONAL) output dummy MQC_Vector argument <vectorOut>, or
!     (OPTIONAL) output dummy MQC_R4Tensor argument <r4TensorOut>. The character
!     label for the array of interest is sent to this routine in dummy argument
!     <label>.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open is meant to be
!     called before calling this routine. The expectation is that
!     MQC_Gaussian_Unformatted_Matrix_Read_Header is also called before this
!     routine. However, it is also OK to call this routine first. In that case,
!     this routine will first call Routine MQC_Gaussian_Unformatted_Matrix_Open.
!
!     H. P. Hratchian, 2017.
!     L. M. Thompson, 2017
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::label
      type(MQC_Matrix),intent(inout),OPTIONAL::matrixOut
      type(MQC_Vector),intent(inout),OPTIONAL::vectorOut
      type(MQC_R4Tensor),intent(inout),OPTIONAL::r4TensorOut
      character(len=*),intent(in),OPTIONAL::filename
!
      integer::iout=6
!
!     Temporary local variables used when calling the gauopen routines.
      integer::IVers,NI,NR,NTot,LenBuf,N1,N2,N3,N4,N5,NRI,LR
      character(len=64)::cBuffer,tmpLabel
      logical::EOF,ASym
!
!     Local temp variables.
      integer::i,nOutputArrays
      integer,external::LenArr
      integer,allocatable,dimension(:)::integerTmp
      real,allocatable,dimension(:)::arrayTmp
      complex,allocatable,dimension(:)::complexTmp
      character(len=256)::my_filename,errorMsg
      logical::DEBUG=.true.,ok,found
!
!
!     Format statements.
!
 1010 format(' Label ',A48,' NI=',I2,' NR=',I2,' NRI=',I1,' NTot=',  &
        I8,' LenBuf=',I8,' N=',5I6,' ASym=',L1,' LR=',I5)
!
!
!     Begin by seeing if a new file or filename has been sent by the calling
!     program unit. If so, then get the file declared before reading the
!     header information.
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
            filename)
        else
          call MQC_Error('Error reading Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
            filename)
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'R' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          filename)
      endIf
      if(.not.fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Ensure that one and only one output MQC-type array has been sent from the
!     calling program unit.
!
      nOutputArrays = 0
      if(Present(matrixOut)) nOutputArrays = nOutputArrays+1
      if(Present(vectorOut)) nOutputArrays = nOutputArrays+1
      if(Present(r4TensorOut)) nOutputArrays = nOutputArrays+1
      if(nOutputArrays.ne.1) call mqc_error('Too many output arrays sent to Gaussian matrix file reading procedure.')
!
!     Look for the label sent by the calling program unit. If the label is
!     found, then load <matrixOut> with the data on the file.
!
      found = .false.
      outerLoop:do i = 1,2
        call String_Change_Case(label,'u',tmpLabel)
        EOF = .false.
        Call Rd_Labl(fileinfo%UnitNumber,IVers,cBuffer,NI,NR,NTot,LenBuf,  &
          N1,N2,N3,N4,N5,ASym,NRI,EOF)
        LR = LenArr(N1,N2,N3,N4,N5)
        if(DEBUG) write(IOut,1010) TRIM(cBuffer),NI,NR,NRI,NTot,LenBuf,  &
          N1,N2,N3,N4,N5,ASym,LR
        do while(.not.EOF)
          call String_Change_Case(cBuffer,'u')
          if(TRIM(tmpLabel) == TRIM(cBuffer)) then
            select case(MQC_Gaussian_Unformatted_Matrix_Array_Type(NI,NR,N1,N2,N3,N4,N5,NRI))

            case('INTEGER-VECTOR')
              allocate(integerTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,integerTmp)
              if(Present(vectorOut)) then
                vectorOut = integerTmp
              elseIf(Present(matrixOut)) then
                call MQC_Matrix_DiagMatrix_Put(matrixOut,integerTmp)
              else
                if(.not.Present(matrixOut)) call mqc_error('Reading vector from Gaussian matrix file, but NO VECTOR SENT to &
                  & procedure.')
              endIf
              deallocate(integerTmp)
            case('INTEGER-MATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix file, but NO MATRIX SENT to &
                & procedure.')
              allocate(integerTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,integerTmp)
              matrixOut = Reshape(integerTmp,[N1,N2])
              deallocate(integerTmp)
            case('INTEGER-SYMMATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix file, but NO MATRIX SENT to &
                & procedure.')
              allocate(integerTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,integerTmp)
              call MQC_Matrix_SymmMatrix_Put(matrixOut,integerTmp)
              deallocate(integerTmp)

            case('REAL-VECTOR')
              allocate(arrayTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,arrayTmp)
              if(Present(vectorOut)) then
                vectorOut = arrayTmp
              elseIf(Present(matrixOut)) then
                call MQC_Matrix_DiagMatrix_Put(matrixOut,arrayTmp)
              else
                if(.not.Present(matrixOut)) call mqc_error('Reading vector from Gaussian matrix file, but NO VECTOR SENT to &
                  & procedure.')
              endIf
              deallocate(arrayTmp)
            case('REAL-MATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix file, but NO MATRIX SENT to &
                & procedure.')
              allocate(arrayTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,arrayTmp)
              matrixOut = Reshape(arrayTmp,[N1,N2])
              deallocate(arrayTmp)
            case('REAL-SYMMATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix file, but NO MATRIX SENT to &
                & procedure.')
              allocate(arrayTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,NTot,LenBuf,arrayTmp)
              call MQC_Matrix_SymmMatrix_Put(matrixOut,arrayTmp)
              deallocate(arrayTmp)

            case('COMPLEX-VECTOR')
              allocate(complexTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,2*NTot,2*LenBuf,complexTmp)
              if(Present(vectorOut)) then
                vectorOut = complexTmp
              elseIf(Present(matrixOut)) then
                call MQC_Matrix_DiagMatrix_Put(matrixOut,complexTmp)
              else
                call mqc_error('Reading vector from Gaussian matrix file, but NO VECTOR SENT &
                  & to procedure.')
              endIf
              deallocate(complexTmp)
            case('COMPLEX-MATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix &
                & file, but NO MATRIX SENT to procedure.')
              allocate(complexTmp(LR))
              write(*,*) 'reading matrix'
              call Rd_RBuf(fileinfo%unitNumber,2*NTot,2*LenBuf,complexTmp)
              write(*,*) 'read matrix'
              matrixOut = Reshape(complexTmp,[N1,N2])
              deallocate(complexTmp)
            case('COMPLEX-SYMMATRIX')
              if(.not.Present(matrixOut)) call mqc_error('Reading matrix from Gaussian matrix &
                & file, but NO MATRIX SENT to procedure.')
              allocate(complexTmp(LR))
              call Rd_RBuf(fileinfo%unitNumber,2*NTot,2*LenBuf,complexTmp)
              call MQC_Matrix_SymmMatrix_Put(matrixOut,complexTmp)
              deallocate(complexTmp)

            case('MIXED')
              write(*,*)
              write(*,*)' Hrant - LR   = ',LR
              write(*,*)' Hrant - NR   = ',NR
              write(*,*)' Hrant - NI   = ',NI
              write(*,*)' Hrant - NRI  = ',NRI
              write(*,*)' Hrant - NTot = ',NTot
              write(*,*)
              call mqc_error('No general way to load mixed types as of yet &
      &         We are doing it case-by-case at the moment and this does not match.')

            case('2ERIS-SYMSYMR4TENSOR')
              if(.not.Present(r4TensorOut)) call mqc_error('Reading r4 tensor from Gaussian matrix file, but NO R4TENSOR SENT to &
                & procedure.')
              if(NRI.eq.1) then
                allocate(arrayTmp(LR))
                call Rd_2EN(fileinfo%unitNumber,NR,LR,NR*LR,NTot,LenBuf,arrayTmp)
                call MQC_Matrix_SymmSymmR4Tensor_Put_Real(r4TensorOut,arrayTmp)
                deallocate(arrayTmp)
              elseIf(NRI.eq.2) then
                allocate(complexTmp(LR))
                call Rd_2EN(fileinfo%unitNumber,NR,LR,NR*LR,2*NTot,2*LenBuf,complexTmp)
                call MQC_Matrix_SymmSymmR4Tensor_Put_Complex(r4TensorOut,complexTmp)
                deallocate(complexTmp)
              endIf

            case default
              write(*,*)' Matrix type: ',Trim(MQC_Gaussian_Unformatted_Matrix_Array_Type(NI,NR,N1,N2,N3,N4,N5,NRI))
              call mqc_error('Found strange matrix type in Gaussian matrix read routine.')
            end select
            found = .true.
            exit outerLoop
          else
            Call Rd_Skip(fileinfo%UnitNumber,NTot,LenBuf)
          endIf
          Call Rd_Labl(fileinfo%UnitNumber,IVers,cBuffer,NI,NR,NTot,LenBuf,  &
            N1,N2,N3,N4,N5,ASym,NRI,EOF)
          LR = LenArr(N1,N2,N3,N4,N5)
          if(DEBUG) write(IOut,1010) TRIM(cBuffer),NI,NR,NRI,NTot,LenBuf,  &
            N1,N2,N3,N4,N5,ASym,LR
        endDo
        if(i==1) then
          my_filename = TRIM(fileinfo%filename)
          call fileinfo%CLOSEFILE()
          call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
            my_filename)
        endIf
      endDo outerLoop
      if(.not.found) then
        errorMsg = 'Could NOT find requested matrix file label "'//TRIM(label)//'".'
        call MQC_Error(errorMsg)
      endIf
!
      return
      end subroutine MQC_Gaussian_Unformatted_Matrix_Read_Array


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Write_Array
      subroutine MQC_Gaussian_Unformatted_Matrix_Write_Array(fileinfo,  &
       label,matrixIn,vectorIn,r4TensorIn,filename)
!
!     This Routine is used to look-up a matrix in a unformatted matrix file and
!     write that array into either (OPTIONAL) output dummy MQC_Matrix argument
!     <matrixIn>, (OPTIONAL) output dummy MQC_Vector argument <vectorIn>, or
!     (OPTIONAL) output dummy MQC_R4Tensor argument <r4TensorIn>. The character
!     label for the array of interest is sent to this routine in dummy argument
!     <label>.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open is meant to be
!     called before calling this routine. The expectation is that
!     MQC_Gaussian_Unformatted_Matrix_Write_Header is also called before this
!     routine. However, it is also OK to call this routine first. In that case,
!     this routine will first call Routine MQC_Gaussian_Unformatted_Matrix_Open.
!
!     L. M. Thompson, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::label
      type(MQC_Matrix),intent(in),OPTIONAL::matrixIn 
      type(MQC_Vector),intent(in),OPTIONAL::vectorIn 
      type(MQC_R4Tensor),intent(in),OPTIONAL::r4TensorIn 
      character(len=*),intent(in),OPTIONAL::filename
!
      integer::iout=6
!
!     Temporary local variables used when calling the gauopen routines.
      integer::LenBuf
      character(len=64)::tmpLabel
!
!     Local temp variables.
      integer::i,nInputArrays
      real,allocatable,dimension(:,:)::realMatrixTmp
      integer,allocatable,dimension(:,:)::intMatrixTmp
      complex(kind=8),allocatable,dimension(:,:)::compMatrixTmp
      real,allocatable,dimension(:)::realVectorTmp
      integer,allocatable,dimension(:)::intVectorTmp
      complex(kind=8),allocatable,dimension(:)::compVectorTmp
      type(MQC_Matrix)::matrixInUse 
      character(len=256)::my_filename
      logical::DEBUG=.false.
      Parameter(LenBuf=4000)
!
!
!     Format statements.
!
 1010 format(' Label ',A48,' NI=',I2,' NR=',I2,' NRI=',I1,' NTot=',  &
        I8,' LenBuf=',I8,' N=',5I6,' ASym=',L1,' LR=',I5)
!
!
!     Begin by seeing if a new file or filename has been sent by the calling
!     program unit. If file has not been opened or there is no header data,
!     read the header data. If file is not in write mode, write the header
!     data and set to write mode
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
            filename)
        else
          call MQC_Error('Error writing Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
            filename)
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'W' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
          filename)
      endIf
      if(.not.fileinfo%header_written) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Ensure that one and only one input MQC-type array has been sent from the
!     calling program unit.
!
      nInputArrays = 0
      if(Present(matrixIn)) nInputArrays = nInputArrays+1
      if(Present(vectorIn)) nInputArrays = nInputArrays+1
      if(Present(r4TensorIn)) nInputArrays = nInputArrays+1
      if(nInputArrays.ne.1) call mqc_error('Too many input arrays sent to Gaussian matrix file writing procedure.')
!
!     Load the MQC variable into a regular array and get the required dimensions
!     Some routines will change when we upgrade to algebra2
!
      call String_Change_Case(label,'u',tmpLabel)
      if(present(matrixIn)) then
        matrixInUse = matrixIn
        if(mqc_matrix_haveReal(matrixInUse)) then 
          if(mqc_matrix_test_diagonal(matrixInUse)) then
            if(.not.mqc_matrix_haveDiagonal(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Diag(matrixInUse)
              if(mqc_matrix_haveSymmetric(matrixInUse)) call mqc_matrix_symm2Diag(matrixInUse)
            endIf
            if(mqc_matrix_rows(matrixInUse).lt.mqc_matrix_columns(matrixInUse)) then
              allocate(realMatrixTmp(mqc_matrix_rows(matrixInUse),1))
            else
              allocate(realMatrixTmp(mqc_matrix_columns(matrixInUse),1))
            endIf
            realMatrixTmp = matrixInUse
            call wr_LRBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,size(realMatrixTmp,1), &
              0,0,0,0,.False.,realMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse)) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(realMatrixTmp((mqc_matrix_rows(matrixInUse)*(mqc_matrix_rows(matrixInUse)+1))/2,1))
            realMatrixTmp = matrixInUse
            call wr_LRBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,realMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse,'antisymmetric')) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(realMatrixTmp((mqc_matrix_rows(matrixInUse)*(mqc_matrix_rows(matrixInUse)+1))/2,1))
            realMatrixTmp = matrixInUse
            call wr_LRBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.True.,realMatrixTmp)
          elseIf(mqc_matrix_haveFull(matrixInUse)) then
            allocate(realMatrixTmp(mqc_matrix_rows(matrixInUse),mqc_matrix_columns(matrixInUse)))
            realMatrixTmp = matrixInUse
            call wr_LRBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,realMatrixTmp)
          else
            call mqc_error('type not recognised') 
          endIf
        elseIf(mqc_matrix_haveInteger(matrixInUse)) then 
          if(mqc_matrix_test_diagonal(matrixInUse)) then
            if(.not.mqc_matrix_haveDiagonal(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Diag(matrixInUse)
              if(mqc_matrix_haveSymmetric(matrixInUse)) call mqc_matrix_symm2Diag(matrixInUse)
            endIf
            if(mqc_matrix_rows(matrixInUse).lt.mqc_matrix_columns(matrixInUse)) then
              allocate(intMatrixTmp(mqc_matrix_rows(matrixInUse),1))
            else
              allocate(intMatrixTmp(mqc_matrix_columns(matrixInUse),1))
            endIf
            intMatrixTmp = matrixInUse
            call wr_LIBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,size(intMatrixTmp,1), &
              0,0,0,0,.False.,intMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse)) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(intMatrixTmp((mqc_matrix_rows(matrixInUse)*(mqc_matrix_rows(matrixInUse)+1))/2,1))
            intMatrixTmp = matrixInUse
            call wr_LIBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,intMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse,'antisymmetric')) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(intMatrixTmp((mqc_matrix_rows(matrixInUse)*(mqc_matrix_rows(matrixInUse)+1))/2,1))
            intMatrixTmp = matrixInUse
            call wr_LIBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.True.,intMatrixTmp)
          elseIf(mqc_matrix_haveFull(matrixInUse)) then
            allocate(intMatrixTmp(mqc_matrix_rows(matrixInUse),mqc_matrix_columns(matrixInUse)))
            intMatrixTmp = matrixInUse
            call wr_LIBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,intMatrixTmp)
          else
            call mqc_error('type not recognised') 
          endIf
        elseIf(mqc_matrix_haveComplex(matrixInUse)) then 
          if(mqc_matrix_test_diagonal(matrixInUse)) then
            if(.not.mqc_matrix_haveDiagonal(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Diag(matrixInUse)
              if(mqc_matrix_haveSymmetric(matrixInUse)) call mqc_matrix_symm2Diag(matrixInUse)
            endIf
            if(mqc_matrix_rows(matrixInUse).lt.mqc_matrix_columns(matrixInUse)) then
              allocate(compMatrixTmp(mqc_matrix_rows(matrixInUse),1))
            else
              allocate(compMatrixTmp(mqc_matrix_columns(matrixInUse),1))
            endIf
            compMatrixTmp = matrixInUse
            call wr_LCBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,size(compMatrixTmp,1), &
              0,0,0,0,.False.,compMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse)) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(compMatrixTmp(mqc_matrix_rows(matrixInUse),mqc_matrix_columns(matrixInUse)))
            compMatrixTmp = matrixInUse
            call wr_LCBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,compMatrixTmp)
          elseIf(mqc_matrix_test_symmetric(matrixInUse,'hermitian')) then
            if(.not.mqc_matrix_haveSymmetric(matrixInUse)) then
              if(mqc_matrix_haveFull(matrixInUse)) call mqc_matrix_full2Symm(matrixInUse)
              if(mqc_matrix_haveDiagonal(matrixInUse)) call mqc_matrix_diag2Symm(matrixInUse)
            endIf
            allocate(compMatrixTmp(mqc_matrix_rows(matrixInUse),mqc_matrix_columns(matrixInUse)))
            compMatrixTmp = matrixInUse
            call wr_LCBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,-mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.True.,compMatrixTmp)
          elseIf(mqc_matrix_haveFull(matrixInUse)) then
            allocate(compMatrixTmp(mqc_matrix_rows(matrixInUse),mqc_matrix_columns(matrixInUse)))
            compMatrixTmp = matrixInUse
            call wr_LCBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_matrix_rows(matrixInUse), &
              mqc_matrix_columns(matrixInUse),0,0,0,.False.,compMatrixTmp)
          else
            call mqc_error('type not recognised') 
          endIf
        else
          call mqc_error('MatrixIn type not recognised in &
     &      MQC_Gaussian_Unformatted_Matrix_Write_Array')
        endIf
      elseIf(present(vectorIn)) then
        if(mqc_vector_haveReal(vectorIn)) then 
          allocate(realVectorTmp(mqc_length_vector(vectorIn)))
          realVectorTmp = vectorIn
          call wr_LRBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_length_vector(vectorIn), &
            0,0,0,0,.False.,realVectorTmp)
        elseIf(mqc_vector_haveInteger(vectorIn)) then 
          allocate(intVectorTmp(mqc_length_vector(vectorIn)))
          intVectorTmp = vectorIn
          call wr_LIBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_length_vector(vectorIn), &
            0,0,0,0,.False.,intVectorTmp)
        elseIf(mqc_vector_haveComplex(vectorIn)) then 
          allocate(compVectorTmp(mqc_length_vector(vectorIn)))
          compVectorTmp = vectorIn
          call wr_LCBuf(fileinfo%UnitNumber,tmpLabel,1,LenBuf,mqc_length_vector(vectorIn), &
            0,0,0,0,.False.,compVectorTmp)
        else
          call mqc_error('VectorIn type not recognised in &
     &      MQC_Gaussian_Unformatted_Matrix_Write_Array')
        endIf
      endIf
!
      return
      end subroutine MQC_Gaussian_Unformatted_Matrix_Write_Array
!
!
!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info
      Function MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info(fileinfo,element,label)
!
!     This function is used to get info about specific atom information
!     associated with the Gaussian unformatted matrix file sent in object
!     fileinfo.
!
!     Input argument element refers to a specific atom in the molecule some
!     other element related to the info requested by input argument label.
!
!     The recognized labels and their meaning include:
!           'nuclearCharge'   return the atomic charge of atom number <element>.
!
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      integer::element
      character(len=*),intent(in)::label
      integer::MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info
      integer::value_out=0
      character(len=64)::myLabel
      character(len=256)::my_filename
!
!
!     Ensure the matrix file has already been opened and the header read.
!
      if(.not.fileinfo%isOpen())  &
        call MQC_Error('Failed to retrieve atom info from Gaussian matrix file: File not open.')
      if(.not.fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Do the work...
!
      call String_Change_Case(label,'l',myLabel)
      select case (mylabel)
      case('atomiccharge','nuclearcharge')
        if((element.le.0).or.(element.gt.fileinfo%natoms))  &
          call MQC_Error('element to %getAtomInfo is invalid.')
        value_out = fileinfo%atomicCharges(element)
      case default
        call mqc_error('Invalid label sent to %getAtomInfo.')
      endSelect
!
      MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info = value_out
      return
      end Function MQC_Gaussian_Unformatted_Matrix_Get_Atom_Info


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info
      Function MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info(fileinfo,element,label)
!
!     This function is used to get info about specific basis functions
!     associated with the Gaussian unformatted matrix file sent in object
!     fileinfo.
!
!     Input argument element refers to a specific basis function by number or
!     some other element related to the info requested by input argument label.
!
!     The recognized labels and their meaning include:
!           'basis2Atom'      return the atomic center number on which basis
!                             function <element> is centered.
!           'basis type'      return the atomic orbital basis type of basis
!                             function <element> as numerical label. 
!
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      integer::element
      character(len=*),intent(in)::label
      integer::MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info
      integer::value_out=0
      character(len=64)::myLabel
      character(len=256)::my_filename
!
!
!     Ensure the matrix file has already been opened and the header read.
!
      if(.not.fileinfo%isOpen())  &
        call MQC_Error('Failed to retrieve basis info from Gaussian matrix file: File not open.')
      if(.not.fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Do the work...
!
      call String_Change_Case(label,'l',myLabel)
      select case (mylabel)
      case('basis2atom')
        if(.not.allocated(fileinfo%basisFunction2Atom))  &
          call MQC_Error('Requested basis2Atom not possible.')
        if((element.le.0).or.(element.gt.fileinfo%nbasis))  &
          call MQC_Error('element to %getBasisInfo is invalid.')
        value_out = fileinfo%basisFunction2Atom(element)
      case('basis type')
        if(.not.allocated(fileinfo%IBasisFunctionType))  &
          call MQC_Error('Requested basis type not possible.')
        if((element.le.0).or.(element.gt.fileinfo%nbasis))  &
          call MQC_Error('element to %getBasisInfo is invalid.')
        value_out = fileinfo%IBasisFunctionType(element)
      case default
        call mqc_error('Invalid label sent to %getBasisInfo.')
      endSelect
!
      MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info = value_out
      return
      end Function MQC_Gaussian_Unformatted_Matrix_Get_Basis_Info


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Write_EST_Object
      subroutine mqc_gaussian_unformatted_matrix_write_EST_object(fileinfo,label, &
        est_wavefunction,est_integral,est_eigenvalues,filename,override)
!
!     THIS SHOULD BE GAU_GET_EST_OBJ AND WE SHOULD HAVE A GENERAL ROUTINE IN EST OBJ
!     THAT CALLS THIS IF WE HAVE A GAUSSIAN FILE

!     This subroutine writes the desired MQC EST integral object as specified by
!     input argument <label> to a Gaussian unformatted matrix file sent in 
!     object <fileinfo>. The relevant information will be loaded from either 
!     (OPTIONAL) output dummy MQC_Wavefunction argument <est_wavefunction>, 
!     (OPTIONAL) output dummy MQC_SCF_Integral argument <est_integral>, 
!     (OPTIONAL) output dummy MQC_SCF_Eigenvalues argument <est_eigenvalues>.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     Dummy argument <override> is optional and can be used to write the EST
!     object as a particular wavefunction type (space, spin or general being 
!     the options). NOTE WE WILL WANT SOMETHING LIKE THIS FOR REAL AND COMPLEX 
!     WHEN MQC ALGEBRA HAS IT IMPLEMENTED.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open is meant to be
!     called before calling this routine. The expectation is that
!     MQC_Gaussian_Unformatted_Matrix_Write_Header is also called before this
!     routine. However, it is also OK to call this routine first. In that case,
!     this routine will first call Routine MQC_Gaussian_Unformatted_Matrix_Open.
!
!     The recognized labels and their meaning include:
!           'mo coefficients'    write the molecular orbital coefficients.
!           'mo energies'        write the molecular orbital energies.
!           'mo symmetries'      write the irreducible representation associated 
!                                  with each molecular orbital.*
!           'core hamiltonian'   write the core hamiltonian.
!           'fock'               write the fock matrix.
!           'density'            write the density matrix.
!           'overlap'            write the overlap matrix.
!           'wavefunction'       export the wavefunction object.
!
!     * not yet implemented
!
!     L. M. Thompson, 2017.
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::label
      type(mqc_wavefunction),optional::est_wavefunction
      type(mqc_scf_integral),optional::est_integral
      type(mqc_scf_eigenvalues),optional::est_eigenvalues
      character(len=*),intent(in),optional::filename,override
      character(len=64)::myLabel
      character(len=256)::my_filename,my_override,my_integral_type
      integer::nInputArrays,nBasis,nAlpha,nBeta
      type(mqc_matrix)::tmpMatrix
      type(mqc_vector)::tmpVector
      type(mqc_scalar)::tmpScalar
!
!
!     Ensure the matrix file has already been opened and the header read.
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
            filename)
        else
          call MQC_Error('Error reading Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
            filename)
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'W' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
          filename)
      endIf
      if(.not.fileinfo%header_written) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Write_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Ensure that one and only one output MQC-type array has been sent from the
!     calling program unit.
!
      nInputArrays = 0
      if(Present(est_wavefunction)) nInputArrays = nInputArrays+1
      if(Present(est_integral)) nInputArrays = nInputArrays+1
      if(Present(est_eigenvalues)) nInputArrays = nInputArrays+1
      if(nInputArrays.ne.1) call mqc_error('Too many input arrays sent to Gaussian matrix file reading procedure.')
!
!     Get the EST object in the desired wavefunction type format
!
      if(present(override)) then
        call String_Change_Case(override,'l',my_override)
        if(present(est_wavefunction)) call mqc_error('Overriding wavefunction types not implemented') 
        if(my_override.eq.'space') then
          my_integral_type = 'space'
        elseIf(my_override.eq.'spin') then
          my_integral_type = 'spin'
        elseIf(my_override.eq.'general') then
          my_integral_type = 'general'
        else
          call mqc_error('Unrecognised override type in %writeESTObj')
        endIf
      else
        if(present(est_integral)) then
          my_integral_type = mqc_integral_array_type(est_integral)
        elseIf(present(est_eigenvalues)) then
          my_integral_type = mqc_eigenvalues_array_type(est_eigenvalues)
        endIf
      endIf
!
!     Do the work...
!
      call String_Change_Case(label,'l',myLabel)
      select case (mylabel)
      case('mo coefficients')
        if(.not.(Present(est_integral))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS', &
            matrixIn=est_integral%getBlock('alpha'))
          call fileInfo%writeArray('BETA MO COEFFICIENTS', &
            matrixIn=est_integral%getBlock('beta'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_integral,tmpMatrix)
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case('mo energies')
        if(.not.(Present(est_eigenvalues))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('ALPHA ORBITAL ENERGIES', &
            vectorIn=est_eigenvalues%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('ALPHA ORBITAL ENERGIES', &
            vectorIn=est_eigenvalues%getBlock('alpha'))
          call fileInfo%writeArray('BETA ORBITAL ENERGIES', &
            vectorIn=est_eigenvalues%getBlock('beta'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_eigenvalues,tmpVector)
          call fileInfo%writeArray('ALPHA ORBITAL COEFFICIENTS',vectorIn=tmpVector)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('core hamiltonian')
        if(.not.(Present(est_integral))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA', &
            matrixIn=est_integral%getBlock('alpha'))
          call fileInfo%writeArray('CORE HAMILTONIAN BETA', &
            matrixIn=est_integral%getBlock('beta'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_integral,tmpMatrix)
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case('fock')
        if(.not.(Present(est_integral))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('ALPHA FOCK MATRIX', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('ALPHA FOCK MATRIX', &
            matrixIn=est_integral%getBlock('alpha'))
          call fileInfo%writeArray('BETA FOCK MATRIX', &
            matrixIn=est_integral%getBlock('beta'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_integral,tmpMatrix)
          call fileInfo%writeArray('ALPHA FOCK MATRIX',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case('density')
        if(.not.(Present(est_integral))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX', &
            matrixIn=est_integral%getBlock('alpha'))
          call fileInfo%writeArray('BETA SCF DENSITY MATRIX', &
            matrixIn=est_integral%getBlock('beta'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_integral,tmpMatrix)
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case('overlap')
        if(.not.(Present(est_integral))) call mqc_error('wrong EST type in writeESTOBj')
        if(my_integral_type.eq.'space') then
          call fileInfo%writeArray('OVERLAP', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'spin') then
          call fileInfo%writeArray('OVERLAP', &
            matrixIn=est_integral%getBlock('alpha'))
        elseIf(my_integral_type.eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_integral,tmpMatrix)
          call fileInfo%writeArray('OVERLAP',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case('wavefunction')
        if(.not.(Present(est_wavefunction))) call mqc_error('wrong EST type in writeESTOBj')
        if(mqc_integral_array_type(est_wavefunction%overlap_matrix).eq.'space') then
          call fileInfo%writeArray('OVERLAP', &
            matrixIn=est_wavefunction%overlap_matrix%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%overlap_matrix).eq.'spin') then
          call fileInfo%writeArray('OVERLAP', &
            matrixIn=est_wavefunction%overlap_matrix%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%overlap_matrix).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%overlap_matrix,tmpMatrix)
          call fileInfo%writeArray('OVERLAP',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
        if(mqc_integral_array_type(est_wavefunction%core_hamiltonian).eq.'space') then
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA', &
            matrixIn=est_wavefunction%core_hamiltonian%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%core_hamiltonian).eq.'spin') then
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA', &
            matrixIn=est_wavefunction%core_hamiltonian%getBlock('alpha'))
          call fileInfo%writeArray('CORE HAMILTONIAN BETA', &
            matrixIn=est_wavefunction%core_hamiltonian%getBlock('beta'))
        elseIf(mqc_integral_array_type(est_wavefunction%core_hamiltonian).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%core_hamiltonian,tmpMatrix)
          call fileInfo%writeArray('CORE HAMILTONIAN ALPHA',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
        if(mqc_eigenvalues_array_type(est_wavefunction%mo_energies).eq.'space') then
          call fileInfo%writeArray('ALPHA ORBITAL ENERGIES', &
            vectorIn=est_wavefunction%mo_energies%getBlock('alpha'))
        elseIf(mqc_eigenvalues_array_type(est_wavefunction%mo_energies).eq.'spin') then
          call fileInfo%writeArray('ALPHA ORBITAL ENERGIES', &
            vectorIn=est_wavefunction%mo_energies%getBlock('alpha'))
          call fileInfo%writeArray('BETA ORBITAL ENERGIES', &
            vectorIn=est_wavefunction%mo_energies%getBlock('beta'))
        elseIf(mqc_eigenvalues_array_type(est_wavefunction%mo_energies).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%mo_energies,tmpVector)
          call fileInfo%writeArray('ALPHA ORBITAL ENERGIES',vectorIn=tmpVector)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
        if(mqc_integral_array_type(est_wavefunction%mo_coefficients).eq.'space') then
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS', &
            matrixIn=est_wavefunction%mo_coefficients%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%mo_coefficients).eq.'spin') then
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS', &
            matrixIn=est_wavefunction%mo_coefficients%getBlock('alpha'))
          call fileInfo%writeArray('BETA MO COEFFICIENTS', &
            matrixIn=est_wavefunction%mo_coefficients%getBlock('beta'))
        elseIf(mqc_integral_array_type(est_wavefunction%mo_coefficients).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%mo_coefficients,tmpMatrix)
          call fileInfo%writeArray('ALPHA MO COEFFICIENTS',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
        if(mqc_integral_array_type(est_wavefunction%density_matrix).eq.'space') then
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX', &
            matrixIn=est_wavefunction%density_matrix%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%density_matrix).eq.'spin') then
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX', &
            matrixIn=est_wavefunction%density_matrix%getBlock('alpha'))
          call fileInfo%writeArray('BETA SCF DENSITY MATRIX', &
            matrixIn=est_wavefunction%density_matrix%getBlock('beta'))
        elseIf(mqc_integral_array_type(est_wavefunction%density_matrix).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%density_matrix,tmpMatrix)
          call fileInfo%writeArray('ALPHA SCF DENSITY MATRIX',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
        if(mqc_integral_array_type(est_wavefunction%fock_matrix).eq.'space') then
          call fileInfo%writeArray('ALPHA FOCK MATRIX', &
            matrixIn=est_wavefunction%fock_matrix%getBlock('alpha'))
        elseIf(mqc_integral_array_type(est_wavefunction%fock_matrix).eq.'spin') then
          call fileInfo%writeArray('ALPHA FOCK MATRIX', &
            matrixIn=est_wavefunction%fock_matrix%getBlock('alpha'))
          call fileInfo%writeArray('BETA FOCK MATRIX', &
            matrixIn=est_wavefunction%fock_matrix%getBlock('beta'))
        elseIf(mqc_integral_array_type(est_wavefunction%fock_matrix).eq.'general') then
          call mqc_matrix_undoSpinBlockGHF(est_wavefunction%fock_matrix,tmpMatrix)
          call fileInfo%writeArray('ALPHA FOCK MATRIX',matrixIn=tmpMatrix)
        else
          call mqc_error('Unknown wavefunction type in writeESTObj')
        endIf
      case default
        call mqc_error('Invalid label sent to %writeESTObj.')
      end select
!
      return
!
      end subroutine MQC_Gaussian_Unformatted_Matrix_Write_EST_Object 
!
!
!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Get_EST_Object
      subroutine mqc_gaussian_unformatted_matrix_get_EST_object(fileinfo,label, &
        est_wavefunction,est_integral,est_eigenvalues,filename)
!
!     IS IT POSSIBLE TO MAKE THIS GAU_GET_EST_OBJ AND MAKE A GENERAL ROUTINE IN 
!     EST OBJ THAT CALLS THIS IF WE HAVE A GAUSSIAN FILE? AS FAR AS I CAN TELL
!     WE CAN'T AS THIS REQUIRES MQC_EST TO CALL HIGHER LEVEL MODULES.
!
!     This subroutine loads the desired MQC EST integral object as specified by
!     input argument <label> from a Gaussian unformatted matrix file sent in 
!     object <fileinfo>. The relevant information will be loaded into either 
!     (OPTIONAL) output dummy MQC_Wavefunction argument <est_wavefunction>, 
!     (OPTIONAL) output dummy MQC_SCF_Integral argument <est_integral>, 
!     (OPTIONAL) output dummy MQC_SCF_Eigenvalues argument <est_eigenvalues>, or 
!     (OPTIONAL) output dummy MQC_Scalar argument <scalarOut>, or 
!     (OPTIONAL) output dummy character argument <characterOut>, or 
!     (OPTIONAL) output dummy logical argument <logicalOut>.
!
!     Dummy argument <filename> is optional and is only used if fileinfo
!     hasn't already been defined using Routine
!     MQC_Gaussian_Unformatted_Matrix_Open or if it is determined that the
!     filename sent is different from the filename associated with object
!     fileinfo.
!
!     NOTE: The routine MQC_Gaussian_Unformatted_Matrix_Open is meant to be
!     called before calling this routine. The expectation is that
!     MQC_Gaussian_Unformatted_Matrix_Read_Header is also called before this
!     routine. However, it is also OK to call this routine first. In that case,
!     this routine will first call Routine MQC_Gaussian_Unformatted_Matrix_Open.
!
!     The recognized labels and their meaning include:
!           'mo coefficients'    return the molecular orbital coefficients.
!           'mo energies'        return the molecular orbital energies.
!           'mo symmetries'      return the irreducible representation associated 
!                                  with each molecular orbital.*
!           'core hamiltonian'   return the core hamiltonian.
!           'fock'               return the fock matrix.
!           'density'            return the density matrix.
!           'overlap'            return the overlap matrix.
!           'wavefunction'       load the wavefunction object.
!
!     * not yet implemented
!
!     L. M. Thompson, 2017.
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::label
      type(mqc_wavefunction),optional::est_wavefunction
      type(mqc_scf_integral),optional::est_integral
      type(mqc_scf_eigenvalues),optional::est_eigenvalues
      character(len=*),intent(in),optional::filename
      character(len=64)::myLabel
      character(len=256)::my_filename
      integer::nOutputArrays,nBasis,nAlpha,nBeta
      type(mqc_matrix)::tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha
      type(mqc_vector)::tmpVectorAlpha,tmpVectorBeta
      type(mqc_scalar)::tmpScalar
!
!
!     Ensure the matrix file has already been opened and the header read.
!
      if(.not.fileinfo%isOpen()) then
        if(PRESENT(filename)) then
          call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
            filename)
        else
          call MQC_Error('Error reading Gaussian matrix file header: Must include a filename.')
        endIf
      endIf
      if(PRESENT(filename)) then
        if(TRIM(filename)/=TRIM(fileinfo%filename)) then
          call fileinfo%CLOSEFILE()
          call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
            filename)
        endIf
      endIf
      if(.not.(fileinfo%readWriteMode .eq. 'R' .or.  &
        fileinfo%readWriteMode .eq. ' ')) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          filename)
      endIf
      if(.not.fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Ensure that one and only one output MQC-type array has been sent from the
!     calling program unit.
!
      nOutputArrays = 0
      if(Present(est_wavefunction)) nOutputArrays = nOutputArrays+1
      if(Present(est_integral)) nOutputArrays = nOutputArrays+1
      if(Present(est_eigenvalues)) nOutputArrays = nOutputArrays+1
      if(nOutputArrays.ne.1) call mqc_error('Too many output arrays sent to Gaussian matrix file reading procedure.')
!
!     Do the work...
!
      call String_Change_Case(label,'l',myLabel)
      select case (mylabel)
      case('mo coefficients')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'mo coefficients','space',tmpMatrixAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          call fileInfo%getArray('BETA MO COEFFICIENTS',tmpMatrixBeta)
          call mqc_integral_allocate(est_integral,'mo coefficients','spin',tmpMatrixAlpha, &
            tmpMatrixBeta)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_integral,'mo coefficients','general',tmpMatrixAlpha, &
            tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('mo energies')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          call mqc_eigenvalues_allocate(est_eigenvalues,'mo energies','space',tmpVectorAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          call fileInfo%getArray('BETA ORBITAL ENERGIES',vectorOut=tmpVectorBeta)
          call mqc_eigenvalues_allocate(est_eigenvalues,'mo energies','spin',tmpVectorAlpha, &
            tmpVectorBeta)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpVectorAlpha)
          tmpVectorBeta = tmpVectorAlpha%vat(nBasis+1,-1)
          tmpVectorAlpha = tmpVectorAlpha%vat(1,nBasis)
          call mqc_eigenvalues_allocate(est_eigenvalues,'mo energies','general',tmpVectorAlpha, &
            tmpVectorBeta)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('core hamiltonian')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'core hamiltonian','space',tmpMatrixAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          call fileInfo%getArray('CORE HAMILTONIAN BETA',tmpMatrixBeta)
          call mqc_integral_allocate(est_integral,'core hamiltonian','spin',tmpMatrixAlpha, &
            tmpMatrixBeta)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_integral,'core hamiltonian','general',tmpMatrixAlpha, &
            tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('fock')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'fock','space',tmpMatrixAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          call fileInfo%getArray('BETA FOCK MATRIX',tmpMatrixBeta)
          call mqc_integral_allocate(est_integral,'fock','spin',tmpMatrixAlpha, &
            tmpMatrixBeta)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_integral,'fock','general',tmpMatrixAlpha, &
            tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('density')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'density','space',tmpMatrixAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          call fileInfo%getArray('BETA SCF DENSITY MATRIX',tmpMatrixBeta)
          call mqc_integral_allocate(est_integral,'density','spin',tmpMatrixAlpha, &
            tmpMatrixBeta)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_integral,'density','general',tmpMatrixAlpha, &
            tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('overlap')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'overlap','space',tmpMatrixAlpha)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          call mqc_integral_allocate(est_integral,'overlap','spin',tmpMatrixAlpha, &
            tmpMatrixAlpha)
        elseIf(fileinfo%isGeneral()) then
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          nBasis = fileInfo%getVal('nBasis')
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_integral,'overlap','general',tmpMatrixAlpha, &
            tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case('wavefunction')
        if(fileinfo%isRestricted()) then
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%overlap_matrix,'overlap','space', &
            tmpMatrixAlpha)
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%core_hamiltonian,'core hamiltonian','space', &
            tmpMatrixAlpha)
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          call mqc_eigenvalues_allocate(est_wavefunction%mo_energies,'mo energies','space', &
            tmpVectorAlpha)
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%mo_coefficients,'mo coefficients','space', &
            tmpMatrixAlpha)
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%density_matrix,'density','space', &
            tmpMatrixAlpha)
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%fock_matrix,'fock','space',tmpMatrixAlpha)
          est_wavefunction%nBasis = fileInfo%getVal('nBasis')
          est_wavefunction%nAlpha = fileInfo%getVal('nAlpha')
          est_wavefunction%nBeta = fileInfo%getVal('nBeta')
          est_wavefunction%nElectrons = fileInfo%getVal('nElectrons')
          est_wavefunction%charge = fileInfo%getVal('charge')
          est_wavefunction%multiplicity = fileInfo%getVal('multiplicity')
          call mqc_gaussian_ICGU(fileInfo%ICGU,est_wavefunction%wf_type,est_wavefunction%wf_complex)
        elseIf(fileinfo%isUnrestricted()) then
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          call mqc_integral_allocate(est_wavefunction%overlap_matrix,'overlap','spin', &
            tmpMatrixAlpha,tmpMatrixAlpha)
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          call fileInfo%getArray('CORE HAMILTONIAN BETA',tmpMatrixBeta)
          call mqc_integral_allocate(est_wavefunction%core_hamiltonian,'core hamiltonian','spin', &
            tmpMatrixAlpha,tmpMatrixBeta)
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          call fileInfo%getArray('BETA ORBITAL ENERGIES',vectorOut=tmpVectorBeta)
          call mqc_eigenvalues_allocate(est_wavefunction%mo_energies,'mo energies','spin', &
            tmpVectorAlpha,tmpVectorBeta)
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          call fileInfo%getArray('BETA MO COEFFICIENTS',tmpMatrixBeta)
          call mqc_integral_allocate(est_wavefunction%mo_coefficients,'mo coefficients','spin', &
            tmpMatrixAlpha,tmpMatrixBeta)
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          call fileInfo%getArray('BETA SCF DENSITY MATRIX',tmpMatrixBeta)
          call mqc_integral_allocate(est_wavefunction%density_matrix,'density','spin', &
            tmpMatrixAlpha,tmpMatrixBeta)
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          call fileInfo%getArray('BETA FOCK MATRIX',tmpMatrixBeta)
          call mqc_integral_allocate(est_wavefunction%fock_matrix,'fock','spin',tmpMatrixAlpha, &
            tmpMatrixBeta)
          est_wavefunction%nBasis = fileInfo%getVal('nBasis')
          est_wavefunction%nAlpha = fileInfo%getVal('nAlpha')
          est_wavefunction%nBeta = fileInfo%getVal('nBeta')
          est_wavefunction%nElectrons = fileInfo%getVal('nElectrons')
          est_wavefunction%charge = fileInfo%getVal('charge')
          est_wavefunction%multiplicity = fileInfo%getVal('multiplicity')
          call mqc_gaussian_ICGU(fileInfo%ICGU,est_wavefunction%wf_type,est_wavefunction%wf_complex)
        elseIf(fileinfo%isGeneral()) then
          nBasis = fileInfo%getVal('nBasis')
          call fileInfo%getArray('OVERLAP',tmpMatrixAlpha)
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_wavefunction%overlap_matrix,'overlap','general', &
            tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
          call fileInfo%getArray('CORE HAMILTONIAN ALPHA',tmpMatrixAlpha)
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_wavefunction%core_hamiltonian,'core hamiltonian','general', &
            tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
          call fileInfo%getArray('ALPHA ORBITAL ENERGIES',vectorOut=tmpVectorAlpha)
          call mqc_matrix_spinBlockGHF(tmpVectorAlpha)
          tmpVectorBeta = tmpVectorAlpha%vat(nBasis+1,-1)
          tmpVectorAlpha = tmpVectorAlpha%vat(1,nBasis)
          call mqc_eigenvalues_allocate(est_wavefunction%mo_energies,'mo energies','general', &
            tmpVectorAlpha,tmpVectorBeta)
          call fileInfo%getArray('ALPHA MO COEFFICIENTS',tmpMatrixAlpha)
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_wavefunction%mo_coefficients,'mo_coefficients','general', &
            tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
          call fileInfo%getArray('ALPHA SCF DENSITY MATRIX',tmpMatrixAlpha)
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_wavefunction%density_matrix,'density','general', &
            tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)
          call fileInfo%getArray('ALPHA FOCK MATRIX',tmpMatrixAlpha)
          call mqc_matrix_spinBlockGHF(tmpMatrixAlpha)
          tmpMatrixBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[nBasis+1,-1])
          tmpMatrixBetaAlpha = tmpMatrixAlpha%mat([1,nBasis],[nBasis+1,-1])
          tmpMatrixAlphaBeta = tmpMatrixAlpha%mat([nBasis+1,-1],[1,nBasis])
          tmpMatrixAlpha = tmpMatrixAlpha%mat([1,nBasis],[1,nBasis])
          call mqc_integral_allocate(est_wavefunction%fock_matrix,'fock','general', &
            tmpMatrixAlpha,tmpMatrixBeta,tmpMatrixAlphaBeta,tmpMatrixBetaAlpha)


          est_wavefunction%nBasis = fileInfo%getVal('nBasis')
          est_wavefunction%nAlpha = fileInfo%getVal('nAlpha')
          est_wavefunction%nBeta = fileInfo%getVal('nBeta')
          est_wavefunction%nElectrons = fileInfo%getVal('nElectrons')
          est_wavefunction%charge = fileInfo%getVal('charge')
          est_wavefunction%multiplicity = fileInfo%getVal('multiplicity')
          call mqc_gaussian_ICGU(fileInfo%ICGU,est_wavefunction%wf_type,est_wavefunction%wf_complex)
        else
          call mqc_error('Unknown wavefunction type in getESTObj')
        endIf
      case default
        call mqc_error('Invalid label sent to %getESTObj.')
      end select
!
      return

      end subroutine MQC_Gaussian_Unformatted_Matrix_Get_EST_Object 


!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer
      Function MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer(fileinfo,label)
!
!     This function is used to get an integer scalar value that is stored in a
!     Gaussian matrix file object.
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      class(MQC_Gaussian_Unformatted_Matrix_File),intent(inout)::fileinfo
      character(len=*),intent(in)::label
      integer::MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer
      integer::value_out=0
      character(len=64)::myLabel
      character(len=256)::my_filename
!
!
!     Ensure the matrix file has already been opened and the header read.
!
      if(.not.fileinfo%isOpen())  &
        call MQC_Error('Failed to retrieve value from Gaussian matrix file: File not open.')
      if(.not.fileinfo%header_read) then
        my_filename = TRIM(fileinfo%filename)
        call fileinfo%CLOSEFILE()
        call MQC_Gaussian_Unformatted_Matrix_Read_Header(fileinfo,  &
          my_filename)
      endIf
!
!     Do the work...
!
      call String_Change_Case(label,'l',myLabel)
      select case (mylabel)
      case('natoms')
        value_out = fileinfo%natoms
      case('nbasis')
        value_out = fileinfo%nbasis
      case('nbasisuse')
        value_out = fileinfo%nbasisUse
      case('charge')
        value_out = fileinfo%icharge
      case('multiplicity')
        value_out = fileinfo%multiplicity
      case('nelectrons')
        value_out = fileinfo%nelectrons
      case('nalpha')
        value_out = (fileinfo%nelectrons + fileinfo%multiplicity - 1)/2 
      case('nbeta')
        value_out = (fileinfo%nelectrons - fileinfo%multiplicity + 1)/2 
      case default
        call mqc_error('Failure finding requested integer value in Gaussian matrix file')
      endSelect
!
      MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer = value_out
      return
      end Function MQC_Gaussian_Unformatted_Matrix_Get_Value_Integer

      
!=====================================================================
!
!PROCEDURE MQC_Gaussian_Unformatted_Matrix_Array_Type
      Function MQC_Gaussian_Unformatted_Matrix_Array_Type(NI,NR,N1,N2,N3,N4,N5,NRI)
!
!     This function returns a character string indicating the type of array
!     found in a Gaussian matrix file. This is done using NI, NR, N1, N2, N3,
!     N4, N5 and NRIfrom a matrix header in a Gaussian unformatted matrix file to
!     determine the type of array the data corresponds to. The return value will
!     be prepended by "REAL-", "INTEGER-", or "COMPLEX-" and appended by one of
!     the following:
!
!           "VECTOR"          A vector.
!           "MATRIX"          A matrix that is allocated full (M x N).
!           "SYMMATRIX"       A symmetric matrix.
!
!     If the input flags do not uniquely identify a known array type, then this
!     function returns "UNKNOWN".
!
!
!     H. P. Hratchian, 2017.
!
!
!     Variable Declarations.
!
      implicit none
      integer::NI,NR,N1,N2,N3,N4,N5,NRI
      character(len=64)::MQC_Gaussian_Unformatted_Matrix_Array_Type
!
!
!     Do the work...
!
      MQC_Gaussian_Unformatted_Matrix_Array_Type = "UNKNOWN"
      if(NR.lt.0.or.NI.lt.0) return
      if(NR.gt.0.and.NI.gt.0) then
        MQC_Gaussian_Unformatted_Matrix_Array_Type = "MIXED"
        if(NR.eq.1.and.NI.eq.4) then
          MQC_Gaussian_Unformatted_Matrix_Array_Type = "2ERIS"
        else
          return
        endIf
      elseIf(NI.eq.1) then 
        MQC_Gaussian_Unformatted_Matrix_Array_Type = "INTEGER"
      elseIf(NR.eq.1) then
        if(NRI.eq.1) then
          MQC_Gaussian_Unformatted_Matrix_Array_Type = "REAL"
        elseIf(NRI.eq.2) then
          MQC_Gaussian_Unformatted_Matrix_Array_Type = "COMPLEX"
        endIf
      endIf
      if(N1.gt.1.and.N2.eq.1.and.N3.eq.1.and.N4.eq.1.and.N5.eq.1) then
        MQC_Gaussian_Unformatted_Matrix_Array_Type = &
          TRIM(MQC_Gaussian_Unformatted_Matrix_Array_Type)//"-VECTOR"
      elseIf(N1.gt.1.and.N2.gt.1.and.N3.eq.1.and.N4.eq.1.and.N5.eq.1) then
        MQC_Gaussian_Unformatted_Matrix_Array_Type = &
          TRIM(MQC_Gaussian_Unformatted_Matrix_Array_Type)//"-MATRIX"
      elseIf(N1.le.-1.and.N2.gt.1.and.N3.eq.1.and.N4.eq.1.and.N5.eq.1) then
        MQC_Gaussian_Unformatted_Matrix_Array_Type = &
          TRIM(MQC_Gaussian_Unformatted_Matrix_Array_Type)//"-SYMMATRIX"
      elseIf(N1.le.-1.and.N2.le.-1.and.N3.le.-1.and.N4.gt.1.and.N5.eq.1) then
        MQC_Gaussian_Unformatted_Matrix_Array_Type = &
          TRIM(MQC_Gaussian_Unformatted_Matrix_Array_Type)//"-SYMSYMR4TENSOR"
      endIf
!
      return
      end function MQC_Gaussian_Unformatted_Matrix_Array_Type


!=====================================================================


      End Module MQC_Gaussian