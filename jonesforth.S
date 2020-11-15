/*      RISC-V implementation of jones forth.
	This repository is intended to rewrite the jones FORTH compiler and tutorial into RISC-V ISA.

	The code part of this tutorial is rewritten into RISC-V ASM
	By JJy <jjyruby@gmail.com> https://justjjy.com,
	other part of this tutorial is almost untouched 
	unless it is related to the RISC-V ISA.

	So you can use this tutorial just like the original one 
	except the compiler is run on the Linux / RISCVI64.

	All the additional work is released under the same PUBLIC DOMAIN
	just like the original compiler / tutorial.
 */

/*	A sometimes minimal FORTH compiler and tutorial for Linux / i386 systems. -*- asm -*-
	By Richard W.M. Jones <rich@annexia.org> http://annexia.org/forth
	This is PUBLIC DOMAIN (see public domain release statement below).
	$Id: jonesforth.S,v 1.47 2009-09-11 08:33:13 rich Exp $

	riscv64-unknown-elf-gcc -I /usr/include/ -nostdlib -static -Wl,-Ttext,0 -o jonesforth jonesforth.S
*/
	.set JONES_VERSION,47
/*
	INTRODUCTION ----------------------------------------------------------------------

	FORTH is one of those alien languages which most working programmers regard in the same
	way as Haskell, LISP, and so on.  Something so strange that they'd rather any thoughts
	of it just go away so they can get on with writing this paying code.  But that's wrong
	and if you care at all about programming then you should at least understand all these
	languages, even if you will never use them.

	LISP is the ultimate high-level language, and features from LISP are being added every
	decade to the more common languages.  But FORTH is in some ways the ultimate in low level
	programming.  Out of the box it lacks features like dynamic memory management and even
	strings.  In fact, at its primitive level it lacks even basic concepts like IF-statements
	and loops.

	Why then would you want to learn FORTH?  There are several very good reasons.  First
	and foremost, FORTH is minimal.  You really can write a complete FORTH in, say, 2000
	lines of code.  I don't just mean a FORTH program, I mean a complete FORTH operating
	system, environment and language.  You could boot such a FORTH on a bare PC and it would
	come up with a prompt where you could start doing useful work.  The FORTH you have here
	isn't minimal and uses a Linux process as its 'base PC' (both for the purposes of making
	it a good tutorial). It's possible to completely understand the system.  Who can say they
	completely understand how Linux works, or gcc?

	Secondly FORTH has a peculiar bootstrapping property.  By that I mean that after writing
	a little bit of assembly to talk to the hardware and implement a few primitives, all the
	rest of the language and compiler is written in FORTH itself.  Remember I said before
	that FORTH lacked IF-statements and loops?  Well of course it doesn't really because
	such a lanuage would be useless, but my point was rather that IF-statements and loops are
	written in FORTH itself.

	Now of course this is common in other languages as well, and in those languages we call
	them 'libraries'.  For example in C, 'printf' is a library function written in C.  But
	in FORTH this goes way beyond mere libraries.  Can you imagine writing C's 'if' in C?
	And that brings me to my third reason: If you can write 'if' in FORTH, then why restrict
	yourself to the usual if/while/for/switch constructs?  You want a construct that iterates
	over every other element in a list of numbers?  You can add it to the language.  What
	about an operator which pulls in variables directly from a configuration file and makes
	them available as FORTH variables?  Or how about adding Makefile-like dependencies to
	the language?  No problem in FORTH.  How about modifying the FORTH compiler to allow
	complex inlining strategies -- simple.  This concept isn't common in programming languages,
	but it has a name (in fact two names): "macros" (by which I mean LISP-style macros, not
	the lame C preprocessor) and "domain specific languages" (DSLs).

	This tutorial isn't about learning FORTH as the language.  I'll point you to some references
	you should read if you're not familiar with using FORTH.  This tutorial is about how to
	write FORTH.  In fact, until you understand how FORTH is written, you'll have only a very
	superficial understanding of how to use it.

	So if you're not familiar with FORTH or want to refresh your memory here are some online
	references to read:

	http://en.wikipedia.org/wiki/Forth_%28programming_language%29

	http://galileo.phys.virginia.edu/classes/551.jvn.fall01/primer.htm

	http://wiki.laptop.org/go/Forth_Lessons

	http://www.albany.net/~hello/simple.htm

	Here is another "Why FORTH?" essay: http://www.jwdt.com/~paysan/why-forth.html

	Discussion and criticism of this FORTH here: http://lambda-the-ultimate.org/node/2452

	ACKNOWLEDGEMENTS ----------------------------------------------------------------------

	This code draws heavily on the design of LINA FORTH (http://home.hccnet.nl/a.w.m.van.der.horst/lina.html)
	by Albert van der Horst.  Any similarities in the code are probably not accidental.

	Some parts of this FORTH are also based on this IOCCC entry from 1992:
	http://ftp.funet.fi/pub/doc/IOCCC/1992/buzzard.2.design.
	I was very proud when Sean Barrett, the original author of the IOCCC entry, commented in the LtU thread
	http://lambda-the-ultimate.org/node/2452#comment-36818 about this FORTH.

	And finally I'd like to acknowledge the (possibly forgotten?) authors of ARTIC FORTH because their
	original program which I still have on original cassette tape kept nagging away at me all these years.
	http://en.wikipedia.org/wiki/Artic_Software

	PUBLIC DOMAIN ----------------------------------------------------------------------

	I, the copyright holder of this work, hereby release it into the public domain. This applies worldwide.

	In case this is not legally possible, I grant any entity the right to use this work for any purpose,
	without any conditions, unless such conditions are required by law.

	SETTING UP ----------------------------------------------------------------------

	Let's get a few housekeeping things out of the way.  Firstly because I need to draw lots of
	ASCII-art diagrams to explain concepts, the best way to look at this is using a window which
	uses a fixed width font and is at least this wide:

 <------------------------------------------------------------------------------------------------------------------------>

	Secondly make sure TABS are set to 8 characters.  The following should be a vertical
	line.  If not, sort out your tabs.

		|
		|
	    	|

	Thirdly I assume that your screen is at least 50 characters high.

	ASSEMBLING ----------------------------------------------------------------------

	If you want to actually run this FORTH, rather than just read it, you will need Linux on an
	RISC-V.  Linux because instead of programming directly to the hardware on a bare PC which I
	could have done, I went for a simpler tutorial by assuming that the 'hardware' is a Linux
	process with a few basic system calls (read, write and exit and that's about all).  RISC-V
	is needed because I had to write the assembly for a processor. 
	(Of course when I say 'RISC-V', any 32- or 64-bit RISC-V processor or VM will do.  
	I'm compiling this on a 64 bit AMD Opteron).

	Again, to assemble this you will need gcc and gas (the GNU assembler).  The commands to
	assemble and run the code (save this file as 'jonesforth.S') are:

	gcc -m32 -nostdlib -static -Wl,-Ttext,0 -Wl,--build-id=none -o jonesforth jonesforth.S
	cat jonesforth.f - | ./jonesforth

	If you want to run your own FORTH programs you can do:

	cat jonesforth.f myprog.f | ./jonesforth

	If you want to load your own FORTH code and then continue reading user commands, you can do:

	cat jonesforth.f myfunctions.f - | ./jonesforth

	ASSEMBLER ----------------------------------------------------------------------

	(You can just skip to the next section -- you don't need to be able to read assembler to
	follow this tutorial).

	However if you do want to read the assembly code here are a few notes about gas (the GNU assembler):

	(1) Register names are prefixed with 'a', `t` or 's', so a0 is the 64 bit RISC-V register.  The registers
	    available on RISC-V are: `a0 - a7`, `t0 - t6`, `s0 - s11`.

	(2) add, mv, etc. take arguments in the form RD, RS1[, RS2].  So mv a0, t0 moves t0 -> a0

	(3) li instruction is used for setting a constant value to a register:
	    li t0, 1		set value 1 to t0

	(4) gas has a funky syntax for local labels, where '1f' (etc.) means label '1:' "forwards"
	    and '1b' (etc.) means label '1:' "backwards".  Notice that these labels might be mistaken
	    for hex numbers (eg. you might confuse 1b with $0x1b).

	(5) 'beqz' is "jump if rs is zero", 'bnez' for "jump if rs is not zero", 'j' "jump without condition" etc.

	(6) gas has a reasonably nice .macro syntax, and I use them a lot to make the code shorter and
	    less repetitive.

	For more help reading the assembler, do "info gas" at the Linux prompt.

	Now the tutorial starts in earnest.

	THE DICTIONARY ----------------------------------------------------------------------

	In FORTH as you will know, functions are called "words", and just as in other languages they
	have a name and a definition.  Here are two FORTH words:

	: DOUBLE DUP + ;		\ name is "DOUBLE", definition is "DUP +"
	: QUADRUPLE DOUBLE DOUBLE ;	\ name is "QUADRUPLE", definition is "DOUBLE DOUBLE"

	Words, both built-in ones and ones which the programmer defines later, are stored in a dictionary
	which is just a linked list of dictionary entries.

	<--- DICTIONARY ENTRY (HEADER) ----------------------->
	+------------------------+--------+---------- - - - - +----------- - - - -
	| LINK POINTER           | LENGTH/| NAME	      | DEFINITION
	|			 | FLAGS  |     	      |
	+--- (4 bytes) ----------+- byte -+- n bytes  - - - - +----------- - - - -

	I'll come to the definition of the word later.  For now just look at the header.  The first
	4 bytes are the link pointer.  This points back to the previous word in the dictionary, or, for
	the first word in the dictionary it is just a NULL pointer.  Then comes a length/flags byte.
	The length of the word can be up to 31 characters (5 bits used) and the top three bits are used
	for various flags which I'll come to later.  This is followed by the name itself, and in this
	implementation the name is rounded up to a multiple of 4 bytes by padding it with zero bytes.
	That's just to ensure that the definition starts on a 32 bit boundary.

	A FORTH variable called LATEST contains a pointer to the most recently defined word, in
	other words, the head of this linked list.

	DOUBLE and QUADRUPLE might look like this:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------- - - - -
	| LINK    | 6 | D | O | U | B | L | E | 0 | (definition ...)
	+---------+---+---+---+---+---+---+---+---+------------- - - - -
	   ^       len                         padding
	   |
	+--|------+---+---+---+---+---+---+---+---+---+---+---+---+------------- - - - -
	| LINK    | 9 | Q | U | A | D | R | U | P | L | E | 0 | 0 | (definition ...)
	+---------+---+---+---+---+---+---+---+---+---+---+---+---+------------- - - - -
	   ^       len                                     padding
	   |
	   |
	  LATEST

	You should be able to see from this how you might implement functions to find a word in
	the dictionary (just walk along the dictionary entries starting at LATEST and matching
	the names until you either find a match or hit the NULL pointer at the end of the dictionary);
	and add a word to the dictionary (create a new definition, set its LINK to LATEST, and set
	LATEST to point to the new word).  We'll see precisely these functions implemented in
	assembly code later on.

	One interesting consequence of using a linked list is that you can redefine words, and
	a newer definition of a word overrides an older one.  This is an important concept in
	FORTH because it means that any word (even "built-in" or "standard" words) can be
	overridden with a new definition, either to enhance it, to make it faster or even to
	disable it.  However because of the way that FORTH words get compiled, which you'll
	understand below, words defined using the old definition of a word continue to use
	the old definition.  Only words defined after the new definition use the new definition.

	DIRECT THREADED CODE ----------------------------------------------------------------------

	Now we'll get to the really crucial bit in understanding FORTH, so go and get a cup of tea
	or coffee and settle down.  It's fair to say that if you don't understand this section, then you
	won't "get" how FORTH works, and that would be a failure on my part for not explaining it well.
	So if after reading this section a few times you don't understand it, please email me
	(rich@annexia.org).

	Let's talk first about what "threaded code" means.  Imagine a peculiar version of C where
	you are only allowed to call functions without arguments.  (Don't worry for now that such a
	language would be completely useless!)  So in our peculiar C, code would look like this:

	f ()
	{
	  a ();
	  b ();
	  c ();
	}

	and so on.  How would a function, say 'f' above, be compiled by a standard C compiler?
	Probably into assembly code like this.  On the right hand side I've written the actual
	RISC-V machine code.

	f:
	  CALL a			E8 08 00 00 00
	  CALL b			E8 1C 00 00 00
	  CALL c			E8 2C 00 00 00
	  ; ignore the return from the function for now

	"E8" is the x86 machine code to "CALL" a function.  In the first 20 years of computing
	memory was hideously expensive and we might have worried about the wasted space being used
	by the repeated "E8" bytes.  We can save 20% in code size (and therefore, in expensive memory)
	by compressing this into just:

	08 00 00 00		Just the function addresses, without
	1C 00 00 00		the CALL prefix.
	2C 00 00 00

	On a 16-bit machine like the ones which originally ran FORTH the savings are even greater - 33%.

	[Historical note: If the execution model that FORTH uses looks strange from the following
	paragraphs, then it was motivated entirely by the need to save memory on early computers.
	This code compression isn't so important now when our machines have more memory in their L1
	caches than those early computers had in total, but the execution model still has some
	useful properties].

	Of course this code won't run directly on the CPU any more.  Instead we need to write an
	interpreter which takes each set of bytes and calls it.

	On an RISC-V machine it turns out that we can write this interpreter rather easily, in just
	two assembly instructions which turn into just 3 bytes of machine code.  Let's store the
	pointer to the next word to execute in the s1 register:

		08 00 00 00	<- We're executing this one now.  s1 is the _next_ one to execute.
	  s1 -> 1C 00 00 00
		2C 00 00 00

	The all-important instructions are called `lw` and `addiw`. Firstly `lw` reads the memory 
	at s1 into the register (a0).  Secondly `addiw` increments s1 by 4 bytes.  
	So after the two instructions, the situation now looks like this:

		08 00 00 00	<- We're still executing this one
		1C 00 00 00	<- a0 now contains this address (0x0000001C)
	  s1 -> 2C 00 00 00

	Now we just need to jump to the address in a0.  This is again needs two instructions:
	firstly `lw t0, 0(a0)` to load the jump address to t0, then `jalr t0` to jump to the address.
	And after doing the jump, the situation looks like:

		08 00 00 00
		1C 00 00 00	<- Now we're executing this subroutine.
	  s1 -> 2C 00 00 00

	To make this work, each subroutine is followed by the four instructions: 
	'lw a0, 0(s1); addi s1, s1, 4; lw t0, 0(a0); jalr t0'
	which make the jump to the next subroutine.

	And that brings us to our first piece of actual code!  Well, it's a macro.
*/

