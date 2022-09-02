Process pgmname(longmixed),dll,thread
       Identification Division.
       Program-ID "CBL2JAVA" is recursive.
      *
       Environment Division.
      *
       Configuration Section.
      *
       Data Division.
      *
       Working-Storage Section.
      *****************************************************************
      *            IMS DECLARATIONS
      *****************************************************************
      * DL/I FUNCTION CODES
       77  QC                   PIC X(2) VALUE 'QC'.
       77  GU-FUNC              PIC X(4) VALUE 'GU  '.
       77  ROLL-FUNC            PIC X(4) VALUE 'ROLL'.
       77  ISRT-FUNC            PIC X(4) VALUE 'ISRT'.

       01  INPUT-MESSAGE.
               03  IN-LL        PIC  S9(4) COMP.
               03  IN-ZZ        PIC  S9(4) COMP.
               03  IN-TRANCODE  PIC  X(8).
               03  IN-DATA      PIC  X(70).

       01  OUTPUT-MESSAGE.
           02  OUT-LL       PICTURE S9(3) COMP VALUE +70.
           02  OUT-ZZ       PICTURE S9(3) COMP VALUE +0.
           02  OUT-DATA     PICTURE X(70) VALUE SPACES.

       01  WS-CURRENT-DATE-FIELDS.
           05  WS-CURRENT-DATE.
               10  WS-CURRENT-YEAR    PIC  9(4).
               10  WS-CURRENT-MONTH   PIC  9(2).
               10  WS-CURRENT-DAY     PIC  9(2).
           05  WS-CURRENT-TIME.
               10  WS-CURRENT-HOUR    PIC  9(2).
               10  WS-CURRENT-MINUTE  PIC  9(2).
               10  WS-CURRENT-SECOND  PIC  9(2).
               10  WS-CURRENT-MS      PIC  9(2).
           05  WS-DIFF-FROM-GMT       PIC S9(4).

       Local-Storage Section.
      * Define variables to store 64-bit Java object references for 
      * the class ID and the method ID
       01 classid  pic 9(18) comp-5.
       01 methodid pic 9(18) comp-5.

      * Define variables for calling NewDirectByteBuffer to share
      * COBOL's IN-DATA Working-Storage with Java.
      * NewDirectByteBuffer expects a pointer to a block of memory,
      * a 64-bit value representing the amount of memory to be
      * referenced, and returns a 64-bit object reference for the 
      * allocated direct java.nio.ByteBuffer.
       01 in-data-ptr usage pointer.
       01 in-data-len pic s9(18) comp-5.
       01 input-data-buffer pic 9(18) comp-5.

      * Define variables to convert the Java class name, method name
      * and method signature from EBCDIC to UTF-8
       01 class-name-utf8  pic x(64).
       01 method-name-utf8 pic x(64).
       01 method-sig-utf8  pic x(64).

      * Error flag to check for Java Exceptions
       01 err-flag pic x(1) value x'00'.

      * Indicator for Java setup done
       01 JAVA-OBJECTS-FOUND       PIC X(1) VALUE 'N'.

       Linkage Section.
       COPY JNI.

       01  IOPCB.
           02  IO-LTERM         PIC X(8).
           02  IO-RESV          PIC X(2).
           02  IO-STATUS        PIC X(2).
           02  IO-PREF          PIC X(12).
           02  IO-MODN          PIC X(8).
           02  IO-USERID        PIC X(8).
           02  IO-GROUPID       PIC X(8).

      * PROCEDURE DIVISION
       PROCEDURE DIVISION.

           ENTRY 'MYIMSAPP' using IOPCB
           Display "************************************************"
           Display "            CBL2JAVA: Execution begin             "
           Display "************************************************"

           Move 'N' to JAVA-OBJECTS-FOUND

           Move SPACES to INPUT-MESSAGE

           Set address of JNIEnv to JNIEnvPtr

           Set address of JNINativeInterface to JNIEnv

      *    Tran was defined as Wait For Input (WFI) = Y
           Perform DO-MAIN-LOOP

           Display "************************************************"
           Display "            CBL2JAVA: Execution end             "
           Display "************************************************"
           
      ******************************************************************
      * NOTE: Use GOBACK instead of STOP RUN.
      *       STOP RUN will terminate the LE enclave   
      ******************************************************************
           GOBACK.


      * PROCEDURE DO-MAIN-LOOP
       DO-MAIN-LOOP.
           Move SPACES to INPUT-MESSAGE
           Move +32 to IN-LL IN INPUT-MESSAGE

           Display "CBL2JAVA attempting to read a message.!!"
           Perform PROCESS-INPUT-MESSAGE

           if IO-STATUS = ' ' then
               Perform INSERT-IO
           end-if

           if IO-STATUS = ' ' then
              GO to DO-MAIN-LOOP
           else
              Display "IO-STATUS : "  IO-STATUS
           end-if.


      * PROCEDURE PROCESS-INPUT-MESSAGE
       PROCESS-INPUT-MESSAGE.

           Move "$$" to IO-STATUS

           Call 'CBLTDLI' using GU-FUNC, IOPCB, INPUT-MESSAGE

           if IO-STATUS = ' '
             Display " "
             Display "IOPCB"
             Display "IO-LTERM  : "  IO-LTERM
             Display "IO-STATUS : "  IO-STATUS
             Display "IO-MODN   : "  IO-MODN
             Display "IO-USERID : "  IO-USERID
             Display "IO-GROUPID: "  IO-GROUPID
             Display "Input Message has: "
             Display "IN-LL: " IN-LL
             Display "IN-ZZ: " IN-ZZ
             Display "IN-TRANCODE: " IN-TRANCODE
             Display "IN-DATA: " IN-DATA

             Move FUNCTION CURRENT-DATE to WS-CURRENT-DATE-FIELDS
             Display "Before Java interactions: " WS-CURRENT-DATE-FIELDS

      *      Call the method sayHello1 using COBOL 6.4 CALL statement
             perform DRIVE-JAVA-VIA-CALL

      *      Call the method sayHello2 using manual JNI calls.
      *      First get the  Java objects representing the class, 
      *      method, and input arguments.
             Perform GET-JAVA-OBJECTS
             
             if JAVA-OBJECTS-FOUND = 'Y'
               Display 'Calling the StaticVoidMethod'
               Call CallStaticVoidMethod using by value JNIEnvPtr
                                          by value classid
                                          by value methodid
                                          by value input-data-buffer 
             end-if

             Move FUNCTION CURRENT-DATE to WS-CURRENT-DATE-FIELDS
             Display "After Java interactions:  " WS-CURRENT-DATE-FIELDS

             Display "IN-DATA now has: " IN-DATA
           end-if

      * Set the reply message in OUT-DATA
           Move spaces to OUT-DATA
           Move IN-DATA to OUT-DATA.



      * PROCEDURE INSERT-IO
       INSERT-IO.
           Display "Insert reply"
           Call 'CBLTDLI' using ISRT-FUNC, IOPCB, OUTPUT-MESSAGE
           
           Display "IO-LTERM  : "  IO-LTERM
           Display "IO-STATUS : "  IO-STATUS
           Display " ".

      * PROCEDURE DRIVE-JAVA-VIA-CALL
       DRIVE-JAVA-VIA-CALL.
           Call 'Java.mpr.apps.HelloWorldJava64.sayHello1' using 
                                                               IN-DATA
           Perform CHECK-JAVA-ERROR.

      * PROCEDURE GET-JAVA-OBJECTS
       GET-JAVA-OBJECTS.
           Display "COBOL getting Java objects"

           String function Display-of(n'mpr/apps/HelloWorldJava64',
                                      1208) x'00'
                  delimited by size into class-name-utf8

           String function Display-of(n'sayHello2', 
                                      1208) x'00'
                  delimited by size into method-name-utf8
      
           String function Display-of(n'(Ljava/nio/ByteBuffer;)V', 
                                      1208) x'00'
                  delimited by size into method-sig-utf8
      
      *    FYI in case you are going to work with arrays
      *    Sample of how to define the method signature for a
      *    method that expects an array as input.
      *    Method ID: sayHello(byte[] input).
      *    Method signature: '(B[)V' 
      *    In the codepage I'm using, the char 'Ý', xBA, represents the 
      *    left square bracket '[' denoting an array. So, we would use:
      *    String function Display-of(n'(BÝ)V',
      *                               1208) x'00'
      *           delimited by size into method-sig-utf8

           Call FindClass using 
                          by value JNIEnvPtr
                          by value address of class-name-utf8
                          returning classid

           Perform CHECK-JAVA-ERROR

           Call GetStaticMethodId using
                                  by value JNIEnvPtr
                                  by value classid
                                  by value address of method-name-utf8
                                  by value address of method-sig-utf8
                                  returning methodid

           Perform CHECK-JAVA-ERROR

      * Get a direct byte buffer so Java can "manipulate" the contents
      * of the IN-DATA item part of INPUT-MESSAGE.
           Compute in-data-len = length of IN-DATA 
           Set in-data-ptr to address of IN-DATA
           call NewDirectByteBuffer using 
                                    by value JNIEnvPtr
                                    by value in-data-ptr
                                    by value in-data-len
                                    returning input-data-buffer

           Perform CHECK-JAVA-ERROR

      * Check methodid against the value of zero rather than null
      * because methodid is 64-bits and null is not.
           if methodid = 0
              Display "Error getting the method ID."
           else
              Move 'Y' to JAVA-OBJECTS-FOUND
              Display "COBOL got Java objects"
           end-if.



      * PROCEDURE CHECK-JAVA-ERROR
      * Simple error handling.
       CHECK-JAVA-ERROR.
           Call ExceptionCheck using by value JNIEnvPtr
                               returning err-flag
           if err-flag = x'01' then
             Display 'Unhandled Java exception encountered: terminating'
             Display ' '
             goback
           end-if
           Move x'00' to err-flag
           exit.


       End Program "CBL2JAVA".
