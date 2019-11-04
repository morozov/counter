boot.tap: boot.bas counter.tap
	bas2tap -sboot -a10 boot.bas boot.tap
	cat counter.tap EXOLON\$$.tap >> boot.tap

counter.tap: counter.asm
	pasmo --tap counter.asm counter.tap