/* NEXT macro. */
/* use s1 pointing to the interpreter pc
 */
	.macro NEXT
	lw a0, 0(s1)
	addi s1, s1, 4
	lw t0, 0(a0)
	jalr t0
	.endm


/*	The macro is called NEXT.  That's a FORTH-ism.  It expands to those two instructions.

	Every FORTH primitive that we write has to be ended by NEXT.  Think of it kind of like
	a return.

	The above describes what is known as direct threaded code.

	To sum up: We compress our function calls down to a list of addresses and use a somewhat
	magical macro to act as a "jump to next function in the list".  We also use one register (s1)
	to act as a kind of instruction pointer, pointing to the next function in the list.

	I'll just give you a hint of what is to come by saying that a FORTH definition such as:

	: QUADRUPLE DOUBLE DOUBLE ;

	actually compiles (almost, not precisely but we'll see why in a moment) to a list of
	function addresses for DOUBLE, DOUBLE and a special function called EXIT to finish off.

	At this point, REALLY EAGLE-EYED ASSEMBLY EXPERTS are saying "JONES, YOU'VE MADE A MISTAKE!".

	INDIRECT THREADED CODE ----------------------------------------------------------------------

	It turns out that direct threaded code is interesting but only if you want to just execute
	a list of functions written in assembly language.  So QUADRUPLE would work only if DOUBLE
	was an assembly language function.  In the direct threaded code, QUADRUPLE would look like:

		+------------------+
		| addr of DOUBLE  --------------------> (assembly code to do the double)
		+------------------+                    NEXT
	  s1 ->	| addr of DOUBLE   |
		+------------------+

	We can add an extra indirection to allow us to run both words written in assembly language
	(primitives written for speed) and words written in FORTH themselves as lists of addresses.

	The extra indirection is the reason for the `lw t0, 0(a0)`.

	Let's have a look at how QUADRUPLE and DOUBLE really look in FORTH:

		: QUADRUPLE DOUBLE DOUBLE ;

		+------------------+
		| codeword         |		   : DOUBLE DUP + ;
		+------------------+
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP   --------------> +------------------+
		| addr of EXIT	   |		   +------------------+            | codeword      -------+
		+------------------+	     s1 -> | addr of +     --------+	   +------------------+   |
						   +------------------+	   |	   | assembly to    <-----+
						   | addr of EXIT     |    |       | implement DUP    |
						   +------------------+	   |	   |	..	      |
									   |	   |    ..            |
									   |	   | NEXT             |
									   |	   +------------------+
									   |
									   +-----> +------------------+
										   | codeword      -------+
										   +------------------+   |
										   | assembly to   <------+
										   | implement +      |
										   | 	..            |
										   | 	..            |
										   | NEXT      	      |
										   +------------------+

	This is the part where you may need an extra cup of tea/coffee/favourite caffeinated
	beverage.  What has changed is that I've added an extra pointer to the beginning of
	the definitions.  In FORTH this is sometimes called the "codeword".  The codeword is
	a pointer to the interpreter to run the function.  For primitives written in
	assembly language, the "interpreter" just points to the actual assembly code itself.
	They don't need interpreting, they just run.

	In words written in FORTH (like QUADRUPLE and DOUBLE), the codeword points to an interpreter
	function.

	I'll show you the interpreter function shortly, but let's recall our indirect
	jump instructions.  Take the case where we're executing DOUBLE
	as shown, and DUP has been called.  Note that s1 is pointing to the address of +

	The assembly code for DUP eventually does a NEXT.  That:

	(1) reads the address of + into a0		a0 points to the codeword of +
	(2) increments s1 by 4
	(3) jumps to the indirect t0			jumps to the address in the codeword of +,
							ie. the assembly code to implement +

		+------------------+
		| codeword         |
		+------------------+
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP   --------------> +------------------+
		| addr of EXIT	   |		   +------------------+            | codeword      -------+
		+------------------+	   	   | addr of +     --------+	   +------------------+   |
						   +------------------+	   |	   | assembly to    <-----+
					     s1 -> | addr of EXIT     |    |       | implement DUP    |
						   +------------------+	   |	   |	..	      |
									   |	   |    ..            |
									   |	   | NEXT             |
									   |	   +------------------+
									   |
									   +-----> +------------------+
										   | codeword      -------+
										   +------------------+   |
									now we're  | assembly to    <-----+
									executing  | implement +      |
									this	   | 	..            |
									function   | 	..            |
										   | NEXT      	      |
										   +------------------+

	So I hope that I've convinced you that NEXT does roughly what you'd expect.  This is
	indirect threaded code.

	I've glossed over four things.  I wonder if you can guess without reading on what they are?

	.
	.
	.

	My list of four things are: (1) What does "EXIT" do?  (2) which is related to (1) is how do
	you call into a function, ie. how does s1 start off pointing at part of QUADRUPLE, but
	then point at part of DOUBLE.  (3) What goes in the codeword for the words which are written
	in FORTH?  (4) How do you compile a function which does anything except call other functions
	ie. a function which contains a number like : DOUBLE 2 * ; ?

	THE INTERPRETER AND RETURN STACK ------------------------------------------------------------

	Going at these in no particular order, let's talk about issues (3) and (2), the interpreter
	and the return stack.

	Words which are defined in FORTH need a codeword which points to a little bit of code to
	give them a "helping hand" in life.  They don't need much, but they do need what is known
	as an "interpreter", although it doesn't really "interpret" in the same way that, say,
	Java bytecode used to be interpreted (ie. slowly).  This interpreter just sets up a few
	machine registers so that the word can then execute at full speed using the indirect
	threaded model above.

	One of the things that needs to happen when QUADRUPLE calls DOUBLE is that we save the old
	s1 ("instruction pointer") and create a new one pointing to the first word in DOUBLE.
	Because we will need to restore the old s1 at the end of DOUBLE (this is, after all, like
	a function call), we will need a stack to store these "return addresses" (old values of s1).

	As you will have seen in the background documentation, FORTH has two stacks, an ordinary
	stack for parameters, and a return stack which is a bit more mysterious.  But our return
	stack is just the stack I talked about in the previous paragraph, used to save s1 when
	calling from a FORTH word into another FORTH word.

	In this FORTH, we are using the normal stack pointer (sp) for the parameter stack.
	We will use the RISC-V's "other" stack pointer (fp, usually called the "frame pointer")
	for our return stack.

	I've got two macros which just wrap up the details of using fp for the return stack.
	You use them as for example "PUSHRSP a0" (push a0 on the return stack) or "POPRSP a1"
	(pop top of return stack into a1).
*/

/* Macros to deal with the return stack. */
	.macro PUSH reg
	addi sp, sp, -4         // push reg on to stack
	sw \reg, 0(sp)
	.endm

	.macro POP reg
	lw \reg, 0(sp)		// pop top of return stack to reg
	addi sp, sp, +4
	.endm

	.macro PUSHRSP reg
	addi fp, fp, -4                   // push  reg on to stack
	sw \reg, 0(fp)
	.endm

	.macro POPRSP reg
	lw \reg, 0(fp)            	// pop top of return stack to reg
	addi fp, fp, +4
	.endm

/* Macros to help us handling function calls.
 This macro saves all nessary registers before a call
  and resume these registers after the call */
	.macro RCALL symbol
	PUSH ra					// push ra (return address) on to stack
	call \symbol
	POP ra					// resume ra
	.endm


/*
	And with that we can now talk about the interpreter.

	In FORTH the interpreter function is often called DOCOL (I think it means "DO COLON" because
	all FORTH definitions start with a colon, as in : DOUBLE DUP + ;

	The "interpreter" (it's not really "interpreting") just needs to push the old s1 on the
	stack and set s1 to the first word in the definition.  Remember that we jumped to the
	function using `lw t0, 0(a0); jalr t0`?  Well a consequence of that is that conveniently a0 contains
	the address of this codeword, so just by adding 4 to it we get the address of the first
	data word.  Finally after setting up s1, it just does NEXT which causes that first word
	to run.
*/

/* DOCOL - the interpreter! */

	.text
	.balign 4
DOCOL:
	PUSHRSP s1		// push s1 on to the return stack
	addiw a0, a0, +4 	// a0 points to codeword, so make
	mv s1, a0		// s1 point to first data word
	NEXT

/*
	Just to make this absolutely clear, let's see how DOCOL works when jumping from QUADRUPLE
	into DOUBLE:

		QUADRUPLE:
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE:
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+         a0 -> | addr of DOCOL    |
	  s1 ->	| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+               | etc.             |

	First, the call to DOUBLE calls DOCOL (the codeword of DOUBLE).  DOCOL does this:  It
	pushes the old s1 on the return stack.  a0 points to the codeword of DOUBLE, so we
	just add 4 on to it to get our new s1:

		QUADRUPLE:
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE:
		| addr of DOUBLE  ---------------> +------------------+
top of return	+------------------+         a0 -> | addr of DOCOL    |
stack points ->	| addr of DOUBLE   |	   + 4 =   +------------------+
		+------------------+	     s1 -> | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+               | etc.             |

	Then we do NEXT, and because of the magic of threaded code that increments s1 again
	and calls DUP.

	Well, it seems to work.

	One minor point here.  Because DOCOL is the first bit of assembly actually to be defined
	in this file (the others were just macros), and because I usually compile this code with the
	text segment starting at address 0, DOCOL has address 0.  So if you are disassembling the
	code and see a word with a codeword of 0, you will immediately know that the word is
	written in FORTH (it's not an assembler primitive) and so uses DOCOL as the interpreter.

	STARTING UP ----------------------------------------------------------------------

	Now let's get down to nuts and bolts.  When we start the program we need to set up
	a few things like the return stack.  But as soon as we can, we want to jump into FORTH
	code (albeit much of the "early" FORTH code will still need to be written as
	assembly language primitives).

	This is what the set up code does.  Does a tiny bit of house-keeping, sets up the
	separate return stack (NB: Linux gives us the ordinary parameter stack already), then
	immediately jumps to a FORTH word called QUIT.  Despite its name, QUIT doesn't quit
	anything.  It resets some internal state and starts reading and interpreting commands.
	(The reason it is called QUIT is because you can call QUIT from your own FORTH code
	to "quit" your program and go back to interpreting).
*/

/* Assembler entry point. */

	.text
	.globl _start
_start:
	la t0, var_S0
	sw sp, 0(t0)		// Save the initial data stack pointer in FORTH variable S0.
	la fp, return_stack_top        // Initialise the return stack.
	call set_up_data_segment

	la s1, cold_start      	// Initialise interpreter.
	NEXT			        // Run interpreter!

	.section .rodata
	.balign 4
cold_start:			// High-level code without a codeword.
	.int QUIT

/*
	BUILT-IN WORDS ----------------------------------------------------------------------

	Remember our dictionary entries (headers)?  Let's bring those together with the codeword
	and data words to see how : DOUBLE DUP + ; really looks in memory.

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
	   ^       len                         pad  codeword      |
	   |							  V
	  LINK in next word				points to codeword of DUP
	
	Initially we can't just write ": DOUBLE DUP + ;" (ie. that literal string) here because we
	don't yet have anything to read the string, break it up at spaces, parse each word, etc. etc.
	So instead we will have to define built-in words using the GNU assembler data constructors
	(like .int, .byte, .string, .ascii and so on -- look them up in the gas info page if you are
	unsure of them).

	The long way would be:

	.int <link to previous word>
	.byte 6			// len
	.ascii "DOUBLE"		// string
	.byte 0			// padding
DOUBLE: .int DOCOL		// codeword
	.int DUP		// pointer to codeword of DUP
	.int PLUS		// pointer to codeword of +
	.int EXIT		// pointer to codeword of EXIT

	That's going to get quite tedious rather quickly, so here I define an assembler macro
	so that I can just write:

	defword "DOUBLE",6,,DOUBLE
	.int DUP,PLUS,EXIT

	and I'll get exactly the same effect.

	Don't worry too much about the exact implementation details of this macro - it's complicated!
*/

/* Flags - these are discussed later. */
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f	// length mask

	// Store the chain of links.
	.macro defword name, namelen, flags=0, label, link
	.section .rodata
	.balign 4
	.globl name_\label
name_\label :
	.int name_\link		// link
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.balign 4		// padding to next 4 byte boundary
	.globl \label
\label :
	.int DOCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

/*
	Similarly I want a way to write words written in assembly language.  There will quite a few
	of these to start with because, well, everything has to start in assembly before there's
	enough "infrastructure" to be able to start writing FORTH words, but also I want to define
	some common FORTH words in assembly language for speed, even though I could write them in FORTH.

	This is what DUP looks like in memory:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+------------+
	| LINK    | 3 | D | U | P | code_DUP ---------------------> points to the assembly
	+---------+---+---+---+---+------------+		    code used to write DUP,
	   ^       len              codeword			    which ends with NEXT.
	   |
	  LINK in next word

	Again, for brevity in writing the header I'm going to write an assembler macro called defcode.
	As with defword above, don't worry about the complicated details of the macro.
*/

	.macro defcode name, namelen, flags=0, label, link
	.section .rodata
	.balign 4
	.globl name_\label
name_\label :
	.int name_\link		// link
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.balign 4		// padding to next 4 byte boundary
	.globl \label
\label :
	.int code_\label	// codeword
	.text
	.balign 4
	.globl code_\label
code_\label :			// assembler code follows
	.endm

/*
	Now some easy FORTH primitives.  These are written in assembly for speed.  If you understand
	RISC-V assembly language then it is worth reading these.  However if you don't understand assembly
	you can skip the details.
*/

	.set name_NULL, 0

	defcode "DROP",4,,DROP, NULL
	POP a0		// drop top of stack
	NEXT

	defcode "SWAP",4,,SWAP, DROP
	POP a0		// swap top two elements on stack
	POP a1
	PUSH a0
	PUSH a1
	NEXT

	defcode "DUP",3,,DUP, SWAP
	lw a0, 0(sp)    		// duplicate top of stack
	PUSH a0
	NEXT

	defcode "OVER",4,,OVER, DUP
	lw a0, 4(sp)	                // get the second element of stack
	PUSH a0 		        // and push it on top
	NEXT

	defcode "ROT",3,,ROT, OVER
	POP a0
	POP a1
	POP a2
	PUSH a1
	PUSH a0
	PUSH a2
	NEXT

	defcode "-ROT",4,,NROT, ROT
	POP a0
	POP a1
	POP a2
	PUSH a0
	PUSH a2
	PUSH a1
	NEXT

	defcode "2DROP",5,,TWODROP, NROT // drop top two elements of stack
	POP a0
	POP a0
	NEXT

	defcode "2DUP",4,,TWODUP, TWODROP // duplicate top two elements of stack
	lw a0, 0(sp)
	lw a1, 4(sp)
	PUSH a1
	PUSH a0
	NEXT

	defcode "2SWAP",5,,TWOSWAP, TWODUP // swap top two pairs of elements of stack
	POP a0
	POP a1
	POP a2
	POP a3
	PUSH a1
	PUSH a0
	PUSH a3
	PUSH a2
	NEXT

	defcode "?DUP",4,,QDUP, TWOSWAP	// duplicate top of stack if non-zero
	lw a0, 0(sp)
	beqz a0, 1f
	PUSH a0
1:	NEXT

	defcode "1+",2,,INCR, QDUP
	POP a0
	addiw a0, a0, +1         // increment top of stack
	PUSH a0
	NEXT

	defcode "1-",2,,DECR, INCR
	POP a0
	addiw a0, a0, -1		// decrement top of stack
	PUSH a0
	NEXT

	defcode "4+",2,,INCR4, DECR
	POP a0
	addiw a0, a0, +4		// add 4 to top of stack
	PUSH a0
	NEXT

	defcode "4-",2,,DECR4, INCR4
	POP a0
	addiw a0, a0, -4 	// subtract 4 from top of stack
	PUSH a0
	NEXT

	defcode "+",1,,ADD, DECR4
	POP a0		// get top of stack
	POP a1		// get second of stack
	addw a0, a0, a1	// and add the two number
	PUSH a0         // push back the result to stack
	NEXT

	defcode "-",1,,SUB, ADD
	POP a0		// get top of stack
	POP a1		// get second of stack
	subw a0, a1, a0	// and subtract the two number
	PUSH a0         // push back the result to stack
	NEXT

	defcode "*",1,,MUL, SUB
	POP a0
	POP a1
	mul a0, a0, a1
	PUSH a0		// ignore overflow
	NEXT

/*
	In this FORTH, only /MOD is primitive.  Later we will define the / and MOD words in
	terms of the primitive /MOD.
*/

/*
	From the RISC-V spec [7.2]:
	If both the quotient and remainder are required from the same division, the
	recommended code sequence is: DIV[U] rdq, rs1, rs2; REM[U] rdr, rs1, rs2 (rdq cannot be the
	same as rs1 or rs2). Microarchitectures can then fuse these into a single divide operation instead
	of performing two separate divides.
*/
	defcode "/MOD",4,,DIVMOD, MUL
	POP a0,
	POP a1,
	div a3, a1, a0
	rem a4, a1, a0
	PUSH a4		// push remainder
	PUSH a3		// push quotient
	NEXT

/*
	Lots of comparison operations like =, <, >, etc..

	ANS FORTH says that the comparison words should return all (binary) 1's for
	TRUE and all 0's for FALSE.  However this is a bit of a strange convention
	so this FORTH breaks it and returns the more normal (for C programmers ...)
	1 meaning TRUE and 0 meaning FALSE.
*/

	defcode "=",1,,EQU, DIVMOD	// top two words are equal?
	POP a0
	POP a1
	subw a0, a0, a1
	seqz a0, a0             // set a0 to 1 if a0 is zero
	PUSH a0
	NEXT

	defcode "<>",2,,NEQU, EQU	// top two words are not equal?
	POP a0
	POP a1
	subw a0, a0, a1
	sltu a0, zero, a0         // set a0 to 1 if a0 is not equals to zero, otherwise set a0 to 0
	PUSH a0
	NEXT

	defcode "<",1,,LT, NEQU
	POP a0
	POP a1
	slt a0, a1, a0          // set a0 to 1 if a1 < a0, otherwise set a0 to 0
	PUSH a0
	NEXT

	defcode ">",1,,GT, LT
	POP a0
	POP a1
	slt a0, a0, a1          // set a0 to 1 if a0 < a1, otherwise set a0 to 0
	PUSH a0
	NEXT

	defcode "<=",2,,LE, GT
	POP a0
	POP a1
	slt t0, a0, a1 // if a1 <= a0, then !(a0 < a1)
	li t1, 1
	subw t0, t1, t0
	PUSH t0
	NEXT

	defcode ">=",2,,GE, LE
	POP a0
	POP a1
	slt t0, a1, a0          // if a1 >= a0, then !(a1 < a0)
	li t1, 1
	subw t0, t1, t0
	PUSH t0
	NEXT

	defcode "0=",2,,ZEQU, GE	// top of stack equals 0?
	POP a0
	seqz a0, a0
	PUSH a0
	NEXT

	defcode "0<>",3,,ZNEQU, ZEQU	// top of stack not 0?
	POP a0
	sltu a0, zero, a0
	PUSH a0
	NEXT

	defcode "0<",2,,ZLT, ZNEQU	// comparisons with 0
	POP a0
	slt a0, a0, zero
	PUSH a0
	NEXT

	defcode "0>",2,,ZGT, ZLT
	POP a0
	slt a0, zero, a0
	PUSH a0
	NEXT

	defcode "0<=",3,,ZLE, ZGT
	POP a0
	slt t0, zero, a0
	li t1, 1
	subw t0, t1, t0
	PUSH t0
	NEXT

	defcode "0>=",3,,ZGE, ZLE
	POP a0
	slt t0, a0, zero
	li t1, 1
	subw t0, t1, t0
	PUSH t0
	NEXT

	defcode "AND",3,,AND, ZGE	// bitwise AND
	POP a0
	POP a1
	and a0, a0, a1
	PUSH a0
	NEXT

	defcode "OR",2,,OR, AND	// bitwise OR
	POP a0
	POP a1
	or a0, a0, a1
	PUSH a0
	NEXT

	defcode "XOR",3,,XOR, OR	// bitwise XOR
	POP a0
	POP a1
	xor a0, a0, a1
	PUSH a0
	NEXT

	defcode "INVERT",6,,INVERT, XOR // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
	POP a0
	not a0, a0
	PUSH a0
	NEXT

/*
	RETURNING FROM FORTH WORDS ----------------------------------------------------------------------

	Time to talk about what happens when we EXIT a function.  In this diagram QUADRUPLE has called
	DOUBLE, and DOUBLE is about to exit (look at where s1 is pointing):

		QUADRUPLE
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
		| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+	   	   | addr of +        |
						   +------------------+
					     s1 -> | addr of EXIT     |
						   +------------------+

	What happens when the + function does NEXT?  Well, the following code is executed.
*/

	defcode "EXIT",4,,EXIT, INVERT
	POPRSP s1		// pop return stack into s1
	NEXT

/*
	EXIT gets the old s1 which we saved from before on the return stack, and puts it in s1.
	So after this (but just before NEXT) we get:

		QUADRUPLE
		+------------------+
		| codeword         |
		+------------------+		   DOUBLE
		| addr of DOUBLE  ---------------> +------------------+
		+------------------+               | codeword         |
	  s1 ->	| addr of DOUBLE   |		   +------------------+
		+------------------+	   	   | addr of DUP      |
		| addr of EXIT	   |		   +------------------+
		+------------------+	   	   | addr of +        |
						   +------------------+
						   | addr of EXIT     |
						   +------------------+

	And NEXT just completes the job by, well, in this case just by calling DOUBLE again :-)

	LITERALS ----------------------------------------------------------------------

	The final point I "glossed over" before was how to deal with functions that do anything
	apart from calling other functions.  For example, suppose that DOUBLE was defined like this:

	: DOUBLE 2 * ;

	It does the same thing, but how do we compile it since it contains the literal 2?  One way
	would be to have a function called "2" (which you'd have to write in assembler), but you'd need
	a function for every single literal that you wanted to use.

	FORTH solves this by compiling the function using a special word called LIT:

	+---------------------------+-------+-------+-------+-------+-------+
	| (usual header of DOUBLE)  | DOCOL | LIT   | 2     | *     | EXIT  |
	+---------------------------+-------+-------+-------+-------+-------+

	LIT is executed in the normal way, but what it does next is definitely not normal.  It
	looks at s1 (which now points to the number 2), grabs it, pushes it on the stack, then
	manipulates s1 in order to skip the number as if it had never been there.

	What's neat is that the whole grab/manipulate can be done using two RISC-V instructions.
	Rather than me drawing more ASCII-art diagrams, see if you can find out how LIT works:
*/

	defcode "LIT",3,,LIT, EXIT
	// s1 points to the next command, but in this case it points to the next
	// literal 32 bit integer.  Get that literal into a0 and increment s1.
	lw a0, 0(s1)
	PUSH a0			// push the literal number on to stack
	addi s1, s1, 4		// skip next command
	NEXT

/*
	MEMORY ----------------------------------------------------------------------

	As important point about FORTH is that it gives you direct access to the lowest levels
	of the machine.  Manipulating memory directly is done frequently in FORTH, and these are
	the primitive words for doing it.
*/

	defcode "!",1,,STORE, LIT
	POP a0			// address to store at
	POP a1			// data to store there
	sw a1, 0(a0)	// store it
	NEXT

	defcode "@",1,,FETCH, STORE
	POP a0			// address to fetch
	lw a1, 0(a0)	// fetch it
	PUSH a1			// push value onto stack
	NEXT

	defcode "+!",2,,ADDSTORE, FETCH
	POP a0			// address
	POP a1			// the amount to add
	lw a2, 0(a0)
	addw a3, a1, a2	// add it
	sw a3, 0(a0)
	NEXT

	defcode "-!",2,,SUBSTORE, ADDSTORE
	POP a0		// address
	POP a1		// the amount to subtract
	lw a2, 0(a0)
	subw a3, a2, a1
	sw a3, 0(a0)
	NEXT

/*
	! and @ (STORE and FETCH) store 32-bit words.  It's also useful to be able to read and write bytes
	so we also define standard words C@ and C!.

	Byte-oriented operations only work on architectures which permit them.
 */

	defcode "C!",2,,STOREBYTE, SUBSTORE
	POP a0			// address to store at
	POP a1			// data to store there
	sb a1, 0(a0)	// store it
	NEXT

	defcode "C@",2,,FETCHBYTE, STOREBYTE
	POP a0			// address to fetch
	lb a1, 0(a0)		// fetch it
	PUSH a1			// push value onto stack
	NEXT

/* C@C! is a useful byte copy primitive. */
	defcode "C@C!",4,,CCOPY, FETCHBYTE
	POP a0			// destination address
	POP a1			// source address
	lb a2, 0(a1)		// get source character
	sb a2, 0(a0)		// copy to destination
	PUSH a0			// increment destination address
	addiw a1, a1, +4		// increment source address
	PUSH a1
	NEXT

/* and CMOVE is a block copy operation. */
	defcode "CMOVE",5,,CMOVE,CCOPY
	POP a0			// length
	POP a1			// destination address
	POP a2			// source address
	RCALL _COPY_BYTES
	NEXT

/* Copy bytes	
	a0: length	
	a1: destination address	
	a2: source address
*/
_COPY_BYTES:
	slti a4, a0, 4		// jump to copy byte if length is < 4
	bnez a4, 2f
1:	// copy word by word
	lw a3, 0(a2)
	sw a3, 0(a1)		// copy source to destination
	addiw a0, a0, -4		// update length, destination, source
	beqz a0, 3f
	addiw a1, a1, 4
	addiw a2, a2, 4
	slti a4, a0, 4		// check if length is < 4
	beqz a4, 1b
2:	// copy byte
	lb a3, 0(a2)
	sb a3, 0(a1)
	addiw a0, a0, -1
	addiw a1, a1, 1
	addiw a2, a2, 1
	bnez a0, 2b
3:
	ret

/*
	BUILT-IN VARIABLES ----------------------------------------------------------------------

	These are some built-in variables and related standard FORTH words.  Of these, the only one that we
	have discussed so far was LATEST, which points to the last (most recently defined) word in the
	FORTH dictionary.  LATEST is also a FORTH word which pushes the address of LATEST (the variable)
	on to the stack, so you can read or write it using @ and ! operators.  For example, to print
	the current value of LATEST (and this can apply to any FORTH variable) you would do:

	LATEST @ . CR

	To make defining variables shorter, I'm using a macro called defvar, similar to defword and
	defcode above.  (In fact the defvar macro uses defcode to do the dictionary header).
*/

	.macro defvar name, namelen, flags=0, label, initial=0,link
	defcode \name,\namelen,\flags,\label,\link
	la t0, var_\name
	PUSH t0
	NEXT
	.data
	.balign 4
var_\name :
	.int \initial
	.endm

/*
	The built-in variables are:

	STATE		Is the interpreter executing code (0) or compiling a word (non-zero)?
	LATEST		Points to the latest (most recently defined) word in the dictionary.
	HERE		Points to the next free byte of memory.  When compiling, compiled words go here.
	S0		Stores the address of the top of the parameter stack.
	BASE		The current base for printing and reading numbers.

*/
	defvar "STATE",5,,STATE,,CMOVE
	defvar "HERE",4,,HERE,,STATE
	defvar "LATEST",6,,LATEST,name_SYSCALL0,HERE // SYSCALL0 must be last in built-in dictionary
	defvar "S0",2,,SZ,,LATEST
	defvar "BASE",4,,BASE,10,SZ

/*
	BUILT-IN CONSTANTS ----------------------------------------------------------------------

	It's also useful to expose a few constants to FORTH.  When the word is executed it pushes a
	constant value on the stack.

	The built-in constants are:

	VERSION		Is the current version of this FORTH.
	R0		The address of the top of the return stack.
	DOCOL		Pointer to DOCOL.
	F_IMMED		The IMMEDIATE flag's actual value.
	F_HIDDEN	The HIDDEN flag's actual value.
	F_LENMASK	The length mask in the flags/len byte.

	SYS_*		and the numeric codes of various Linux syscalls (from <asm/unistd.h>)
*/

#include <asm/unistd.h>	// you might need this instead

	.macro defconst name, namelen, flags=0, label, value, link
	defcode \name,\namelen,\flags,\label,\link
	li t0, \value
	PUSH t0
	NEXT
	.endm

	// same as defconst but the value is a symbol
	.macro defconstsym name, namelen, flags=0, label, value, link
	defcode \name,\namelen,\flags,\label,\link
	la t0, \value
	PUSH t0
	NEXT
	.endm

	defconst "VERSION",7,,VERSION,JONES_VERSION,BASE
	defconstsym "R0",2,,RZ,return_stack_top,VERSION
	defconstsym "DOCOL",5,,__DOCOL,DOCOL,RZ
	defconst "F_IMMED",7,,__F_IMMED,F_IMMED,__DOCOL
	defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN,__F_IMMED
	defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK,__F_HIDDEN

	defconst "SYS_EXIT",8,,SYS_EXIT,__NR_exit,__F_LENMASK
	defconst "SYS_OPEN",8,,SYS_OPEN,__NR_openat,SYS_EXIT
	defconst "SYS_CLOSE",9,,SYS_CLOSE,__NR_close,SYS_OPEN
	defconst "SYS_READ",8,,SYS_READ,__NR_read,SYS_CLOSE
	defconst "SYS_WRITE",9,,SYS_WRITE,__NR_write,SYS_READ
	defconst "SYS_CREAT",9,,SYS_CREAT,__NR_openat,SYS_WRITE
	defconst "SYS_BRK",7,,SYS_BRK,__NR_brk,SYS_CREAT

	defconst "O_RDONLY",8,,__O_RDONLY,0,SYS_BRK
	defconst "O_WRONLY",8,,__O_WRONLY,1,__O_RDONLY
	defconst "O_RDWR",6,,__O_RDWR,2,__O_WRONLY
	defconst "O_CREAT",7,,__O_CREAT,0100,__O_RDWR
	defconst "O_EXCL",6,,__O_EXCL,0200,__O_CREAT
	defconst "O_TRUNC",7,,__O_TRUNC,01000,__O_EXCL
	defconst "O_APPEND",8,,__O_APPEND,02000,__O_TRUNC
	defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000,__O_APPEND

/*
	RETURN STACK ----------------------------------------------------------------------

	These words allow you to access the return stack.  Recall that the register fp always points to
	the top of the return stack.
*/

	defcode ">R",2,,TOR, __O_NONBLOCK
	POP a0			// pop parameter stack into a0
	PUSHRSP a0		// push it on to the return stack
	NEXT

	defcode "R>",2,,FROMR, TOR
	POPRSP a0		// pop return stack on to a0
	PUSH a0			// and push on to parameter stack
	NEXT

	defcode "RSP@",4,,RSPFETCH, FROMR
	PUSH fp
	NEXT

	defcode "RSP!",4,,RSPSTORE, RSPFETCH
	POP fp
	NEXT

	defcode "RDROP",5,,RDROP, RSPSTORE
	addi fp, fp, +4		// pop return stack and throw away
	NEXT

/*
	PARAMETER (DATA) STACK ----------------------------------------------------------------------

	These functions allow you to manipulate the parameter stack.  Recall that Linux sets up the parameter
	stack for us, and it is accessed through sp.
*/

	defcode "DSP@",4,,DSPFETCH, RDROP
	mv a0, sp
	PUSH a0
	NEXT

	defcode "DSP!",4,,DSPSTORE, DSPFETCH
	POP sp
	NEXT

/*
	INPUT AND OUTPUT ----------------------------------------------------------------------

	These are our first really meaty/complicated FORTH primitives.  I have chosen to write them in
	assembler, but surprisingly in "real" FORTH implementations these are often written in terms
	of more fundamental FORTH primitives.  I chose to avoid that because I think that just obscures
	the implementation.  After all, you may not understand assembler but you can just think of it
	as an opaque block of code that does what it says.

	Let's discuss input first.

	The FORTH word KEY reads the next byte from stdin (and pushes it on the parameter stack).
	So if KEY is called and someone hits the space key, then the number 32 (ASCII code of space)
	is pushed on the stack.

	In FORTH there is no distinction between reading code and reading input.  We might be reading
	and compiling code, we might be reading words to execute, we might be asking for the user
	to type their name -- ultimately it all comes in through KEY.

	The implementation of KEY uses an input buffer of a certain size (defined at the end of this
	file).  It calls the Linux read(2) system call to fill this buffer and tracks its position
	in the buffer using a couple of variables, and if it runs out of input buffer then it refills
	it automatically.  The other thing that KEY does is if it detects that stdin has closed, it
	exits the program, which is why when you hit ^D the FORTH system cleanly exits.

     buffer			      bufftop
	|				 |
	V				 V
	+-------------------------------+--------------------------------------+
	| INPUT READ FROM STDIN ....... | unused part of the buffer            |
	+-------------------------------+--------------------------------------+
			  ^
			  |
		       currkey (next character to read)

	<---------------------- BUFFER_SIZE (4096 bytes) ---------------------->
*/

	.set BUFFER_SIZE, 4096

	defcode "KEY",3,,KEY, DSPSTORE
	RCALL _KEY
	PUSH a0				// push return value on stack
	NEXT
_KEY:
	la t1, currkey
	lw a1, 0(t1)
	la t0, bufftop
	lw t0, 0(t0)
	sltu a2, a1, t0
	beqz a2, 1f			// exhausted the input buffer?
	lb a0, 0(a1)		// get next key from input buffer
	addiw a3, a1, +1
	sw a3, 0(t1)		// increment currkey
	ret

1:	// Out of input; use read(2) to fetch more input from stdin.
	mv a0, zero			// 1st param: stdin
	la a1, buffer		// 2nd param: buffer
	la t0, currkey
	sw a1, 0(t0)
	li a2, BUFFER_SIZE	// 3rd param: max length
	li a7, __NR_read	// syscall: read
	ecall
	slt t0, zero, a0	// If a0 <= 0, then exit.
	beqz t0, 2f
	addw a0, a0, a1		// buffer+a0 = bufftop
	la t0, bufftop
	sw a0, 0(t0)
	j _KEY

2:	// Error or end of input: exit the program.
	li a7, __NR_exit	// syscall: exit
	ecall

	.data
	.balign 4
currkey:
	.int buffer		// Current place in input buffer (next character to read).
bufftop:
	.int buffer		// Last valid data in input buffer + 1.

/*
	By contrast, output is much simpler.  The FORTH word EMIT writes out a single byte to stdout.
	This implementation just uses the write system call.  No attempt is made to buffer output, but
	it would be a good exercise to add it.
*/

	defcode "EMIT",4,,EMIT, KEY
	POP a0
	RCALL _EMIT
	NEXT
_EMIT:
	// write needs the address of the byte to write
	la a1, emit_scratch     // 2nd param: address
	sb a0, 0(a1)

	li a0, 1		// 1st param: stdout

	li a2, 1 		// 3rd param: nbytes = 1

	li a7, __NR_write	// write syscall
	ecall
	ret

	.data			// NB: easier to fit in the .data section
emit_scratch:
	.space 1		// scratch used by EMIT

/*
	Back to input, WORD is a FORTH word which reads the next full word of input.

	What it does in detail is that it first skips any blanks (spaces, tabs, newlines and so on).
	Then it calls KEY to read characters into an internal buffer until it hits a blank.  Then it
	calculates the length of the word it read and returns the address and the length as
	two words on the stack (with the length at the top of stack).

	Notice that WORD has a single internal buffer which it overwrites each time (rather like
	a static C string).  Also notice that WORD's internal buffer is just 32 bytes long and
	there is NO checking for overflow.  31 bytes happens to be the maximum length of a
	FORTH word that we support, and that is what WORD is used for: to read FORTH words when
	we are compiling and executing code.  The returned strings are not NUL-terminated.

	Start address+length is the normal way to represent strings in FORTH (not ending in an
	ASCII NUL character as in C), and so FORTH strings can contain any character including NULs
	and can be any length.

	WORD is not suitable for just reading strings (eg. user input) because of all the above
	peculiarities and limitations.

	Note that when executing, you'll see:
	WORD FOO
	which puts "FOO" and length 3 on the stack, but when compiling:
	: BAR WORD FOO ;
	is an error (or at least it doesn't do what you might expect).  Later we'll talk about compiling
	and immediate mode, and you'll understand why.
*/


	/* Macro to help us check a character is or is'nt blank. 
	Set 0 to the result register if the src register is a blank char */
	.macro IS_BLANK result, src
	addiw \result, \src, -' '
	beqz \result, 42f
	addiw \result, \src, -'\n'
	beqz \result, 42f
	addiw \result, \src, -'\t'
42:
	.endm

	defcode "WORD",4,,WORD, EMIT
	RCALL _WORD
	PUSH a0		// push base address
	PUSH a1		// push length
	NEXT

_WORD:
	/* Search for first non-blank character.  Also skip \ comments. */
1:
	RCALL _KEY		// get next key, returned in a0
	addiw a1, a0, -'\\'	// start of a comment?
	beqz a1, 4f		// if so, skip the comment
	IS_BLANK a1, a0
	beqz a1, 1b		// if so, keep looking

	/* Search for the end of the word, storing chars as we go. */
	la a2, word_buffer	// pointer to return buffer
2:
	sb a0, 0(a2)		// add character to return buffer
	addiw a2, a2, +1
	PUSH a2
	RCALL _KEY		// get next key, returned in a0
	POP a2
	IS_BLANK a1, a0	// is blank?
	beqz a1, 3f		// if not, keep looping
	j 2b
3:
	/* Return the word (well, the static buffer) and length. */
	la a0, word_buffer	// return address of the word
	subw a1, a2, a0		// return length of the word
	ret

	/* Code to skip \ comments to end of the current line. */
4:
	RCALL _KEY
	addiw a1, a0, -'\n'	// end of line yet?
	bnez a1, 4b
	j 1b

	.data			// NB: easier to fit in the .data section
	// A static buffer where WORD returns.  Subsequent calls
	// overwrite this buffer.  Maximum word length is 32 chars.
word_buffer:
	.space 32

/*
	As well as reading in words we'll need to read in numbers and for that we are using a function
	called NUMBER.  This parses a numeric string such as one returned by WORD and pushes the
	number on the parameter stack.

	The function uses the variable BASE as the base (radix) for conversion, so for example if
	BASE is 2 then we expect a binary number.  Normally BASE is 10.

	If the word starts with a '-' character then the returned value is negative.

	If the string can't be parsed as a number (or contains characters outside the current BASE)
	then we need to return an error indication.  So NUMBER actually returns two items on the stack.
	At the top of stack we return the number of unconverted characters (ie. if 0 then all characters
	were converted, so there is no error).  Second from top of stack is the parsed number or a
	partial value if there was an error.
*/
	defcode "NUMBER",6,,NUMBER, WORD
	POP a1		// length of string
	POP a2		// start address of string
	RCALL _NUMBER
	PUSH a0		// parsed number
	PUSH a1		// number of unparsed characters (0 = no error)
	NEXT

_NUMBER:
	mv a0, zero
	beqz a1, 5f		// trying to parse a zero-length string is an error, but will return 0.

	la a3, var_BASE
	lw a3, 0(a3)		// get BASE

	// Check if first character is '-'.
	lb a4, 0(a2)		// a4 = first character in string
	addiw a2, a2, +1
	addiw a5, a4, -'-'	// negative number?
	bnez a5, 2f		// number is negative if a5 = 0
	addiw a1, a1, -1
	bnez a1, 1f
	li a1, 1		// error: string is only '-'.
	ret

	// Loop reading digits.
1:	mul a0, a0, a3		// a0 *= BASE
	lb a4, 0(a2)		// a4 = next character in string
	addiw a2, a2, +1

	// Convert 0-9, A-Z to a number 0-35.
2:	sltiu t0, a4, '0'	// < '0'?
	bnez t0, 4f
	addiw a4, a4, -'0'
	sltiu t0, a4, 10	// <= '9'?
	bnez t0, 3f
	sltiu t0, a4, 17	// < 'A'? (17 is 'A' - '0')
	bnez t0, 4f
	addiw a4, a4, -7	// Char - 'A' + 10

3:	slt t0, a4, a3		// >= BASE?
	beqz t0, 4f

	// OK, so add it to a0 and loop.
	addw a0, a0, a4
	addiw a1, a1, -1
	bnez a1, 1b

4:	// Negate the result if first character was '-' (a5 = 0?).
	bnez a5, 5f
	neg a0, a0

5:	ret

/*
	DICTIONARY LOOK UPS ----------------------------------------------------------------------

	We're building up to our prelude on how FORTH code is compiled, but first we need yet more infrastructure.

	The FORTH word FIND takes a string (a word as parsed by WORD -- see above) and looks it up in the
	dictionary.  What it actually returns is the address of the dictionary header, if it finds it,
	or 0 if it didn't.

	So if DOUBLE is defined in the dictionary, then WORD DOUBLE FIND returns the following pointer:

    pointer to this
	|
	|
	V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+

	See also >CFA and >DFA.

	FIND doesn't find dictionary entries which are flagged as HIDDEN.  See below for why.
*/

	defcode "FIND",4,,FIND, NUMBER
	POP a1			// a1 = length
	POP a2			// a2 = address
	RCALL _FIND
	PUSH a0			// a0 = address of dictionary entry (or NULL)
	NEXT

_FIND:
	// Now we start searching backwards through the dictionary for this word.
	la a0, var_LATEST	// LATEST points to name header of the latest word in the dictionary
	lw a0, 0(a0)
1:	beqz a0, 4f		// NULL pointer?  (end of the linked list)

	// Compare the length expected and the length of the word.
	// Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
	// this won't pick the word (the length will appear to be wrong).
	lb a3, 4(a0)		// a0 = flags+length field
	andi a3, a3, (F_HIDDEN|F_LENMASK) // a0 = name length
	subw t0, a3, a1		// Length is the same?
	bnez t0, 3f

	// Compare the strings in detail.
	mv t0, a0
	mv t2, a2
2:	lb t1, 5(t0) 		// Dictionary string we are checking against.
	lb t3, 0(t2)
	subw t1, t1, t3		// Compare the strings.
	bnez t1, 3f		// Not the same.
	addiw t0, t0, 1
	addiw t2, t2, 1
	addiw a3, a3, -1
	bnez a3, 2b

	// The strings are the same - return the header pointer in a0
	ret

3:	lw a0, 0(a0)		// Move back through the link field to the previous word
	j 1b			// .. and loop.

4:	// Not found.
	mv a0, zero		// Return zero to indicate not found.
	ret

/*
	FIND returns the dictionary pointer, but when compiling we need the codeword pointer (recall
	that FORTH definitions are compiled into lists of codeword pointers).  The standard FORTH
	word >CFA turns a dictionary pointer into a codeword pointer.

	The example below shows the result of:

		WORD DOUBLE FIND >CFA

	FIND returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	V					   V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	Notes:

	Because names vary in length, this isn't just a simple increment.

	In this FORTH you cannot easily turn a codeword pointer back into a dictionary entry pointer, but
	that is not true in most FORTH implementations where they store a back pointer in the definition
	(with an obvious memory/complexity cost).  The reason they do this is that it is useful to be
	able to go backwards (codeword -> dictionary entry) in order to decompile FORTH definitions
	quickly.

	What does CFA stand for?  My best guess is "Code Field Address".
*/

	defcode ">CFA",4,,TCFA, FIND
	POP a0
	RCALL _TCFA
	PUSH a0
	NEXT
_TCFA:
	lb a1, 4(a0)		// Load flags+len into a0.
	andi a1, a1, F_LENMASK	// Just the length, not the flags.
	addiw a0, a0, 5		// Skip link pointer and flags+len byte.
	addw a0, a0, a1		// Skip the name.
	addiw a0, a0, 3		// The codeword is 4-byte aligned.
	andi a0, a0, ~3
	ret

/*
	Related to >CFA is >DFA which takes a dictionary entry address as returned by FIND and
	returns a pointer to the first data field.

	FIND returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	|					   |	>DFA converts it to a pointer to this
	|					   |		 |
	V					   V		 V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	(Note to those following the source of FIG-FORTH / ciforth: My >DFA definition is
	different from theirs, because they have an extra indirection).

	You can see that >DFA is easily defined in FORTH just by adding 4 to the result of >CFA.
*/

	defword ">DFA",4,,TDFA, TCFA
	.int TCFA		// >CFA		(get code field address)
	.int INCR4		// 4+		(add 4 to it to get to next word)
	.int EXIT		// EXIT		(return from FORTH word)

/*
	COMPILING ----------------------------------------------------------------------

	Now we'll talk about how FORTH compiles words.  Recall that a word definition looks like this:

		: DOUBLE DUP + ;

	and we have to turn this into:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
	   ^       len                         pad  codeword      |
	   |							  V
	  LATEST points here				points to codeword of DUP

	There are several problems to solve.  Where to put the new word?  How do we read words?  How
	do we define the words : (COLON) and ; (SEMICOLON)?

	FORTH solves this rather elegantly and as you might expect in a very low-level way which
	allows you to change how the compiler works on your own code.

	FORTH has an INTERPRET function (a true interpreter this time, not DOCOL) which runs in a
	loop, reading words (using WORD), looking them up (using FIND), turning them into codeword
	pointers (using >CFA) and deciding what to do with them.

	What it does depends on the mode of the interpreter (in variable STATE).

	When STATE is zero, the interpreter just runs each word as it looks them up.  This is known as
	immediate mode.

	The interesting stuff happens when STATE is non-zero -- compiling mode.  In this mode the
	interpreter appends the codeword pointer to user memory (the HERE variable points to the next
	free byte of user memory -- see DATA SEGMENT section below).

	So you may be able to see how we could define : (COLON).  The general plan is:

	(1) Use WORD to read the name of the function being defined.

	(2) Construct the dictionary entry -- just the header part -- in user memory:

    pointer to previous word (from LATEST)			+-- Afterwards, HERE points here, where
	   ^							|   the interpreter will start appending
	   |							V   codewords.
	+--|------+---+---+---+---+---+---+---+---+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      |
	+---------+---+---+---+---+---+---+---+---+------------+
		   len                         pad  codeword

	(3) Set LATEST to point to the newly defined word, ...

	(4) .. and most importantly leave HERE pointing just after the new codeword.  This is where
	    the interpreter will append codewords.

	(5) Set STATE to 1.  This goes into compile mode so the interpreter starts appending codewords to
	    our partially-formed header.

	After : has run, our input is here:

	: DOUBLE DUP + ;
		 ^
		 |
		Next byte returned by KEY will be the 'D' character of DUP

	so the interpreter (now it's in compile mode, so I guess it's really the compiler) reads "DUP",
	looks it up in the dictionary, gets its codeword pointer, and appends it:

									     +-- HERE updated to point here.
									     |
									     V
	+---------+---+---+---+---+---+---+---+---+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        |
	+---------+---+---+---+---+---+---+---+---+------------+------------+
		   len                         pad  codeword

	Next we read +, get the codeword pointer, and append it:

											  +-- HERE updated to point here.
											  |
											  V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+
		   len                         pad  codeword

	The issue is what happens next.  Obviously what we _don't_ want to happen is that we
	read ";" and compile it and go on compiling everything afterwards.

	At this point, FORTH uses a trick.  Remember the length byte in the dictionary definition
	isn't just a plain length byte, but can also contain flags.  One flag is called the
	IMMEDIATE flag (F_IMMED in this code).  If a word in the dictionary is flagged as
	IMMEDIATE then the interpreter runs it immediately _even if it's in compile mode_.

	This is how the word ; (SEMICOLON) works -- as a word flagged in the dictionary as IMMEDIATE.

	And all it does is append the codeword for EXIT on to the current definition and switch
	back to immediate mode (set STATE back to 0).  Shortly we'll see the actual definition
	of ; and we'll see that it's really a very simple definition, declared IMMEDIATE.

	After the interpreter reads ; and executes it 'immediately', we get this:

	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
		   len                         pad  codeword					       ^
												       |
												      HERE
	STATE is set to 0.

	And that's it, job done, our new definition is compiled, and we're back in immediate mode
	just reading and executing words, perhaps including a call to test our new word DOUBLE.

	The only last wrinkle in this is that while our word was being compiled, it was in a
	half-finished state.  We certainly wouldn't want DOUBLE to be called somehow during
	this time.  There are several ways to stop this from happening, but in FORTH what we
	do is flag the word with the HIDDEN flag (F_HIDDEN in this code) just while it is
	being compiled.  This prevents FIND from finding it, and thus in theory stops any
	chance of it being called.

	The above explains how compiling, : (COLON) and ; (SEMICOLON) works and in a moment I'm
	going to define them.  The : (COLON) function can be made a little bit more general by writing
	it in two parts.  The first part, called CREATE, makes just the header:

						   +-- Afterwards, HERE points here.
						   |
						   V
	+---------+---+---+---+---+---+---+---+---+
	| LINK    | 6 | D | O | U | B | L | E | 0 |
	+---------+---+---+---+---+---+---+---+---+
		   len                         pad

	and the second part, the actual definition of : (COLON), calls CREATE and appends the
	DOCOL codeword, so leaving:

								+-- Afterwards, HERE points here.
								|
								V
	+---------+---+---+---+---+---+---+---+---+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      |
	+---------+---+---+---+---+---+---+---+---+------------+
		   len                         pad  codeword

	CREATE is a standard FORTH word and the advantage of this split is that we can reuse it to
	create other types of words (not just ones which contain code, but words which contain variables,
	constants and other data).
*/

	defcode "CREATE",6,,CREATE, TDFA

	// Get the name length and address.

	POP a0		// a0 = length
	POP a2		// a2 = address of name

	// Link pointer.

	la a1, var_HERE		// a1 is the address of the header
	lw a1, 0(a1)
	la a3, var_LATEST	
	lw t0, 0(a3)		// Get link pointer
	sw t0, 0(a1)		// and store it in the header.
	addi a1, a1, 4

	// Length byte and the word itself.

	sb a0, 0(a1)		// Store the length/flags byte.
	addiw a1, a1, 1
	PUSH a0			// save length and destination address
	PUSH a1
	RCALL _COPY_BYTES	// Copy the word
	POP a1
	POP a0
	addw a1, a1, a0		// a1 is the address of the end of word
	addiw a1, a1, 3		// Align to next 4 byte boundary.
	andi a1, a1, ~3

	// Update LATEST and HERE.
	la t0, var_HERE
	la t1, var_LATEST
	lw t2, 0(t0)
	sw t2, 0(t1)
	sw a1, 0(t0)
	NEXT

/*
	Because I want to define : (COLON) in FORTH, not assembler, we need a few more FORTH words
	to use.

	The first is , (COMMA) which is a standard FORTH word which appends a 32 bit integer to the user
	memory pointed to by HERE, and adds 4 to HERE.  So the action of , (COMMA) is:

							previous value of HERE
								 |
								 V
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 |             |  <data>    |
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
		   len                         pad		              ^
									      |
									new value of HERE

	and <data> is whatever 32 bit integer was at the top of the stack.

	, (COMMA) is quite a fundamental operation when compiling.  It is used to append codewords
	to the current word that is being compiled.
*/

	defcode ",",1,,COMMA, CREATE
	POP a0		// Code pointer to store.
	RCALL _COMMA
	NEXT
_COMMA:
	la t0, var_HERE		// HERE
	lw t1, 0(t0)
	sw a0, 0(t1)		// Store it.
	addiw t1, t1, 4		// Increment
	sw t1, 0(t0)		// Update HERE
	ret

/*
	Our definitions of : (COLON) and ; (SEMICOLON) will need to switch to and from compile mode.

	Immediate mode vs. compile mode is stored in the global variable STATE, and by updating this
	variable we can switch between the two modes.

	For various reasons which may become apparent later, FORTH defines two standard words called
	[ and ] (LBRAC and RBRAC) which switch between modes:

	Word	Assembler	Action		Effect
	[	LBRAC		STATE := 0	Switch to immediate mode.
	]	RBRAC		STATE := 1	Switch to compile mode.

	[ (LBRAC) is an IMMEDIATE word.  The reason is as follows: If we are in compile mode and the
	interpreter saw [ then it would compile it rather than running it.  We would never be able to
	switch back to immediate mode!  So we flag the word as IMMEDIATE so that even in compile mode
	the word runs immediately, switching us back to immediate mode.
*/

	defcode "[",1,F_IMMED,LBRAC, COMMA
	la t0, var_STATE
	sw zero, 0(t0)	// Set STATE to 0.
	NEXT

	defcode "]",1,,RBRAC, LBRAC
	la t0, var_STATE
	la t1, 1
	sw t1, 0(t0)	// Set STATE to 1.
	NEXT

/*
	Now we can define : (COLON) using CREATE.  It just calls CREATE, appends DOCOL (the codeword), sets
	the word HIDDEN and goes into compile mode.
*/

	defword ":",1,,COLON, RBRAC
	.int WORD		// Get the name of the new word
	.int CREATE		// CREATE the dictionary entry / header
	.int LIT, DOCOL, COMMA	// Append DOCOL  (the codeword).
	.int LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
	.int RBRAC		// Go into compile mode.
	.int EXIT		// Return from the function.

/*
	; (SEMICOLON) is also elegantly simple.  Notice the F_IMMED flag.
*/

	defword ";",1,F_IMMED,SEMICOLON, COLON
	.int LIT, EXIT, COMMA	// Append EXIT (so the word will return).
	.int LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
	.int LBRAC		// Go back to IMMEDIATE mode.
	.int EXIT		// Return from the function.

/*
	EXTENDING THE COMPILER ----------------------------------------------------------------------

	Words flagged with IMMEDIATE (F_IMMED) aren't just for the FORTH compiler to use.  You can define
	your own IMMEDIATE words too, and this is a crucial aspect when extending basic FORTH, because
	it allows you in effect to extend the compiler itself.  Does gcc let you do that?

	Standard FORTH words like IF, WHILE, ." and so on are all written as extensions to the basic
	compiler, and are all IMMEDIATE words.

	The IMMEDIATE word toggles the F_IMMED (IMMEDIATE flag) on the most recently defined word,
	or on the current word if you call it in the middle of a definition.

	Typical usage is:

	: MYIMMEDWORD IMMEDIATE
		...definition...
	;

	but some FORTH programmers write this instead:

	: MYIMMEDWORD
		...definition...
	; IMMEDIATE

	The two usages are equivalent, to a first approximation.
*/

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE,SEMICOLON
	la a0, var_LATEST	// LATEST word.
	lw a0, 0(a0)
	addiw a0, a0, 4		// Point to name/flags byte.
	lb t0, 0(a0)
	xori t0, t0, F_IMMED	// Toggle the IMMED bit.
	sb t0, 0(a0)
	NEXT

/*
	'addr HIDDEN' toggles the hidden flag (F_HIDDEN) of the word defined at addr.  To hide the
	most recently defined word (used above in : and ; definitions) you would do:

		LATEST @ HIDDEN

	'HIDE word' toggles the flag on a named 'word'.

	Setting this flag stops the word from being found by FIND, and so can be used to make 'private'
	words.  For example, to break up a large word into smaller parts you might do:

		: SUB1 ... subword ... ;
		: SUB2 ... subword ... ;
		: SUB3 ... subword ... ;
		: MAIN ... defined in terms of SUB1, SUB2, SUB3 ... ;
		HIDE SUB1
		HIDE SUB2
		HIDE SUB3

	After this, only MAIN is 'exported' or seen by the rest of the program.
*/

	defcode "HIDDEN",6,,HIDDEN,IMMEDIATE
	POP a0			// Dictionary entry.
	addiw a0, a0, 4		// Point to name/flags byte.
	lb t0, 0(a0)
	xori t0, t0, F_HIDDEN	// Toggle the HIDDEN bit.
	sb t0, 0(a0)
	NEXT

	defword "HIDE",4,,HIDE,HIDDEN
	.int WORD		// Get the word (after HIDE).
	.int FIND		// Look up in the dictionary.
	.int HIDDEN		// Set F_HIDDEN flag.
	.int EXIT		// Return.

/*
	' (TICK) is a standard FORTH word which returns the codeword pointer of the next word.

	The common usage is:

	' FOO ,

	which appends the codeword of FOO to the current word we are defining (this only works in compiled code).

	You tend to use ' in IMMEDIATE words.  For example an alternate (and rather useless) way to define
	a literal 2 might be:

	: LIT2 IMMEDIATE
		' LIT ,		\ Appends LIT to the currently-being-defined word
		2 ,		\ Appends the number 2 to the currently-being-defined word
	;

	So you could do:

	: DOUBLE LIT2 * ;

	(If you don't understand how LIT2 works, then you should review the material about compiling words
	and immediate mode).

	This definition of ' uses a cheat which I copied from buzzard92.  As a result it only works in
	compiled code.  It is possible to write a version of ' based on WORD, FIND, >CFA which works in
	immediate mode too.
*/
	defcode "'",1,,TICK,HIDE
	lw t0, 0(s1)		// Get the address of the next word and skip it.
	PUSH t0			// Push it on the stack.
	addi s1, s1, 4
	NEXT

/*
	BRANCHING ----------------------------------------------------------------------

	It turns out that all you need in order to define looping constructs, IF-statements, etc.
	are two primitives.

	BRANCH is an unconditional branch. 0BRANCH is a conditional branch (it only branches if the
	top of stack is zero).

	The diagram below shows how BRANCH works in some imaginary compiled word.  When BRANCH executes,
	s1 starts by pointing to the offset field (compare to LIT above):

	+---------------------+-------+---- - - ---+------------+------------+---- - - - ----+------------+
	| (Dictionary header) | DOCOL |            | BRANCH     | offset     | (skipped)     | word       |
	+---------------------+-------+---- - - ---+------------+-----|------+---- - - - ----+------------+
								   ^  |			      ^
								   |  |			      |
								   |  +-----------------------+
								  s1 added to offset

	The offset is added to s1 to make the new s1, and the result is that when NEXT runs, execution
	continues at the branch target.  Negative offsets work as expected.

	0BRANCH is the same except the branch happens conditionally.

	Now standard FORTH words such as IF, THEN, ELSE, WHILE, REPEAT, etc. can be implemented entirely
	in FORTH.  They are IMMEDIATE words which append various combinations of BRANCH or 0BRANCH
	into the word currently being compiled.

	As an example, code written like this:

		condition-code IF true-part THEN rest-code

	compiles to:

		condition-code 0BRANCH OFFSET true-part rest-code
					  |		^
					  |		|
					  +-------------+
*/

	defcode "BRANCH",6,,BRANCH,TICK
	lw t0, 0(s1)
	add s1, s1, t0		// add the offset to the instruction pointer
	NEXT

	defcode "0BRANCH",7,,ZBRANCH,BRANCH
	POP t0			// top of stack is zero?
	beqz t0, code_BRANCH	// if so, jump back to the branch function above
	addi s1, s1, 4		// otherwise we need to skip the offset
	NEXT

/*
	LITERAL STRINGS ----------------------------------------------------------------------

	LITSTRING is a primitive used to implement the ." and S" operators (which are written in
	FORTH).  See the definition of those operators later.

	TELL just prints a string.  It's more efficient to define this in assembly because we
	can make it a single Linux syscall.
*/

	defcode "LITSTRING",9,,LITSTRING,ZBRANCH
	lw a0, 0(s1)		// get the length of the string
	addi s1, s1, 4
	PUSH s1			// push the address of the start of the string
	push a0			// push it on the stack
	add s1, s1, a0		// skip past the string
 	addi s1, s1, 3		// but round up to next 4 byte boundary
	andi s1, s1, ~3
	NEXT

	defcode "TELL",4,,TELL,LITSTRING
	li a0, 1		// 1st param: stdout
	POP a2			// 3rd param: length of string
	POP a1			// 2nd param: address of string
	li a7, __NR_write	// write syscall
	ecall
	NEXT

/*
	QUIT AND INTERPRET ----------------------------------------------------------------------

	QUIT is the first FORTH function called, almost immediately after the FORTH system "boots".
	As explained before, QUIT doesn't "quit" anything.  It does some initialisation (in particular
	it clears the return stack) and it calls INTERPRET in a loop to interpret commands.  The
	reason it is called QUIT is because you can call it from your own FORTH words in order to
	"quit" your program and start again at the user prompt.

	INTERPRET is the FORTH interpreter ("toploop", "toplevel" or "REPL" might be a more accurate
	description -- see: http://en.wikipedia.org/wiki/REPL).
*/

	// QUIT must not return (ie. must not call EXIT).
	defword "QUIT",4,,QUIT,TELL
	.int RZ,RSPSTORE	// R0 RSP!, clear the return stack
	.int INTERPRET		// interpret the next word
	.int BRANCH,-8		// and loop (indefinitely)

/*
	This interpreter is pretty simple, but remember that in FORTH you can always override
	it later with a more powerful one!
 */
	defcode "INTERPRET",9,,INTERPRET,QUIT
	RCALL _WORD		// Returns a1 = length, a0 = pointer to word.

	// Is it in the dictionary? Use s2 as the interpret_is_lit flag.
	mv s2, zero		// Not a literal number (not yet anyway ...)
	mv a2, a0
	RCALL _FIND		// Returns a0 = pointer to header or 0 if not found.
	beqz a0, 1f

	// In the dictionary.  Is it an IMMEDIATE codeword?
	lb t0, 4(a0)		// Get name+flags.
	PUSH t0			// Just save it for now.
	RCALL _TCFA		// Convert dictionary entry (in a0) to codeword pointer.
	POP t0
	andi t0, t0, F_IMMED	// Is IMMED flag set?
	bnez t0, 4f		// If IMMED, jump straight to executing.

	j 2f

1:	// Not in the dictionary (not a word) so assume it's a literal number.
	addiw s2, s2, 1		// inc interpret_is_lit
	RCALL _NUMBER		// Returns the parsed number in a0, a1 > 0 if error
	bnez a1, 6f
	mv a1, a0
	la a0, LIT		// The word is LIT

2:	// Are we compiling or executing?
	la t1, var_STATE
	lw t0, 0(t1)
	beqz t0, 4f		// Jump if executing.

	// Compiling - just append the word to the current dictionary definition.
	RCALL _COMMA
	beqz s2, 3f		// Was it a literal?
	mv a0, a1		// Yes, so LIT is followed by a number.
	RCALL _COMMA
3:	NEXT

4:	// Executing - run it!
	bnez s2, 5f		// Literal?

	// Not a literal, execute it now.  This never returns, but the codeword will
	// eventually call NEXT which will reenter the loop in QUIT.
	lw t0, 0(a0)
	jr t0

5:	// Executing a literal, which means push it on the stack.
	PUSH a1
	NEXT

6:	// Parse error (not a known word or a number in the current BASE).
	// Print an error message followed by up to 40 characters of context.
	li a0, 2		// 1st param: stderr
	la a1, errmsg		// 2nd param: error message
	la t0, errmsgend
	subw a2, t0, a1		// 3rd param: length of string
	li a7, __NR_write	// write syscall
	ecall

	la a1, currkey		// the error occurred just before currkey position
	lw a1, 0(a1)
	la t0, buffer
	subw a2, a1, t0		// a2 = currkey - buffer (length in buffer before currkey)
	li t2, 40
	slt t0, t2, a2		// if > 40, then print only 40 characters
	beqz t0, 7f
	li a2, 40
7:	subw a1, a1, a2		// a1 = start of area to print, a2 = length
	li a0, 2
	li a7, __NR_write	// write syscall
	ecall

	la a1, errmsgnl		// newline
	li a2, 1
	li a0, 2
	li a7, __NR_write	// write syscall
	ecall

	NEXT

	.section .rodata
errmsg: .ascii "PARSE ERROR: "
errmsgend:
errmsgnl: .ascii "\n"

	.data			// NB: easier to fit in the .data section
	.balign 4

/*
	ODDS AND ENDS ----------------------------------------------------------------------

	CHAR puts the ASCII code of the first character of the following word on the stack.  For example
	CHAR A puts 65 on the stack.

	EXECUTE is used to run execution tokens.  See the discussion of execution tokens in the
	FORTH code for more details.

	SYSCALL0, SYSCALL1, SYSCALL2, SYSCALL3 make a standard Linux system call.  (See <asm/unistd.h>
	for a list of system call numbers).  As their name suggests these forms take between 0 and 3
	syscall parameters, plus the system call number.

	In this FORTH, SYSCALL0 must be the last word in the built-in (assembler) dictionary because we
	initialise the LATEST variable to point to it.  This means that if you want to extend the assembler
	part, you must put new words before SYSCALL0, or else change how LATEST is initialised.
*/

	defcode "CHAR",4,,CHAR,INTERPRET
	RCALL _WORD		// Returns a1 = length, a0 = pointer to word.
	lb t0, 0(a0)		// Get the first character of the word.
	PUSH t0			// Push it onto the stack.
	NEXT

	defcode "EXECUTE",7,,EXECUTE,CHAR
	POP a0			// Get xt into a0
	jr a0			// and jump to it.
				// After xt runs its NEXT will continue executing the current word.

	defcode "SYSCALL3",8,,SYSCALL3,EXECUTE
	POP a7			// System call number (see <asm/unistd.h>)
	POP a0			// First parameter.
	POP a1			// Second parameter
	POP a2			// Third parameter
	ecall
	PUSH a0			// Result (negative for -errno)
	NEXT

	defcode "SYSCALL2",8,,SYSCALL2,SYSCALL3
	POP a7			// System call number (see <asm/unistd.h>)
	POP a0			// First parameter.
	POP a1			// Second parameter
	ecall
	PUSH a0			// Result (negative for -errno)
	NEXT

	defcode "SYSCALL1",8,,SYSCALL1,SYSCALL2
	POP a7			// System call number (see <asm/unistd.h>)
	POP a0			// First parameter.
	ecall
	PUSH a0			// Result (negative for -errno)
	NEXT

	defcode "SYSCALL0",8,,SYSCALL0,SYSCALL1
	POP a7			// System call number (see <asm/unistd.h>)
	ecall
	PUSH a0			// Result (negative for -errno)
	NEXT

/*
	DATA SEGMENT ----------------------------------------------------------------------

	Here we set up the Linux data segment, used for user definitions and variously known as just
	the 'data segment', 'user memory' or 'user definitions area'.  It is an area of memory which
	grows upwards and stores both newly-defined FORTH words and global variables of various
	sorts.

	It is completely analogous to the C heap, except there is no generalised 'malloc' and 'free'
	(but as with everything in FORTH, writing such functions would just be a Simple Matter
	Of Programming).  Instead in normal use the data segment just grows upwards as new FORTH
	words are defined/appended to it.

	There are various "features" of the GNU toolchain which make setting up the data segment
	more complicated than it really needs to be.  One is the GNU linker which inserts a random
	"build ID" segment.  Another is Address Space Randomization which means we can't tell
	where the kernel will choose to place the data segment (or the stack for that matter).

	Therefore writing this set_up_data_segment assembler routine is a little more complicated
	than it really needs to be.  We ask the Linux kernel where it thinks the data segment starts
	using the brk(2) system call, then ask it to reserve some initial space (also using brk(2)).

	You don't need to worry about this code.
*/
	.text
	.set INITIAL_DATA_SEGMENT_SIZE,65536
set_up_data_segment:
	mv a0, zero		// Call brk(0)
	li a7, __NR_brk
	ecall
	la t0, var_HERE		// Initialise HERE to point at beginning of data segment.
	sw a0, 0(t0)
	li t0, INITIAL_DATA_SEGMENT_SIZE
	addw a0, a0, t0		// Reserve nn bytes of memory for initial data segment.
	li a7, __NR_brk		// Call brk(HERE+INITIAL_DATA_SEGMENT_SIZE)
	ecall
	ret

/*
	We allocate static buffers for the return static and input buffer (used when
	reading in files and text that the user types in).
*/
	.set RETURN_STACK_SIZE, 8192

	.bss
/* FORTH return stack. */
	.balign 4096
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:		// Initial top of return stack.

/* This is used as a temporary input buffer when reading from files or the terminal. */
	.balign 4096
buffer:
	.space BUFFER_SIZE

/*
	START OF FORTH CODE ----------------------------------------------------------------------

	We've now reached the stage where the FORTH system is running and self-hosting.  All further
	words can be written as FORTH itself, including words like IF, THEN, .", etc which in most
	languages would be considered rather fundamental.

	I used to append this here in the assembly file, but I got sick of fighting against gas's
	crack-smoking (lack of) multiline string syntax.  So now that is in a separate file called
	jonesforth.f

	If you don't already have that file, download it from http://annexia.org/forth in order
	to continue the tutorial.
*/

/* END OF jonesforth.S */
